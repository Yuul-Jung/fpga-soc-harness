// tb_i2c_rtc_log.v — synchronous slave models (fix 2, complete rewrite)
// Self-checking testbench for axil_i2c_rtc_log.
// All slave logic clocked by `clk`; edges detected by comparing to prev reg.
// Outputs lines starting with "PASS:" or "FAIL:".
// Verilog-2001 compatible (iverilog/vvp).
`timescale 1ns/1ps
`default_nettype none

module tb_i2c_rtc_log;

// ----------------------------------------------------------------
// Clock / reset
// ----------------------------------------------------------------
reg clk = 0;
always #5 clk = ~clk;   // 100 MHz

reg resetn;
initial begin resetn = 0; #200; resetn = 1; end

// ----------------------------------------------------------------
// AXI4-Lite master signals
// ----------------------------------------------------------------
reg  [31:0] awaddr = 0;  reg awvalid = 0; wire awready;
reg  [31:0] wdata  = 0;  reg [3:0] wstrb = 4'hF; reg wvalid = 0; wire wready;
wire [1:0]  bresp;       wire bvalid; reg bready = 1;
reg  [31:0] araddr = 0;  reg arvalid = 0; wire arready;
wire [31:0] rdata;       wire [1:0] rresp; wire rvalid; reg rready = 1;

// ----------------------------------------------------------------
// I2C bus: open-drain wired-AND
// ----------------------------------------------------------------
wire scl_o, scl_oe, scl_i;
wire sda_o, sda_oe, sda_i;

reg  ds3231_sda_lo;
reg  eeprom_sda_lo;
wire sda_bus = (~sda_oe ? 1'b1 : 1'b0) &
               (~ds3231_sda_lo ? 1'b1 : 1'b0) &
               (~eeprom_sda_lo ? 1'b1 : 1'b0);
// scl_oe: 1 = drive low, 0 = tristate (pull-up = high)
wire scl_bus = (scl_oe ? 1'b0 : 1'b1);

assign scl_i = scl_bus;
assign sda_i = sda_bus;

// ----------------------------------------------------------------
// DUT
// ----------------------------------------------------------------
axil_i2c_rtc_log #(
    .CLK_HZ      (100_000_000),
    .HALF_PERIOD (10)
) dut (
    .s_aclk     (clk),    .s_aresetn  (resetn),
    .s_awaddr   (awaddr), .s_awvalid  (awvalid), .s_awready  (awready),
    .s_wdata    (wdata),  .s_wstrb    (wstrb),   .s_wvalid   (wvalid),  .s_wready (wready),
    .s_bresp    (bresp),  .s_bvalid   (bvalid),  .s_bready   (bready),
    .s_araddr   (araddr), .s_arvalid  (arvalid), .s_ararready(arready),
    .s_rdata    (rdata),  .s_rresp    (rresp),   .s_rvalid   (rvalid),  .s_rready (rready),
    .scl_o(scl_o), .scl_oe(scl_oe), .scl_i(scl_i),
    .sda_o(sda_o), .sda_oe(sda_oe), .sda_i(sda_i)
);

// ================================================================
// DS3231 synchronous slave model
// ds_step: 0=waiting addr_W, 1=waiting reg_ptr, 2=waiting addr_R, 3..9=TX bytes
// ================================================================
reg [7:0] DS_REG [0:6];
initial begin
    DS_REG[0] = 8'h45; // sec
    DS_REG[1] = 8'h30; // min
    DS_REG[2] = 8'h14; // hour
    DS_REG[3] = 8'h03; // day
    DS_REG[4] = 8'h07; // date
    DS_REG[5] = 8'h11; // month
    DS_REG[6] = 8'h26; // year
end

localparam [2:0] DS_IDLE    = 3'd0,
                 DS_RX      = 3'd1,
                 DS_ACK1    = 3'd2,   // drive SDA low, wait SCL negedge (bit-7 fall)
                 DS_ACK2    = 3'd3,   // hold SDA low through ACK posedge, release on negedge
                 DS_TX      = 3'd4,
                 DS_TX_ACK  = 3'd5;

reg [2:0]  ds_state;
reg [2:0]  ds_step;        // transaction phase counter
reg [7:0]  ds_rx_shift;
reg [3:0]  ds_bit_cnt;     // 0..7 (counts posedges while in DS_RX)
reg [2:0]  ds_tx_reg_idx;  // 0..6 index into DS_REG
reg [7:0]  ds_tx_byte;
reg [3:0]  ds_tx_bit;      // 0..7

