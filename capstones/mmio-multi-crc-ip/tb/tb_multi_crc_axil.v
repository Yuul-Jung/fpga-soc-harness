// tb_multi_crc_axil.v — self-checking testbench for multi_crc_axil
// 통과: "PASS", 실패: "FAIL" 로 시작하는 줄 출력
// 비교: !== 사용 (X/Z도 실패)
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
`default_nettype none
`timescale 1ns/1ps

module tb_multi_crc_axil;

// -------------------------------------------------------------------------
// Clock/Reset
// -------------------------------------------------------------------------
reg clk;
reg rstn;
initial clk = 0;
always #5 clk = ~clk; // 100 MHz

// -------------------------------------------------------------------------
// DUT 신호
// -------------------------------------------------------------------------
reg  [3:0]  awaddr;
reg         awvalid;
wire        awready;
reg  [31:0] wdata;
reg  [3:0]  wstrb;
reg         wvalid;
wire        wready;
wire [1:0]  bresp;
wire        bvalid;
reg         bready;
reg  [3:0]  araddr;
reg         arvalid;
wire        arready;
wire [31:0] rdata;
wire [1:0]  rresp;
wire        rvalid;
reg         rready;
wire        irpt;

multi_crc_axil #(.ADDR_WIDTH(4)) dut (
    .s_axi_aclk    (clk),
    .s_axi_aresetn (rstn),
    .s_axi_awaddr  (awaddr),
    .s_axi_awvalid (awvalid),
    .s_axi_awready (awready),
    .s_axi_wdata   (wdata),
    .s_axi_wstrb   (wstrb),
    .s_axi_wvalid  (wvalid),
    .s_axi_wready  (wready),
    .s_axi_bresp   (bresp),
    .s_axi_bvalid  (bvalid),
    .s_axi_bready  (bready),
    .s_axi_araddr  (araddr),
    .s_axi_arvalid (arvalid),
    .s_axi_arready (arready),
    .s_axi_rdata   (rdata),
    .s_axi_rresp   (rresp),
    .s_axi_rvalid  (rvalid),
    .s_axi_rready  (rready),
    .ip2intc_irpt  (irpt)
);

// -------------------------------------------------------------------------
// 카운터
// -------------------------------------------------------------------------
integer fail_count;
integer test_num;

// -------------------------------------------------------------------------
// AXI 태스크
// -------------------------------------------------------------------------
task axi_write;
    input [3:0] addr;
    input [31:0] data;
    begin
        @(negedge clk);
        awaddr  = addr;
        awvalid = 1'b1;
        wdata   = data;
        wstrb   = 4'hF;
        wvalid  = 1'b1;
        bready  = 1'b1;
        @(posedge clk); // 핸드쉐이크 사이클
        while (!(awready && wready)) @(posedge clk);
        @(negedge clk);
        awvalid = 1'b0;
        wvalid  = 1'b0;
        @(posedge clk);
        while (!bvalid) @(posedge clk);
        @(negedge clk);
        bready  = 1'b0;
        @(posedge clk);
    end
endtask

task axi_read;
    input  [3:0]  addr;
    output [31:0] data;
    begin
        @(negedge clk);
        araddr  = addr;
        arvalid = 1'b1;
        rready  = 1'b1;
        @(posedge clk);
        while (!arready) @(posedge clk);
        @(negedge clk);
        arvalid = 1'b0;
        @(posedge clk);
        while (!rvalid) @(posedge clk);
        data = rdata;
        @(negedge clk);
        rready = 1'b0;
        @(posedge clk);
    end
endtask

task check_eq;
    input [31:0] got;
    input [31:0] exp;
    input [63:0] label;
    begin
        test_num = test_num + 1;
        if (got !== exp) begin
            $display("FAIL #%0d %s: got=0x%08X exp=0x%08X", test_num, label, got, exp);
            fail_count = fail_count + 1;
        end
    end
endtask

// -------------------------------------------------------------------------
// 메인
// -------------------------------------------------------------------------
reg [31:0] rd;

