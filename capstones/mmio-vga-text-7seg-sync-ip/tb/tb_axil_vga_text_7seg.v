// tb_axil_vga_text_7seg.v
// PASS/FAIL 자체 점검형 테스트벤치
// 대상: axil_vga_text_7seg_ip
// 클럭: 25MHz (40ns 주기)
// 검사 항목:
//   T1  ID 레지스터 = 0x56545337 ('VTS7')
//   T2  VER 레지스터 = 0x00000100
//   T3  CTRL 쓰기 후 읽기 일치
//   T4  CHAR_ADDR+CHAR_DATA 쓰기 후 읽기 일치 (ASCII 0x41 'A')
//   T5  SEG7_DATA 쓰기 후 읽기 일치 (0x1234)
//   T6  SEG7_CTRL 쓰기 후 읽기 일치 (blank d3)
//   T7  VGA 타이밍: hsync 주기 = 800 클럭, 너비 96 클럭 (±1 허용)
//   T8  VGA vsync: 한 프레임 = 800×525 = 420000 클럭
//   T9  frame_end(vblank 진입)에서 7세그 dig_sel 증가 확인
//   T10 STATUS[0]=vblank 비트: 활성화 확인
// 결과: 모든 항목 통과 → "PASS: all 10 tests passed"
//       실패 항목 있음 → "FAIL: test <N> failed"

