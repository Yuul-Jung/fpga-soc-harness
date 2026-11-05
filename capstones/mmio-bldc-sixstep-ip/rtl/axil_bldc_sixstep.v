// axil_bldc_sixstep.v
// AXI4-Lite slave: BLDC 6-step Hall sensor commutation IP
// Board: Basys3 (100 MHz), Verilog-2001
// Register map (base = free_slot[16] proposal: 0x4016_0000):
//   0x00 CTRL    RW  [0]=en [1]=dir [2]=fault_clr(self-clearing)
//   0x04 DUTY    RW  [9:0]=PWM duty (0-1023, period=1024 clk)
//   0x08 DEAD    RW  [7:0]=dead-time clock cycles (default 10 = 100ns@100MHz)
//   0x0C HALL_ST RO  [2:0]=hall_in [5:3]=step [6]=hall_err
//   0x10 STATUS  RO  [0]=fault [1]=running(en&&!fault)

`timescale 1ns/1ps

module axil_bldc_sixstep #(
    parameter ADDR_W = 8,
    parameter DATA_W = 32,
    parameter DEAD_DEFAULT = 8'd10  // 100 ns @ 100 MHz
) (
    input  wire        clk,
    input  wire        rst_n,

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
    output reg               s_rvalid,
    input  wire              s_rready,

    // Hall sensor inputs (raw, synchronization inside)
    input  wire [2:0]        hall_i,

    // PWM gate outputs to inverter
    output wire [2:0]        pwm_hi,   // upper arm [C,B,A]
    output wire [2:0]        pwm_lo    // lower arm [C,B,A]
);

    // -----------------------------------------------------------------------
    // Register addresses
    // -----------------------------------------------------------------------
    localparam REG_CTRL    = 8'h00;
    localparam REG_DUTY    = 8'h04;
    localparam REG_DEAD    = 8'h08;
    localparam REG_HALL_ST = 8'h0C;
    localparam REG_STATUS  = 8'h10;

    // -----------------------------------------------------------------------
    // Internal control registers
    // -----------------------------------------------------------------------
    reg        ctrl_en;
    reg        ctrl_dir;
    reg        ctrl_fault_clr;  // self-clearing
    reg [9:0]  reg_duty;
    reg [7:0]  reg_dead;

    // -----------------------------------------------------------------------
    // 2-stage synchronizer for Hall inputs
    // -----------------------------------------------------------------------
    reg [2:0] hall_s0, hall_s1, hall_sync;
    always @(posedge clk) begin
        if (!rst_n) begin
            hall_s0 <= 3'b111; hall_s1 <= 3'b111; hall_sync <= 3'b111;
        end else begin
            hall_s0   <= hall_i;
            hall_s1   <= hall_s0;
            hall_sync <= hall_s1;
        end
    end

    // -----------------------------------------------------------------------
    // Sub-module wires
    // -----------------------------------------------------------------------
    wire [2:0] ph_hi_req, ph_lo_req;
    wire [2:0] step_out;
    wire       hall_err;
    wire       fault_w;
    wire       fault_clr_pulse;

    // -----------------------------------------------------------------------
    // Hall FSM
    // -----------------------------------------------------------------------
    bldc_hall_fsm u_hall (
        .clk      (clk),
        .rst_n    (rst_n),
        .en       (ctrl_en),
        .dir      (ctrl_dir),
        .hall     (hall_sync),
        .ph_hi    (ph_hi_req),
        .ph_lo    (ph_lo_req),
        .step     (step_out),
        .hall_err (hall_err)
    );

    // -----------------------------------------------------------------------
    // Dead-time PWM
    // -----------------------------------------------------------------------
    assign fault_clr_pulse = ctrl_fault_clr;

    deadtime_pwm u_dt_pwm (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (ctrl_en),
        .fault_clr  (fault_clr_pulse),
        .duty       (reg_duty),
        .dead_cycles(reg_dead),
        .ph_hi_req  (ph_hi_req),
        .ph_lo_req  (ph_lo_req),
        .pwm_hi     (pwm_hi),
        .pwm_lo     (pwm_lo),
        .fault      (fault_w)
    );

    // -----------------------------------------------------------------------
    // AXI4-Lite write channel
    // -----------------------------------------------------------------------
    reg [ADDR_W-1:0] waddr_lat;
    reg              waddr_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            s_awready     <= 1'b0;
            s_wready      <= 1'b0;
            s_bvalid      <= 1'b0;
            s_bresp       <= 2'b00;
            waddr_lat     <= {ADDR_W{1'b0}};
            waddr_valid   <= 1'b0;
            ctrl_en       <= 1'b0;
            ctrl_dir      <= 1'b0;
            ctrl_fault_clr<= 1'b0;
            reg_duty      <= 10'd512;         // 50% default
            reg_dead      <= DEAD_DEFAULT;
        end else begin
            ctrl_fault_clr <= 1'b0;  // self-clearing

            // Latch write address
            s_awready <= 1'b0;
            if (s_awvalid && !waddr_valid) begin
                s_awready   <= 1'b1;
                waddr_lat   <= s_awaddr;
                waddr_valid <= 1'b1;
            end

            // Latch write data and perform write
            s_wready <= 1'b0;
            if (s_wvalid && waddr_valid) begin
                s_wready    <= 1'b1;
                waddr_valid <= 1'b0;
                s_bvalid    <= 1'b1;
                s_bresp     <= 2'b00;
                case (waddr_lat)
                    REG_CTRL: begin
                        ctrl_en        <= s_wdata[0];
                        ctrl_dir       <= s_wdata[1];
                        ctrl_fault_clr <= s_wdata[2];
                    end
                    REG_DUTY: reg_duty <= s_wdata[9:0];
                    REG_DEAD: reg_dead <= s_wdata[7:0];
                    default: ; // read-only registers ignore write
                endcase
            end

            if (s_bvalid && s_bready) s_bvalid <= 1'b0;
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite read channel
    // -----------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            s_arready <= 1'b0;
            s_rvalid  <= 1'b0;
            s_rdata   <= 32'd0;
            s_rresp   <= 2'b00;
        end else begin
            s_arready <= 1'b0;

            if (s_arvalid && !s_rvalid) begin
                s_arready <= 1'b1;
                s_rvalid  <= 1'b1;
                s_rresp   <= 2'b00;
                case (s_araddr)
                    REG_CTRL:    s_rdata <= {29'd0, ctrl_fault_clr, ctrl_dir, ctrl_en};
                    REG_DUTY:    s_rdata <= {22'd0, reg_duty};
                    REG_DEAD:    s_rdata <= {24'd0, reg_dead};
                    REG_HALL_ST: s_rdata <= {25'd0, hall_err, step_out, hall_sync};
                    REG_STATUS:  s_rdata <= {30'd0, (ctrl_en & ~fault_w), fault_w};
                    default:     s_rdata <= 32'hDEAD_BEEF;
                endcase
            end

            if (s_rvalid && s_rready) s_rvalid <= 1'b0;
        end
    end

endmodule
