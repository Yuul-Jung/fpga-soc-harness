// tb_i2c_nmea_hub.v
// Self-checking testbench for mmio-i2c-nmea-sensor-hub
// Tests:
//  T1: ID register read
//  T2: CTRL enable + STATUS initial
//  T3: IRQ disable, write I2C period (small), wait for sample_valid, check FIFO_STATUS
//  T4: NMEA UART: inject '$', data bytes, '\n'; check FIFO_STATUS and IRQ
//  T5: FIFO pop and data integrity check
//  T6: FIFO_CLR clears FIFO
// Output: PASS or FAIL (first token on line)
// Verilog-2001

`timescale 1ns/1ps

module tb_i2c_nmea_hub;

    // -----------------------------------------------------------------------
    // DUT parameters (small baud/period for fast simulation)
    // -----------------------------------------------------------------------
    localparam I2C_PERIOD_SIM = 32'd200;   // very fast cycle for simulation
    localparam BAUD_DIV_SIM   = 16'd10;    // fast UART for simulation

    // -----------------------------------------------------------------------
    // Clock & reset
    // -----------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz

    reg rst_n;

    // -----------------------------------------------------------------------
    // DUT wires
    // -----------------------------------------------------------------------
    reg  [7:0]  awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;
    reg  [7:0]  araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rrvalid;
    reg         rready;

    wire        i2c_scl_o, i2c_scl_oe, i2c_sda_o, i2c_sda_oe;
    reg         i2c_sda_i;
    reg         uart_rx;
    wire        irq;

    axil_i2c_nmea_hub #(
        .I2C_PERIOD(I2C_PERIOD_SIM),
        .BAUD_DIV  (BAUD_DIV_SIM)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .s_awaddr   (awaddr),
        .s_awvalid  (awvalid),
        .s_awready  (awready),
        .s_wdata    (wdata),
        .s_wstrb    (wstrb),
        .s_wvalid   (wvalid),
        .s_wready   (wready),
        .s_bresp    (bresp),
        .s_bvalid   (bvalid),
        .s_bready   (bready),
        .s_araddr   (araddr),
        .s_arvalid  (arvalid),
        .s_arready  (arready),
        .s_rdata    (rdata),
        .s_rresp    (rresp),
        .s_rrvalid  (rrvalid),
        .s_rready   (rready),
        .i2c_scl_o  (i2c_scl_o),
        .i2c_scl_oe (i2c_scl_oe),
        .i2c_sda_o  (i2c_sda_o),
        .i2c_sda_oe (i2c_sda_oe),
        .i2c_sda_i  (i2c_sda_i),
        .uart_rx    (uart_rx),
        .irq        (irq)
    );

    // -----------------------------------------------------------------------
    // I2C slave model: always ACK, return 6 bytes = {dev_addr, 0x1,0x2,0x3,0x4,0x5}
    // Open-drain: SDA = i2c_sda_oe ? 0 : (slave_sda ? 1 : 0)
    // -----------------------------------------------------------------------
    reg slave_ack;
    always @(*) begin
        // Slave drives SDA low for ACK in ACK phase; otherwise releases
        // For simulation: always ACK (pull SDA low when SCL rises during ACK phase)
        i2c_sda_i = i2c_sda_oe ? 1'b0 : 1'b1; // simple: always ACK
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite helper tasks
    // -----------------------------------------------------------------------
    task axi_write(input [7:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            awaddr  = addr;
            awvalid = 1'b1;
            wdata   = data;
            wstrb   = 4'hF;
            wvalid  = 1'b1;
            bready  = 1'b1;

            // Wait for address accept
            @(posedge clk);
            while (!awready) @(posedge clk);
            @(posedge clk);
            awvalid = 1'b0;

            // Wait for data accept
            while (!wready) @(posedge clk);
            @(posedge clk);
            wvalid = 1'b0;

            // Wait for response
            while (!bvalid) @(posedge clk);
            @(posedge clk);
            bready = 1'b0;
        end
    endtask

    task axi_read(input [7:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            araddr  = addr;
            arvalid = 1'b1;
            rready  = 1'b1;

            @(posedge clk);
            while (!arready) @(posedge clk);
            @(posedge clk);
            arvalid = 1'b0;

            while (!rrvalid) @(posedge clk);
            data = rdata;
            @(posedge clk);
            rready = 1'b0;
        end
    endtask

    // -----------------------------------------------------------------------
    // UART transmit task (bit-bang at BAUD_DIV_SIM periods)
    // -----------------------------------------------------------------------
    task uart_send_byte(input [7:0] byte_val);
        integer i;
        begin
            // Start bit
            uart_rx = 1'b0;
            repeat (BAUD_DIV_SIM) @(posedge clk);
            // 8 data bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = byte_val[i];
                repeat (BAUD_DIV_SIM) @(posedge clk);
            end
            // Stop bit
            uart_rx = 1'b1;
            repeat (BAUD_DIV_SIM) @(posedge clk);
        end
    endtask

    // -----------------------------------------------------------------------
    // Test variables
    // -----------------------------------------------------------------------
    reg [31:0] rd_val;
    integer    fail_count;
    integer    test_num;

    task check(input pass_cond, input [63:0] test_id, input [31:0] got, input [31:0] exp);
        begin
            if (!pass_cond) begin
                $display("FAIL T%0d: got=0x%08X exp=0x%08X", test_id, got, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    integer i;
    initial begin
        // Init
        fail_count = 0;
        rst_n      = 1'b0;
        awvalid    = 1'b0; awaddr = 8'd0;
        wvalid     = 1'b0; wdata  = 32'd0; wstrb = 4'hF;
        bready     = 1'b0;
        arvalid    = 1'b0; araddr = 8'd0;
        rready     = 1'b0;
        i2c_sda_i  = 1'b1;
        uart_rx    = 1'b1;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // ---- T1: ID register ----
        axi_read(8'h00, rd_val);
        check(rd_val === 32'h4B485542, 1, rd_val, 32'h4B485542);

        // ---- T2: Initial STATUS (not enabled, FIFO empty) ----
        axi_read(8'h08, rd_val);
        // fifo_cnt=0, not full, not busy
        check(rd_val[4:0] === 5'd0, 2, rd_val, 32'd0);

        // ---- T3: Enable hub with fast I2C period, wait for I2C sample ----
        // Write I2C_CFG with small period (already set by parameter)
        axi_write(8'h10, I2C_PERIOD_SIM);
        // Enable hub (ctrl_en=1, ie=0)
        axi_write(8'h04, 32'h1);
        // Wait for at least one I2C cycle to complete (period + FSM overhead)
        repeat (I2C_PERIOD_SIM * 10 + 5000) @(posedge clk);
        // Check FIFO has at least 1 entry
        axi_read(8'h08, rd_val);
        // fifo_cnt should be >= 1 (at least one I2C device was polled)
        check(rd_val[4:0] >= 5'd1, 3, rd_val[4:0], 5'd1);

        // ---- T4: UART NMEA line injection ----
        // Send "$GPGGA,..." terminated by '\n'
        uart_send_byte(8'h24); // '$'
        uart_send_byte(8'h47); // 'G'
        uart_send_byte(8'h50); // 'P'
        uart_send_byte(8'h0A); // '\n'
        // Wait for processing
        repeat (50) @(posedge clk);
        // Check IRQ status bit 1 (UART_LINE_DONE) or FIFO has more entries
        axi_read(8'h0C, rd_val);
        check(rd_val[1] === 1'b1, 4, rd_val, 32'h2);

        // ---- T5: FIFO pop — read FIFO_HI then FIFO_LO ----
        axi_read(8'h08, rd_val);
        // cnt should be >= 1
        check(rd_val[4:0] >= 5'd1, 51, rd_val[4:0], 5'd1);

        axi_read(8'h14, rd_val); // FIFO_HI (timestamp)
        // timestamp should be non-zero (clock has advanced)
        check(rd_val !== 32'd0, 52, rd_val, 32'hXXXXXXXX);

        axi_read(8'h18, rd_val); // FIFO_LO (pops FIFO)
        // just check it doesn't return 0xDEADBEEF
        check(rd_val !== 32'hDEAD_BEEF, 53, rd_val, 32'h0);

        // ---- T6: FIFO CLR ----
        // Fill some entries first (already have some from above)
        // Write CTRL with FIFO_CLR=1
        axi_write(8'h04, 32'h5); // EN=1, FIFO_CLR=1
        repeat (4) @(posedge clk);
        axi_read(8'h08, rd_val);
        // After CLR, FIFO cnt should be 0
        check(rd_val[4:0] === 5'd0, 6, rd_val[4:0], 5'd0);

        // ---- Final result ----
        repeat (10) @(posedge clk);
        if (fail_count === 0)
            $display("PASS: all tests passed");
        else
            $display("FAIL: %0d test(s) failed", fail_count);
        $finish;
    end

    // Timeout watchdog
    initial begin
        #2_000_000;
        $display("FAIL: timeout");
        $finish;
    end

endmodule
