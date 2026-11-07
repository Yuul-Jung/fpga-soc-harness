// tb_spi_dbg_axil_bridge.v
// Self-checking testbench for axil_spi_dbg_bridge
//
// Tests:
//   1. AXI write via SPI: write 0xDEAD_BEEF to scratchpad reg 0
//   2. AXI read  via SPI: read back; verify data matches
//   3. AXI write via SPI: write 0x1234_5678 to scratchpad reg 1
//   4. AXI read  via SPI: read reg 1; verify
//   5. Unknown CMD byte: verify no AXI transaction issued
//
// Inline AXI4-Lite slave: 4 × 32-bit scratchpad registers
//   base = 0x4000_0000 (address MSByte=0x40 is stripped by bridge)
//   reg 0 @ 0x40000000, reg 1 @ 0x40000004, ...
//
// SPI clock: 1 MHz (period 1000 ns), aclk: 100 MHz (10 ns period)
// Output: PASS / FAIL prefix on each test; final PASS or FAIL summary.

`timescale 1ns / 1ps

module tb_spi_dbg_axil_bridge;

// ---- Clock ----
parameter CLK_PERIOD  = 10;   // 100 MHz
parameter SPI_HALF    = 500;  // SPI half-period (1 MHz)

reg aclk = 0;
always #(CLK_PERIOD/2) aclk = ~aclk;

reg aresetn = 0;

// ---- SPI master signals (driven by testbench) ----
reg  tb_sck  = 0;
reg  tb_mosi = 0;
reg  tb_csn  = 1;
wire tb_miso;

// ---- AXI4-Lite slave signals ----
wire [31:0] m_awaddr;
wire        m_awvalid;
reg         m_awready = 0;

wire [31:0] m_wdata;
wire [3:0]  m_wstrb;
wire        m_wvalid;
reg         m_wready = 0;

reg  [1:0]  m_bresp  = 2'b00;
reg         m_bvalid = 0;
wire        m_bready;

wire [31:0] m_araddr;
wire        m_arvalid;
reg         m_arready = 0;

reg  [31:0] m_rdata  = 32'd0;
reg  [1:0]  m_rresp  = 2'b00;
reg         m_rvalid = 0;
wire        m_rready;

wire        busy;

// ---- DUT ----
axil_spi_dbg_bridge dut (
    .aclk       (aclk),
    .aresetn    (aresetn),
    .sck        (tb_sck),
    .mosi       (tb_mosi),
    .miso       (tb_miso),
    .csn        (tb_csn),
    .m_awaddr   (m_awaddr),
    .m_awvalid  (m_awvalid),
    .m_awready  (m_awready),
    .m_wdata    (m_wdata),
    .m_wstrb    (m_wstrb),
    .m_wvalid   (m_wvalid),
    .m_wready   (m_wready),
    .m_bresp    (m_bresp),
    .m_bvalid   (m_bvalid),
    .m_bready   (m_bready),
    .m_araddr   (m_araddr),
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready),
    .busy       (busy)
);

// ---- Inline AXI4-Lite slave: 4-register scratchpad ----
reg [31:0] scratchpad [0:3];
integer    si;
initial for (si = 0; si < 4; si = si+1) scratchpad[si] = 32'h00000000;

// AXI slave: registered; 1-cycle latency on both read and write
reg [31:0] rd_addr_latch;
reg        rd_pending  = 0;
reg        wr_pending  = 0;
reg [31:0] wr_addr_lat;
reg [31:0] wr_data_lat;

always @(posedge aclk) begin
    // AR channel
    if (m_arvalid && !rd_pending) begin
        m_arready  <= 1'b1;
        rd_addr_latch <= m_araddr;
        rd_pending <= 1'b1;
    end else begin
        m_arready <= 1'b0;
    end

    // R channel: respond one cycle after AR accepted
    if (rd_pending) begin
        m_rdata  <= scratchpad[(rd_addr_latch[3:2]) & 2'h3];
        m_rvalid <= 1'b1;
        m_rresp  <= 2'b00;
        rd_pending <= 1'b0;
    end else if (m_rvalid && m_rready) begin
        m_rvalid <= 1'b0;
    end

    // AW + W channels
    if (m_awvalid && !wr_pending) begin
        m_awready <= 1'b1;
        wr_addr_lat <= m_awaddr;
        wr_pending  <= 1'b1;
    end else begin
        m_awready <= 1'b0;
    end

    if (m_wvalid) begin
        m_wready <= 1'b1;
        wr_data_lat <= m_wdata;
    end else begin
        m_wready <= 1'b0;
    end

    // Write data to scratchpad when both AW and W are accepted
    if (wr_pending && m_wready) begin
        scratchpad[(wr_addr_lat[3:2]) & 2'h3] <= wr_data_lat;
        wr_pending <= 1'b0;
        m_bvalid   <= 1'b1;
        m_bresp    <= 2'b00;
    end else if (m_bvalid && m_bready) begin
        m_bvalid <= 1'b0;
    end
end

// ---- SPI master task ----
// send_recv_byte: drives 8 bits on MOSI, captures 8 bits from MISO
// mode 0: data valid on rising edge; MISO sampled on rising edge
task send_recv_byte;
    input  [7:0] tx;
    output [7:0] rx;
    integer k;
    begin
        rx = 8'h00;
        for (k = 7; k >= 0; k = k-1) begin
            // Set MOSI before rising edge
            tb_mosi = tx[k];
            #(SPI_HALF);
            // Rising edge: slave samples MOSI, master samples MISO
            tb_sck = 1;
            #1;                    // small delay so MISO is stable
            rx[k] = tb_miso;
            #(SPI_HALF-1);
            // Falling edge: slave shifts next MISO bit
            tb_sck = 0;
        end
    end
endtask

// SPI write transaction (8-byte frame, CMD=0x01)
task spi_write;
    input [23:0] addr;
    input [31:0] data;
    reg [7:0] dummy;
    begin
        tb_csn = 0; #(SPI_HALF);
        send_recv_byte(8'h01,          dummy);  // B0: CMD=write
        send_recv_byte(addr[23:16],    dummy);  // B1
        send_recv_byte(addr[15:8],     dummy);  // B2
        send_recv_byte(addr[7:0],      dummy);  // B3
        send_recv_byte(data[31:24],    dummy);  // B4
        send_recv_byte(data[23:16],    dummy);  // B5
        send_recv_byte(data[15:8],     dummy);  // B6
        send_recv_byte(data[7:0],      dummy);  // B7
        tb_csn = 1; #(SPI_HALF*2);
    end
endtask

// SPI read transaction (8-byte frame, CMD=0x02)
// Returns 32-bit data captured from B4..B7 of MISO
task spi_read;
    input  [23:0] addr;
    output [31:0] data;
    reg [7:0] d4, d5, d6, d7, dummy;
    begin
        tb_csn = 0; #(SPI_HALF);
        send_recv_byte(8'h02,       dummy);  // B0: CMD=read
        send_recv_byte(addr[23:16], dummy);  // B1
        send_recv_byte(addr[15:8],  dummy);  // B2
        send_recv_byte(addr[7:0],   dummy);  // B3: AXI read issued now
        send_recv_byte(8'h00,       d4);     // B4: RD[31:24]
        send_recv_byte(8'h00,       d5);     // B5: RD[23:16]
        send_recv_byte(8'h00,       d6);     // B6: RD[15:8]
        send_recv_byte(8'h00,       d7);     // B7: RD[7:0]
        tb_csn = 1; #(SPI_HALF*2);
        data = {d4, d5, d6, d7};
    end
endtask

// ---- Pass/fail counters ----
integer pass_cnt = 0;
integer fail_cnt = 0;

task check;
    input [255:0] label;
    input [31:0]  got;
    input [31:0]  exp;
    begin
        if (got !== exp) begin
            $display("FAIL %0s: got=0x%08X exp=0x%08X", label, got, exp);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("PASS %0s: 0x%08X", label, got);
            pass_cnt = pass_cnt + 1;
        end
    end
endtask

// ---- Stimulus ----
reg [31:0] rd_data;

initial begin
    // Reset
    aresetn = 0;
    tb_csn  = 1;
    tb_sck  = 0;
    tb_mosi = 0;
    repeat(20) @(posedge aclk);
    aresetn = 1;
    repeat(5) @(posedge aclk);

    // Test 1: Write 0xDEAD_BEEF to reg 0 (addr 0x000000)
    spi_write(24'h000000, 32'hDEAD_BEEF);
    repeat(20) @(posedge aclk);  // wait for AXI write to complete
    check("WR reg0 scratchpad", scratchpad[0], 32'hDEAD_BEEF);

    // Test 2: Read back reg 0
    spi_read(24'h000000, rd_data);
    repeat(5) @(posedge aclk);
    check("RD reg0 via MISO",  rd_data, 32'hDEAD_BEEF);

    // Test 3: Write 0x1234_5678 to reg 1 (addr 0x000004)
    spi_write(24'h000004, 32'h12345678);
    repeat(20) @(posedge aclk);
    check("WR reg1 scratchpad", scratchpad[1], 32'h12345678);

    // Test 4: Read reg 1
    spi_read(24'h000004, rd_data);
    repeat(5) @(posedge aclk);
    check("RD reg1 via MISO",  rd_data, 32'h12345678);

    // Test 5: Write with unknown CMD — no AXI write should occur
    begin : t5
        reg [7:0] dummy;
        scratchpad[2] = 32'hAAAA_AAAA;  // preset
        tb_csn = 0; #(SPI_HALF);
        send_recv_byte(8'hFF, dummy);           // unknown CMD
        send_recv_byte(8'h00, dummy);
        send_recv_byte(8'h00, dummy);
        send_recv_byte(8'h08, dummy);           // reg 2 addr
        send_recv_byte(8'hBB, dummy);
        send_recv_byte(8'hBB, dummy);
        send_recv_byte(8'hBB, dummy);
        send_recv_byte(8'hBB, dummy);
        tb_csn = 1; #(SPI_HALF*4);
        repeat(20) @(posedge aclk);
        check("unknown CMD no-write", scratchpad[2], 32'hAAAA_AAAA);
    end

    // Summary
    #100;
    if (fail_cnt === 0)
        $display("PASS all %0d checks", pass_cnt);
    else
        $display("FAIL %0d/%0d checks failed", fail_cnt, pass_cnt+fail_cnt);

    $finish;
end

// Safety timeout
initial begin
    #2_000_000;
    $display("FAIL timeout");
    $finish;
end

endmodule