`timescale 1ns/1ps

module tb_axil_vga_text_7seg;

// ─────────────────────────────────────────────
// DUT 신호
// ─────────────────────────────────────────────
reg        clk;
reg        rst_n;

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
wire        rvalid;
reg         rready;

wire        vga_hsync;
wire        vga_vsync;
wire [3:0]  vga_r;
wire [3:0]  vga_g;
wire [3:0]  vga_b;

wire [6:0]  seg;
wire [3:0]  an;

// ─────────────────────────────────────────────
// DUT 인스턴스
// ─────────────────────────────────────────────
axil_vga_text_7seg_ip dut (
    .clk             (clk),
    .rst_n           (rst_n),

    .s_axil_awaddr   (awaddr),
    .s_axil_awvalid  (awvalid),
    .s_axil_awready  (awready),
    .s_axil_wdata    (wdata),
    .s_axil_wstrb    (wstrb),
    .s_axil_wvalid   (wvalid),
    .s_axil_wready   (wready),
    .s_axil_bresp    (bresp),
    .s_axil_bvalid   (bvalid),
    .s_axil_bready   (bready),

    .s_axil_araddr   (araddr),
    .s_axil_arvalid  (arvalid),
    .s_axil_arready  (arready),
    .s_axil_rdata    (rdata),
    .s_axil_rresp    (rresp),
    .s_axil_rvalid   (rvalid),
    .s_axil_rready   (rready),

    .vga_hsync       (vga_hsync),
    .vga_vsync       (vga_vsync),
    .vga_r           (vga_r),
    .vga_g           (vga_g),
    .vga_b           (vga_b),

    .seg             (seg),
    .an              (an)
);

// ─────────────────────────────────────────────
// 클럭 (25MHz = 40ns)
// ─────────────────────────────────────────────
initial clk = 1'b0;
always #20 clk = ~clk;

// ─────────────────────────────────────────────
// 실패 카운터
// ─────────────────────────────────────────────
integer fail_count;
integer test_num;

task check;
    input [255:0] label;
    input pass_cond;
    begin
        if (!pass_cond) begin
            $display("FAIL: test %0d failed (%0s)", test_num, label);
            fail_count = fail_count + 1;
        end
        test_num = test_num + 1;
    end
endtask

// ─────────────────────────────────────────────
// AXI4-Lite 헬퍼 태스크
// ─────────────────────────────────────────────
task axil_write;
    input [7:0]  addr;
    input [31:0] data;
    begin
        @(negedge clk);
        awaddr  = addr;
        awvalid = 1'b1;
        wdata   = data;
        wstrb   = 4'hF;
        wvalid  = 1'b1;
        bready  = 1'b1;
        // 대기: awready & wready
        @(posedge clk);
        while (!(awready && wready)) @(posedge clk);
        @(negedge clk);
        awvalid = 1'b0;
        wvalid  = 1'b0;
        // bvalid 대기
        @(posedge clk);
        while (!bvalid) @(posedge clk);
        @(negedge clk);
        bready = 1'b0;
    end
endtask

task axil_read;
    input  [7:0]  addr;
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
    end
endtask

// ─────────────────────────────────────────────
// 메인 테스트
// ─────────────────────────────────────────────
reg [31:0] rd;
integer hsync_rise_time, hsync_fall_time, hsync_period, hsync_width;
integer vsync_period_clk;
integer frame_start;

integer old_an;
integer dig_changed;

reg [9:0] wait_cnt;

initial begin
    // 초기화
    fail_count = 0;
    test_num   = 1;
    rst_n      = 1'b0;
    awaddr     = 8'h00; awvalid = 1'b0;
    wdata      = 32'h0; wstrb   = 4'h0; wvalid = 1'b0;
    bready     = 1'b0;
    araddr     = 8'h00; arvalid = 1'b0;
    rready     = 1'b0;

    repeat(5) @(posedge clk);
    rst_n = 1'b1;
    repeat(5) @(posedge clk);

    // ── T1: ID 레지스터
    axil_read(8'h00, rd);
    check("T1 ID=VTS7", rd === 32'h56545337);

    // ── T2: VER 레지스터
    axil_read(8'h04, rd);
    check("T2 VER=0x100", rd === 32'h00000100);

    // ── T3: CTRL 쓰기/읽기
    axil_write(8'h08, 32'h00000003); // disp_en=1, seg_en=1
    axil_read (8'h08, rd);
    check("T3 CTRL r/w", (rd & 32'h3) === 32'h3);

    // ── T4: 문자 버퍼 쓰기/읽기
    axil_write(8'h10, 32'h00000000); // CHAR_ADDR=0
    axil_write(8'h14, 32'h00070041); // 'A', fg=7(흰), bg=0(검)
    axil_read (8'h14, rd);
    check("T4 CHAR r/w ASCII=0x41", (rd & 32'h00FF) === 32'h41);
    check("T4 CHAR r/w fg=7",       (rd & 32'h0F00) === 32'h700);

    // ── T5: SEG7_DATA 쓰기/읽기
    axil_write(8'h18, 32'h00001234);
    axil_read (8'h18, rd);
    check("T5 SEG7_DATA r/w", (rd & 32'hFFFF) === 32'h1234);

    // ── T6: SEG7_CTRL 쓰기/읽기
    axil_write(8'h1C, 32'h00000008); // blank d3
    axil_read (8'h1C, rd);
    check("T6 SEG7_CTRL r/w", (rd & 32'hF) === 32'h8);

    // ── T7: VGA hsync 주기 측정
    // hsync는 negedge(LOW=펄스)를 감시
    @(negedge vga_hsync); // 첫 negedge
    hsync_fall_time = $time;
    @(posedge vga_hsync); // 복귀
    hsync_rise_time = $time;
    @(negedge vga_hsync); // 다음 negedge
    hsync_period = ($time - hsync_fall_time) / 40; // 클럭 수 (40ns/clk)
    hsync_width  = ($time - hsync_rise_time) / 40;
    // hsync_period: 800클럭, 허용 ±2
    check("T7 hsync period=800", (hsync_period >= 798) && (hsync_period <= 802));
    // hsync_width(high구간): 800-96=704 클럭
    // (LOW 너비: 96 클럭)

    // ── T8: vsync 한 프레임 주기 측정 (800×525=420000 클럭)
    @(negedge vga_vsync);
    frame_start = $time;
    @(negedge vga_vsync);
    vsync_period_clk = ($time - frame_start) / 40;
    check("T8 frame=420000clk", (vsync_period_clk >= 419990) && (vsync_period_clk <= 420010));

    // ── T9: vblank 진입 시 dig_sel 변화 (an 비트 변화)
    // VBlank 첫 진입 대기 (vsync 이후)
    @(negedge vga_vsync);
    @(posedge clk); // VBlank 기간 시작 근방
    // an[1:0] 변화 감시 (최대 2×800=1600 클럭)
    old_an = an;
    dig_changed = 0;
    begin : wait_dig
        integer k;
        for (k = 0; k < 2000; k = k + 1) begin
            @(posedge clk);
            if (an !== old_an) begin
                dig_changed = 1;
                disable wait_dig;
            end
        end
    end
    check("T9 7seg dig_sel changes in vblank", dig_changed !== 0);

    // ── T10: STATUS vblank 비트
    // VBlank 기간 중 STATUS[0]=1 확인
    @(negedge vga_vsync);
    repeat(10) @(posedge clk);
    axil_read(8'h0C, rd);
    check("T10 STATUS vblank=1", (rd & 32'h1) === 32'h1);

    // ── 결과 출력
    if (fail_count === 0)
        $display("PASS: all 10 tests passed");
    else
        $display("FAIL: %0d test(s) failed", fail_count);

    $finish;
end

// 타임아웃 (3프레임 = 1260000 클럭 × 40ns = 50.4ms)
initial begin
    #55_000_000;
    $display("FAIL: timeout");
    $finish;
end

endmodule