initial begin
    fail_count = 0;
    test_num   = 0;
    awaddr  = 0; awvalid = 0;
    wdata   = 0; wstrb   = 0; wvalid  = 0; bready  = 0;
    araddr  = 0; arvalid = 0; rready  = 0;
    rstn = 0;
    repeat(4) @(posedge clk);
    rstn = 1;
    repeat(2) @(posedge clk);

    // =====================================================================
    // TEST 1: CRC-8 (mode=00)
    // 알고리즘: poly=0x8C(reflected), init=0xFF
    // 테스트 벡터: init=0xFF, 바이트 0xFF 1개 → CRC-8 결과
    // 수동 계산:
    //   t=0xFF, i=0: (t[0]^d[0])=(1^1)=0 → t={0,0x7F}=0x7F
    //   i=1: (t[0]^d[1])=(1^1)=0 → t=0x3F
    //   i=2: 0x3F→(1^1)=0→0x1F
    //   i=3: 0x1F→(1^1)=0→0x0F
    //   i=4: 0x0F→(1^1)=0→0x07
    //   i=5: 0x07→(1^1)=0→0x03
    //   i=6: 0x03→(1^1)=0→0x01
    //   i=7: 0x01→(1^1)=0→0x00
    //   결과: 0x00
    // =====================================================================
    axi_write(4'h0, 32'h0);        // MODE=CRC-8
    axi_write(4'hC, 32'h1);        // CTRL INIT
    repeat(2) @(posedge clk);
    axi_read(4'h8, rd);
    check_eq(rd, 32'h000000FF, "CRC8 after INIT");  // init=0xFF

    axi_write(4'h4, 32'hFF);       // DATA_IN = 0xFF
    repeat(3) @(posedge clk);      // 1사이클 레이턴시 + 여유
    axi_read(4'h8, rd);
    check_eq(rd, 32'h00000000, "CRC8 0xFF->0x00");

    // =====================================================================
    // TEST 2: CRC-16-CCITT (mode=01)
    // init=0xFFFF, 바이트 0xFF 1개
    // 수동 계산: MSB first, poly=0x1021
    //   t=0xFFFF, i=7: (t[15]^d[7])=(1^1)=0 → t={0x7FFF,0}=0xFFFE
    //   i=6: (1^1)=0 → 0xFFFC
    //   i=5: 0→0xFFF8
    //   i=4: 0→0xFFF0
    //   i=3: 0→0xFFE0
    //   i=2: 0→0xFFC0
    //   i=1: 0→0xFF80
    //   i=0: 0→0xFF00
    //   결과: 0xFF00
    // =====================================================================
    axi_write(4'h0, 32'h1);        // MODE=CRC-16
    axi_write(4'hC, 32'h1);        // CTRL INIT
    repeat(2) @(posedge clk);
    axi_read(4'h8, rd);
    check_eq(rd, 32'h0000FFFF, "CRC16 after INIT");

    axi_write(4'h4, 32'hFF);       // DATA_IN = 0xFF
    repeat(3) @(posedge clk);
    axi_read(4'h8, rd);
    check_eq(rd, 32'h0000FF00, "CRC16 0xFF->0xFF00");

    // =====================================================================
    // TEST 3: CRC-32 (mode=10)
    // init=0xFFFFFFFF, 바이트 0xFF 1개
    // 수동 계산: reflected poly=0xEDB88320, all bits same
    //   각 스텝: t[0]^d[i] 모두 1^1=0 (init과 data가 모두 0xFF)
    //   t = {0,t[31:1]} (오른쪽 시프트, XOR 없음)
    //   8번 시프트 후: 0xFFFFFFFF >> 8 = 0x00FFFFFF
    // =====================================================================
    axi_write(4'h0, 32'h2);        // MODE=CRC-32
    axi_write(4'hC, 32'h1);        // CTRL INIT
    repeat(2) @(posedge clk);
    axi_read(4'h8, rd);
    check_eq(rd, 32'hFFFFFFFF, "CRC32 after INIT");

    axi_write(4'h4, 32'hFF);       // DATA_IN = 0xFF
    repeat(3) @(posedge clk);
    axi_read(4'h8, rd);
    check_eq(rd, 32'h00FFFFFF, "CRC32 0xFF->0x00FFFFFF");

    // =====================================================================
    // TEST 4: 모드 전환 후 INIT 독립성 확인
    // CRC-32에서 쓴 뒤 CRC-8로 전환하고 INIT → CRC-8 초기값=0xFF
    // =====================================================================
    axi_write(4'h0, 32'h0);        // MODE=CRC-8
    axi_write(4'hC, 32'h1);        // CTRL INIT
    repeat(2) @(posedge clk);
    axi_read(4'h8, rd);
    check_eq(rd, 32'h000000FF, "CRC8 after mode switch INIT");

    // =====================================================================
    // TEST 5: MODE 레지스터 읽기
    // =====================================================================
    axi_write(4'h0, 32'h2);        // MODE=CRC-32
    axi_read(4'h0, rd);
    check_eq(rd[1:0], 2'b10, "MODE reg readback");

    // =====================================================================
    // TEST 6: 인터럽트 상수 0
    // =====================================================================
    test_num = test_num + 1;
    if (irpt !== 1'b0) begin
        $display("FAIL #%0d irpt: got=%b exp=0", test_num, irpt);
        fail_count = fail_count + 1;
    end

    // =====================================================================
    // 결과
    // =====================================================================
    repeat(2) @(posedge clk);
    if (fail_count == 0)
        $display("PASS all %0d checks", test_num);
    else
        $display("FAIL %0d/%0d checks failed", fail_count, test_num);

    $finish;
end

// 타임아웃 보호
initial begin
    #100000;
    $display("FAIL timeout");
    $finish;
end

endmodule
`default_nettype wire
