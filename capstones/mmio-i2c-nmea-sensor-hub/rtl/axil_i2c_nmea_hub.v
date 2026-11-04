// axil_i2c_nmea_hub.v
// AXI4-Lite slave: I2C 3-device cycling + NMEA UART sensor hub
// Board: Basys3 (100 MHz), Verilog-2001
// Part of capstone mmio-i2c-nmea-sensor-hub

`timescale 1ns/1ps

module axil_i2c_nmea_hub #(
    // AXI4-Lite
    parameter ADDR_W  = 8,
    parameter DATA_W  = 32,
    // defaults
    parameter I2C_PERIOD = 32'd10_000_000,  // 100 ms @ 100 MHz
    parameter BAUD_DIV   = 16'd10417        // 9600 baud @ 100 MHz
) (
    // AXI4-Lite clock & reset
    input  wire        clk,
    input  wire        rst_n,       // synchronous, active-low

    // AXI4-Lite write address channel
    input  wire [ADDR_W-1:0] s_awaddr,
    input  wire              s_awvalid,
    output reg               s_awready,

    // AXI4-Lite write data channel
    input  wire [DATA_W-1:0] s_wdata,
    input  wire [3:0]        s_wstrb,
    input  wire              s_wvalid,
    output reg               s_wready,

    // AXI4-Lite write response channel
    output reg  [1:0]        s_bresp,
    output reg               s_bvalid,
    input  wire              s_bready,

    // AXI4-Lite read address channel
    input  wire [ADDR_W-1:0] s_araddr,
    input  wire              s_arvalid,
    output reg               s_arready,

    // AXI4-Lite read data channel
    output reg  [DATA_W-1:0] s_rdata,
    output reg  [1:0]        s_rresp,
    output reg               s_rrvalid,
    input  wire              s_rready,

    // I2C interface (open-drain, external pull-ups required)
    output wire        i2c_scl_o,
    output wire        i2c_scl_oe,  // 1=drive low
    output wire        i2c_sda_o,
    output wire        i2c_sda_oe,  // 1=drive low
    input  wire        i2c_sda_i,

    // UART RX (9600 baud NMEA)
    input  wire        uart_rx,

    // Interrupt output (active-high, level)
    output wire        irq
);

    // ---------------------------------------------------------------
    // Register addresses
    // ---------------------------------------------------------------
    localparam REG_ID          = 8'h00;
    localparam REG_CTRL        = 8'h04;
    localparam REG_STATUS      = 8'h08;
    localparam REG_IRQ_STATUS  = 8'h0C;
    localparam REG_I2C_CFG     = 8'h10;
    localparam REG_FIFO_HI     = 8'h14;
    localparam REG_FIFO_LO     = 8'h18;
    localparam REG_UART_CFG    = 8'h1C;

    localparam ID_VAL = 32'h4B485542; // 'KHUB'

    // ---------------------------------------------------------------
    // Internal registers
    // ---------------------------------------------------------------
    reg         ctrl_en;
    reg         ctrl_ie;
    reg         ctrl_fifo_clr;

    reg  [31:0] irq_status;   // [0]=FIFO_HF, [1]=UART_LINE_DONE
    reg  [31:0] i2c_cfg;      // period counter threshold
    reg  [15:0] uart_cfg;     // baud divisor

    // Write address capture
    reg  [ADDR_W-1:0] waddr_lat;
    reg               waddr_valid;

    // ---------------------------------------------------------------
    // Sub-module wires
    // ---------------------------------------------------------------
    // I2C FSM
    wire        i2c_busy;
    wire [7:0]  i2c_dev_type;    // which device sample
    wire [47:0] i2c_raw_data;    // 6 bytes from sensor
    wire        i2c_sample_valid;

    // UART NMEA RX
    wire        uart_line_rdy;
    wire        uart_line_done;  // one-cycle pulse when line complete

    // FIFO
    reg         fifo_push;
    reg  [71:0] fifo_din;        // [71:40]=timestamp, [39:32]=type, [31:0]=data_lo
    wire        fifo_pop;
    wire [71:0] fifo_dout;
    wire [4:0]  fifo_cnt;
    wire        fifo_full;
    wire        fifo_empty;

    // Timestamp counter
    reg  [31:0] ts_cnt;

    // ---------------------------------------------------------------
    // Timestamp free-running counter
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) ts_cnt <= 32'd0;
        else        ts_cnt <= ts_cnt + 1'b1;
    end

    // ---------------------------------------------------------------
    // Sub-module instantiations
    // ---------------------------------------------------------------
    i2c_cycle_fsm u_i2c (
        .clk            (clk),
        .rst_n          (rst_n),
        .en             (ctrl_en),
        .period_cfg     (i2c_cfg),
        .scl_o          (i2c_scl_o),
        .scl_oe         (i2c_scl_oe),
        .sda_o          (i2c_sda_o),
        .sda_oe         (i2c_sda_oe),
        .sda_i          (i2c_sda_i),
        .busy           (i2c_busy),
        .dev_type       (i2c_dev_type),
        .raw_data       (i2c_raw_data),
        .sample_valid   (i2c_sample_valid)
    );

    nmea_uart_rx u_uart (
        .clk            (clk),
        .rst_n          (rst_n),
        .en             (ctrl_en),
        .baud_div       (uart_cfg),
        .rx             (uart_rx),
        .line_rdy       (uart_line_rdy),
        .line_done_pulse(uart_line_done)
    );

    ts_fifo #(
        .DEPTH(16),
        .DWIDTH(72)
    ) u_fifo (
        .clk            (clk),
        .rst_n          (rst_n & ~ctrl_fifo_clr),
        .push           (fifo_push),
        .din            (fifo_din),
        .pop            (fifo_pop),
        .dout           (fifo_dout),
        .cnt            (fifo_cnt),
        .full           (fifo_full),
        .empty          (fifo_empty)
    );

    // ---------------------------------------------------------------
    // FIFO push logic
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            fifo_push <= 1'b0;
            fifo_din  <= 72'd0;
        end else if (i2c_sample_valid && !fifo_full) begin
            fifo_push <= 1'b1;
            fifo_din  <= {ts_cnt, i2c_dev_type, i2c_raw_data[31:0]};
        end else if (uart_line_done && !fifo_full) begin
            fifo_push <= 1'b1;
            fifo_din  <= {ts_cnt, 8'hFF, 24'h0, 8'h01}; // type=0xFF=NMEA
        end else begin
            fifo_push <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // IRQ status
    // ---------------------------------------------------------------
    wire fifo_hf = (fifo_cnt >= 5'd8);

    always @(posedge clk) begin
        if (!rst_n) begin
            irq_status <= 32'd0;
        end else begin
            if (fifo_hf)       irq_status[0] <= 1'b1;
            if (uart_line_done) irq_status[1] <= 1'b1;
        end
    end

    assign irq = ctrl_ie & (|irq_status);

    // ---------------------------------------------------------------
    // AXI4-Lite write channel (simple 1-cycle ready)
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            s_awready    <= 1'b0;
            s_wready     <= 1'b0;
            s_bvalid     <= 1'b0;
            s_bresp      <= 2'b00;
            waddr_lat    <= {ADDR_W{1'b0}};
            waddr_valid  <= 1'b0;
            ctrl_en      <= 1'b0;
            ctrl_ie      <= 1'b0;
            ctrl_fifo_clr<= 1'b0;
            i2c_cfg      <= I2C_PERIOD;
            uart_cfg     <= BAUD_DIV;
        end else begin
            // auto-clear fifo_clr after one cycle
            ctrl_fifo_clr <= 1'b0;
            // latch write address
            s_awready <= 1'b0;
            if (s_awvalid && !waddr_valid) begin
                s_awready  <= 1'b1;
                waddr_lat  <= s_awaddr;
                waddr_valid<= 1'b1;
            end

            // latch write data and perform write
            s_wready <= 1'b0;
            if (s_wvalid && waddr_valid) begin
                s_wready    <= 1'b1;
                waddr_valid <= 1'b0;
                s_bvalid    <= 1'b1;
                s_bresp     <= 2'b00;
                case (waddr_lat)
                    REG_CTRL: begin
                        ctrl_en       <= s_wdata[0];
                        ctrl_ie       <= s_wdata[1];
                        ctrl_fifo_clr <= s_wdata[2];
                    end
                    REG_IRQ_STATUS: begin
                        // W1C
                        irq_status <= irq_status & ~s_wdata;
                    end
                    REG_I2C_CFG:  i2c_cfg  <= s_wdata;
                    REG_UART_CFG: uart_cfg <= s_wdata[15:0];
                    default: ; // read-only registers ignore write
                endcase
            end

            if (s_bvalid && s_bready) s_bvalid <= 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // AXI4-Lite read channel
    // ---------------------------------------------------------------
    // FIFO pop on FIFO_DATA_LO read
    reg  fifo_pop_r;
    reg  [71:0] fifo_dout_latch;
    assign fifo_pop = fifo_pop_r;

    always @(posedge clk) begin
        if (!rst_n) begin
            s_arready    <= 1'b0;
            s_rrvalid    <= 1'b0;
            s_rdata      <= 32'd0;
            s_rresp      <= 2'b00;
            fifo_pop_r   <= 1'b0;
            fifo_dout_latch <= 72'd0;
        end else begin
            s_arready  <= 1'b0;
            fifo_pop_r <= 1'b0;

            if (s_arvalid && !s_rrvalid) begin
                s_arready <= 1'b1;
                s_rrvalid <= 1'b1;
                s_rresp   <= 2'b00;
                case (s_araddr)
                    REG_ID:         s_rdata <= ID_VAL;
                    REG_CTRL:       s_rdata <= {29'd0, ctrl_fifo_clr, ctrl_ie, ctrl_en};
                    REG_STATUS:     s_rdata <= {25'd0, uart_line_rdy, i2c_busy, fifo_full, fifo_cnt};
                    REG_IRQ_STATUS: s_rdata <= irq_status;
                    REG_I2C_CFG:    s_rdata <= i2c_cfg;
                    REG_FIFO_HI: begin
                        fifo_dout_latch <= fifo_dout;
                        s_rdata <= fifo_dout[71:40];
                    end
                    REG_FIFO_LO: begin
                        s_rdata    <= {fifo_dout_latch[39:8], fifo_dout_latch[7:0]};
                        fifo_pop_r <= !fifo_empty;
                    end
                    REG_UART_CFG:   s_rdata <= {16'd0, uart_cfg};
                    default:        s_rdata <= 32'hDEAD_BEEF;
                endcase
            end

            if (s_rrvalid && s_rready) s_rrvalid <= 1'b0;
        end
    end

endmodule