// edge detection regs
reg ds_scl_p, ds_sda_p;
wire ds_scl_pos = scl_bus & ~ds_scl_p;
wire ds_scl_neg = ~scl_bus & ds_scl_p;
wire ds_i2c_start = ~sda_bus & ds_sda_p & (scl_bus | ds_scl_p);
wire ds_i2c_stop  = sda_bus & ~ds_sda_p & (scl_bus | ds_scl_p);

initial begin
    ds3231_sda_lo = 0;
    ds_state = DS_IDLE;
    ds_step  = 0;
    ds_rx_shift = 0; ds_bit_cnt = 0;
    ds_tx_reg_idx = 0; ds_tx_byte = 0; ds_tx_bit = 0;
    ds_scl_p = 1; ds_sda_p = 1;
end

always @(posedge clk) begin : ds3231_model
    // Update prev
    ds_scl_p <= scl_bus;
    ds_sda_p <= sda_bus;

    // Default: release SDA
    ds3231_sda_lo <= 1'b0;

    // START overrides everything
    if (ds_i2c_start) begin
        ds_state    <= DS_RX;
        ds_rx_shift <= 8'h00;
        ds_bit_cnt  <= 4'd0;
        // step stays (we may be in RSTART at step==2)
    end
    // STOP resets
    else if (ds_i2c_stop) begin
        ds_state <= DS_IDLE;
        ds_step  <= 3'd0;
    end
    else begin
        case (ds_state)
            DS_IDLE: begin
                /* waiting for START */
            end

            DS_RX: begin
                // Sample bit on SCL posedge; count 8 posedges (bit 0..7)
                if (ds_scl_pos) begin
                    ds_rx_shift <= {ds_rx_shift[6:0], sda_bus};
                    if (ds_bit_cnt == 4'd7) begin
                        // 8th posedge: byte received; go ACK on SCL negedge
                        ds_state   <= DS_ACK1;
                        ds_bit_cnt <= 4'd0;
                    end else begin
                        ds_bit_cnt <= ds_bit_cnt + 4'd1;
                    end
                end
            end

            DS_ACK1: begin
                // Drive SDA low; wait for the SCL negedge after bit-7 posedge
                ds3231_sda_lo <= 1'b1;
                if (ds_scl_neg) begin
                    ds_state <= DS_ACK2;
                end
            end

            DS_ACK2: begin
                // Hold SDA low (ACK posedge happens while we hold)
                ds3231_sda_lo <= 1'b1;
                // Release on SCL negedge (after ACK posedge)
                if (ds_scl_neg) begin
                    ds3231_sda_lo <= 1'b0; // override default (already 0)
                    // Process received byte based on transaction step
                    case (ds_step)
                        3'd0: begin
                            // Expected: 0xD0 (addr_W, DS3231 = 7'h68, R/W=0)
                            if (ds_rx_shift[7:1] == 7'h68 && ds_rx_shift[0] == 1'b0) begin
                                ds_step <= 3'd1;
                                ds_state   <= DS_RX;
                                ds_rx_shift <= 8'h00;
                                ds_bit_cnt  <= 4'd0;
                            end else begin
                                ds_state <= DS_IDLE;
                            end
                        end
                        3'd1: begin
                            // Register pointer byte — accept any value
                            ds_step  <= 3'd2;
                            ds_state <= DS_IDLE; // wait for RSTART
                        end
                        3'd2: begin
                            // Expected: 0xD1 (addr_R, DS3231 = 7'h68, R/W=1)
                            if (ds_rx_shift[7:1] == 7'h68 && ds_rx_shift[0] == 1'b1) begin
                                ds_tx_reg_idx <= 3'd0;
                                ds_tx_byte    <= DS_REG[0];
                                ds_tx_bit     <= 4'd0;
                                ds_step       <= 3'd3;
                                ds_state      <= DS_TX;
                            end else begin
                                ds_state <= DS_IDLE;
                                ds_step  <= 3'd0;
                            end
                        end
                        default: begin
                            ds_state <= DS_IDLE;
                            ds_step  <= 3'd0;
                        end
                    endcase
                end
            end

            DS_TX: begin
                // Drive SDA: MSB first; set up bit on SCL negedge, stable for posedge
                ds3231_sda_lo <= (ds_tx_byte[3'd7 - ds_tx_bit[2:0]] == 1'b0) ? 1'b1 : 1'b0;
                if (ds_scl_neg) begin
                    if (ds_tx_bit == 4'd7) begin
                        // All 8 bits output; go wait for master ACK/NACK
                        ds_state  <= DS_TX_ACK;
                        ds_tx_bit <= 4'd0;
                    end else begin
                        ds_tx_bit <= ds_tx_bit + 4'd1;
                    end
                end
            end

            DS_TX_ACK: begin
                // Release SDA for master ACK/NACK (master always sends NACK since sda_oe=0)
                // After SCL negedge of ACK cycle: advance to next byte or done
                if (ds_scl_neg) begin
                    if (ds_tx_reg_idx < 3'd6) begin
                        ds_tx_reg_idx <= ds_tx_reg_idx + 3'd1;
                        ds_tx_byte    <= DS_REG[ds_tx_reg_idx + 3'd1];
                        ds_tx_bit     <= 4'd0;
                        ds_state      <= DS_TX;
                    end else begin
                        // All 7 bytes sent
                        ds_state <= DS_IDLE;
                        ds_step  <= 3'd0;
                    end
                end
            end

            default: begin
                ds_state <= DS_IDLE;
            end
        endcase
    end
end

// ================================================================
// 24LC256 (EE) synchronous slave model
// ee_step: 0=addr_W, 1=MSB_addr, 2=LSB_addr, 3=data_or_addrR
// ================================================================
reg [7:0] EE_MEM [0:255]; // 256-byte slice for simulation speed
integer jj;
initial begin
    for (jj = 0; jj < 256; jj = jj+1)
        EE_MEM[jj] = jj[7:0] ^ 8'hA5; // known pattern
    eeprom_sda_lo = 0;
end

localparam [2:0] EE_IDLE    = 3'd0,
                 EE_RX      = 3'd1,
                 EE_ACK1    = 3'd2,
                 EE_ACK2    = 3'd3,
                 EE_TX      = 3'd4,
                 EE_TX_ACK  = 3'd5;

reg [2:0]  ee_state;
reg [1:0]  ee_step;
reg [7:0]  ee_rx_shift;
reg [3:0]  ee_bit_cnt;
reg [7:0]  ee_read_addr;   // LSB of EEPROM address for read
reg [7:0]  ee_tx_byte;
reg [3:0]  ee_tx_bit;

reg ee_scl_p, ee_sda_p;
wire ee_scl_pos = scl_bus & ~ee_scl_p;
wire ee_scl_neg = ~scl_bus & ee_scl_p;
wire ee_i2c_start = ~sda_bus & ee_sda_p & (scl_bus | ee_scl_p);
wire ee_i2c_stop  = sda_bus & ~ee_sda_p & (scl_bus | ee_scl_p);

initial begin
    ee_state = EE_IDLE; ee_step = 2'd0;
    ee_rx_shift = 0; ee_bit_cnt = 0;
    ee_read_addr = 0; ee_tx_byte = 0; ee_tx_bit = 0;
    ee_scl_p = 1; ee_sda_p = 1;
end

always @(posedge clk) begin : ee24lc256_model
    ee_scl_p <= scl_bus;
    ee_sda_p <= sda_bus;

    eeprom_sda_lo <= 1'b0;

    if (ee_i2c_start) begin
        // START or RSTART
        ee_state    <= EE_RX;
        ee_rx_shift <= 8'h00;
        ee_bit_cnt  <= 4'd0;
        // ee_step preserved for RSTART detection in EE_ACK2
    end
    else if (ee_i2c_stop) begin
        ee_state <= EE_IDLE;
        ee_step  <= 2'd0;
    end
    else begin
        case (ee_state)
            EE_IDLE: ;

            EE_RX: begin
                if (ee_scl_pos) begin
                    ee_rx_shift <= {ee_rx_shift[6:0], sda_bus};
                    if (ee_bit_cnt == 4'd7) begin
                        ee_state   <= EE_ACK1;
                        ee_bit_cnt <= 4'd0;
                    end else begin
                        ee_bit_cnt <= ee_bit_cnt + 4'd1;
                    end
                end
            end

            EE_ACK1: begin
                eeprom_sda_lo <= 1'b1;
                if (ee_scl_neg) begin
                    ee_state <= EE_ACK2;
                end
            end

            EE_ACK2: begin
                eeprom_sda_lo <= 1'b1;
                if (ee_scl_neg) begin
                    eeprom_sda_lo <= 1'b0;
                    case (ee_step)
                        2'd0: begin
                            // Device address write (0xA0)
                            if (ee_rx_shift[7:1] == 7'h50 && ee_rx_shift[0] == 1'b0) begin
                                ee_step     <= 2'd1;
                                ee_state    <= EE_RX;
                                ee_rx_shift <= 8'h00;
                                ee_bit_cnt  <= 4'd0;
                            end else begin
                                ee_state <= EE_IDLE;
                            end
                        end
                        2'd1: begin
                            // MSB address byte — ignore for 8-bit sim
                            ee_step     <= 2'd2;
                            ee_state    <= EE_RX;
                            ee_rx_shift <= 8'h00;
                            ee_bit_cnt  <= 4'd0;
                        end
                        2'd2: begin
                            // LSB address byte: store addr, stay in RX for
                            // next byte (WRITE data) or handle RSTART for READ
                            ee_read_addr <= ee_rx_shift;
                            ee_step      <= 2'd3;
                            ee_state     <= EE_RX;   // remain in RX (no STOP yet)
                            ee_rx_shift  <= 8'h00;
                            ee_bit_cnt   <= 4'd0;
                        end
                        2'd3: begin
                            // EE_WRITE data byte arrived (device_addr_R won't come
                            // through EE_RX — it arrives after RSTART which resets
                            // to EE_RX directly via ee_i2c_start)
                            if (ee_rx_shift[7:1] == 7'h50 && ee_rx_shift[0] == 1'b1) begin
                                // EE_READ: address+R byte (arrived after RSTART)
                                ee_tx_byte <= EE_MEM[ee_read_addr];
                                ee_tx_bit  <= 4'd0;
                                ee_state   <= EE_TX;
                            end else begin
                                // EE_WRITE: store data byte
                                EE_MEM[ee_read_addr] <= ee_rx_shift;
                                ee_state <= EE_IDLE;
                                ee_step  <= 2'd0;
                            end
                        end
                        default: begin
                            ee_state <= EE_IDLE;
                            ee_step  <= 2'd0;
                        end
                    endcase
                end
            end

            EE_TX: begin
                eeprom_sda_lo <= (ee_tx_byte[3'd7 - ee_tx_bit[2:0]] == 1'b0) ? 1'b1 : 1'b0;
                if (ee_scl_neg) begin
                    if (ee_tx_bit == 4'd7) begin
                        ee_state  <= EE_TX_ACK;
                        ee_tx_bit <= 4'd0;
                    end else begin
                        ee_tx_bit <= ee_tx_bit + 4'd1;
                    end
                end
            end

            EE_TX_ACK: begin
                // Release SDA (master may ACK or NACK)
                if (ee_scl_neg) begin
                    // 1 byte sent; done for this test
                    ee_state <= EE_IDLE;
                    ee_step  <= 2'd0;
                end
            end

            default: begin
                ee_state <= EE_IDLE;
                ee_step  <= 2'd0;
            end
        endcase
    end
end

// ================================================================
// AXI4-Lite helper tasks
// ================================================================
task axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(posedge clk);
        awaddr  <= addr; awvalid <= 1'b1;
        wdata   <= data; wvalid  <= 1'b1; wstrb <= 4'hF;
        // wait AW
        @(posedge clk);
        while (!awready) @(posedge clk);
        awvalid <= 1'b0;
        // wait W
        while (!wready) @(posedge clk);
        wvalid <= 1'b0;
        // wait B
        while (!bvalid) @(posedge clk);
        @(posedge clk);
    end
endtask

task axi_read;
    input  [31:0] addr;
    output [31:0] data;
    begin
        @(posedge clk);
        araddr <= addr; arvalid <= 1'b1;
        @(posedge clk);
        while (!arready) @(posedge clk);
        arvalid <= 1'b0;
        while (!rvalid) @(posedge clk);
        data = rdata;
        @(posedge clk);
    end
endtask

// Wait for STATUS[0] (busy) to clear, with timeout
task wait_idle;
    input integer max_cycles;
    integer k;
    reg [31:0] st;
    begin
        for (k = 0; k < max_cycles; k = k+1) begin
            axi_read(32'h402B_0000, st);
            if (st[0] == 1'b0) k = max_cycles; // break
            else repeat (10) @(posedge clk);
        end
    end
endtask

// ================================================================
// Test sequence
// ================================================================
integer fail_count;
reg [31:0] rd;

// Expected RTC register values after masking (DUT applies masks)
// hour: & 8'h3F  → 8'h14 & 8'h3F = 8'h14
// month: & 8'h1F → 8'h11 & 8'h1F = 8'h11
localparam [7:0] EXP_SEC  = 8'h45,
                 EXP_MIN  = 8'h30,
                 EXP_HOUR = 8'h14,
                 EXP_DAY  = 8'h03,
                 EXP_DATE = 8'h07,
                 EXP_MON  = 8'h11,
                 EXP_YEAR = 8'h26;

localparam BASE = 32'h402B_0000;

initial begin
    fail_count = 0;

    // Wait for reset
    @(posedge resetn);
    repeat(10) @(posedge clk);

    // ============================================================
    // TEST 1: RTC READ
    // Write CMD=1 (RTC_READ), wait done, read back 7 registers
    // ============================================================
    $display("TEST 1: RTC_READ");
    axi_write(BASE + 32'h04, 32'h0000_0001); // CMD = 1
    // Poll STATUS[0] = busy, wait up to 50000 cycles
    wait_idle(500);

    // Read back registers
    axi_read(BASE + 32'h14, rd);
    if (rd[7:0] !== EXP_SEC) begin
        $display("FAIL: RTC_SEC expected 0x%02x got 0x%02x", EXP_SEC, rd[7:0]);
        fail_count = fail_count + 1;
    end

    axi_read(BASE + 32'h18, rd);
    if (rd[7:0] !== EXP_MIN) begin
        $display("FAIL: RTC_MIN expected 0x%02x got 0x%02x", EXP_MIN, rd[7:0]);
        fail_count = fail_count + 1;
    end

    axi_read(BASE + 32'h1C, rd);
    if (rd[7:0] !== EXP_HOUR) begin
        $display("FAIL: RTC_HOUR expected 0x%02x got 0x%02x", EXP_HOUR, rd[7:0]);
        fail_count = fail_count + 1;
    end

    axi_read(BASE + 32'h20, rd);
    if (rd[7:0] !== EXP_DAY) begin
        $display("FAIL: RTC_DAY expected 0x%02x got 0x%02x", EXP_DAY, rd[7:0]);
        fail_count = fail_count + 1;
    end

    axi_read(BASE + 32'h24, rd);
    if (rd[7:0] !== EXP_DATE) begin
        $display("FAIL: RTC_DATE expected 0x%02x got 0x%02x", EXP_DATE, rd[7:0]);
        fail_count = fail_count + 1;
    end

    axi_read(BASE + 32'h28, rd);
    if (rd[7:0] !== EXP_MON) begin
        $display("FAIL: RTC_MON expected 0x%02x got 0x%02x", EXP_MON, rd[7:0]);
        fail_count = fail_count + 1;
    end

    axi_read(BASE + 32'h2C, rd);
    if (rd[7:0] !== EXP_YEAR) begin
        $display("FAIL: RTC_YEAR expected 0x%02x got 0x%02x", EXP_YEAR, rd[7:0]);
        fail_count = fail_count + 1;
    end

    if (fail_count == 0) $display("PASS: RTC_READ all 7 registers correct");

    repeat(20) @(posedge clk);

    // ============================================================
    // TEST 2: EE WRITE
    // Write addr=0x0042, data=0x5A, CMD=3 (EE_WRITE)
    // ============================================================
    $display("TEST 2: EE_WRITE");
    axi_write(BASE + 32'h08, 32'h0000_0042); // EE_ADDR = 0x0042
    axi_write(BASE + 32'h0C, 32'h0000_005A); // EE_WDATA = 0x5A
    axi_write(BASE + 32'h04, 32'h0000_0003); // CMD = 3
    wait_idle(500);
    // Verify EE_MEM was updated
    if (EE_MEM[8'h42] !== 8'h5A) begin
        $display("FAIL: EE_WRITE EE_MEM[0x42] expected 0x5A got 0x%02x", EE_MEM[8'h42]);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: EE_WRITE EE_MEM[0x42]=0x5A correct");
    end

    repeat(20) @(posedge clk);

    // ============================================================
    // TEST 3: EE READ
    // Read from addr=0x0042 (should return 0x5A written above)
    // CMD=2 (EE_READ)
    // ============================================================
    $display("TEST 3: EE_READ");
    axi_write(BASE + 32'h08, 32'h0000_0042); // EE_ADDR = 0x0042
    axi_write(BASE + 32'h04, 32'h0000_0002); // CMD = 2
    wait_idle(500);
    axi_read(BASE + 32'h10, rd);
    if (rd[7:0] !== 8'h5A) begin
        $display("FAIL: EE_READ expected 0x5A got 0x%02x", rd[7:0]);
        fail_count = fail_count + 1;
    end else begin
        $display("PASS: EE_READ got 0x5A");
    end

    repeat(20) @(posedge clk);

    // ============================================================
    // Final verdict
    // ============================================================
    if (fail_count == 0)
        $display("PASS: all tests passed");
    else
        $display("FAIL: %0d test(s) failed", fail_count);

    $finish;
end

// Safety timeout
initial begin
    #50_000_000; // 50 ms simulation time
    $display("FAIL: simulation timeout");
    $finish;
end

endmodule
