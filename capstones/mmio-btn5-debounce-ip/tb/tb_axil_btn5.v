// tb_axil_btn5.v — 자체 점검형 테스트벤치 for axil_btn5
// 테스트 항목:
//   1. VERSION 레지스터 확인
//   2. DEBOUNCE_MS / LONGPRESS_MS 레지스터 R/W
//   3. IRQ_EN 레지스터 R/W
//   4. 단일 버튼 디바운스 + press_edge IRQ
//   5. 단일 버튼 release_edge IRQ (W1C 클리어 포함)
//   6. 긴 누름 플래그 + IRQ
//   7. 5개 버튼 동시 디바운스
//   8. CTRL irq_clr_all 비트
// 출력: PASS 또는 FAIL로 시작하는 줄 (CI grep으로 확인)
// Verilog-2001. No external IP.

`timescale 1ns/1ps
`default_nettype none

module tb_axil_btn5;

// ─── 클럭/리셋 ──────────────────────────────────────────────────
reg clk = 0;
reg rst = 1;
always #5 clk = ~clk;  // 100 MHz (10ns 주기)

// ─── DUT 신호 ───────────────────────────────────────────────────
reg  [4:0]  btn_in  = 5'b0;
wire        irq;
reg         awvalid = 0;
wire        awready;
reg  [7:0]  awaddr  = 0;
reg         wvalid  = 0;
wire        wready;
reg  [31:0] wdata   = 0;
wire        bvalid;
reg         bready  = 1;
wire [1:0]  bresp;
reg         arvalid = 0;
wire        arready;
reg  [7:0]  araddr  = 0;
wire        rvalid;
reg         rready  = 1;
wire [31:0] rdata;
wire [1:0]  rresp;

// ─── DUT 인스턴스 ───────────────────────────────────────────────
// 시뮬레이션 속도를 위해 CLK_MHZ=1, DEB_MS=2(=2000 클럭), LP_MS=5(=5000 클럭)
axil_btn5 #(
    .CLK_MHZ    (1),
    .DEB_MS_DEF (2),
    .LP_MS_DEF  (5)
) dut (
    .clk              (clk),
    .rst              (rst),
    .btn_in           (btn_in),
    .irq              (irq),
    .s_axil_awvalid   (awvalid),
    .s_axil_awready   (awready),
    .s_axil_awaddr    (awaddr),
    .s_axil_wvalid    (wvalid),
    .s_axil_wready    (wready),
    .s_axil_wdata     (wdata),
    .s_axil_wstrb     (4'hF),
    .s_axil_bvalid    (bvalid),
    .s_axil_bready    (bready),
    .s_axil_bresp     (bresp),
    .s_axil_arvalid   (arvalid),
    .s_axil_arready   (arready),
    .s_axil_araddr    (araddr),
    .s_axil_rvalid    (rvalid),
    .s_axil_rready    (rready),
    .s_axil_rdata     (rdata),
    .s_axil_rresp     (rresp)
);

// ─── 헬퍼 ───────────────────────────────────────────────────────
integer fail = 0;
reg [31:0] rd_val;

// AXI 쓰기 태스크
task axil_write;
    input [7:0]  addr;
    input [31:0] data;
    begin
        @(posedge clk); #1;
        awvalid = 1; awaddr = addr;
        wvalid  = 1; wdata  = data;
        @(posedge clk);
        while (!awready) @(posedge clk);
        #1; awvalid = 0;
        while (!wready)  @(posedge clk);
        #1; wvalid  = 0;
        while (!bvalid)  @(posedge clk);
        @(posedge clk); #1;
    end
endtask

// AXI 읽기 태스크
task axil_read;
    input  [7:0]  addr;
    output [31:0] data;
    begin
        @(posedge clk); #1;
        arvalid = 1; araddr = addr;
        @(posedge clk);
        while (!arready) @(posedge clk);
        #1; arvalid = 0;
        while (!rvalid)  @(posedge clk);
        data = rdata;
        @(posedge clk); #1;
    end
endtask

// N 클럭 대기
task wait_clk;
    input integer n;
    integer k;
    begin
        for (k = 0; k < n; k = k + 1)
            @(posedge clk);
    end
endtask

// IRQ 대기 (타임아웃)
task wait_irq;
    input integer timeout;
    integer cnt;
    begin
        cnt = 0;
        while (!irq && cnt < timeout) begin
            @(posedge clk);
            cnt = cnt + 1;
        end
        if (cnt >= timeout) begin
            $display("FAIL: IRQ 타임아웃 (%0d 클럭)", timeout);
            fail = fail + 1;
        end
    end
endtask

// ─── 테스트 본체 ─────────────────────────────────────────────────
initial begin
    // ── 1. 리셋 ──────────────────────────────────────────────────
    rst = 1;
    repeat(10) @(posedge clk);
    rst = 0;
    repeat(5)  @(posedge clk);

    // ── 2. VERSION 레지스터 ───────────────────────────────────────
    axil_read(8'h1C, rd_val);
    if (rd_val !== 32'h00010001) begin
        $display("FAIL: VERSION 기대 0x00010001 실제 0x%08X", rd_val);
        fail = fail + 1;
    end else
        $display("INFO: VERSION OK (0x%08X)", rd_val);

    // ── 3. DEBOUNCE_MS R/W ────────────────────────────────────────
    axil_write(8'h0C, 32'd10);
    axil_read (8'h0C, rd_val);
    if (rd_val !== 32'd10) begin
        $display("FAIL: DEBOUNCE_MS R/W 기대 10 실제 %0d", rd_val);
        fail = fail + 1;
    end else
        $display("INFO: DEBOUNCE_MS R/W OK");

    // LONGPRESS_MS R/W
    axil_write(8'h10, 32'd20);
    axil_read (8'h10, rd_val);
    if (rd_val !== 32'd20) begin
        $display("FAIL: LONGPRESS_MS R/W 기대 20 실제 %0d", rd_val);
        fail = fail + 1;
    end else
        $display("INFO: LONGPRESS_MS R/W OK");

    // ── 4. IRQ_EN R/W ────────────────────────────────────────────
    axil_write(8'h14, 32'h1F);  // 모든 버튼 IRQ 활성화
    axil_read (8'h14, rd_val);
    if (rd_val[4:0] !== 5'h1F) begin
        $display("FAIL: IRQ_EN R/W 기대 0x1F 실제 0x%02X", rd_val[4:0]);
        fail = fail + 1;
    end else
        $display("INFO: IRQ_EN R/W OK");

    // ── 5. 디바운스 복원 (기본값 DEB_MS_DEF=2 → CLK_PER_MS=1_000)
    // CLK_MHZ=1 → CLK_PER_MS=1000. DEBOUNCE_MS=2 → thr=2000 클럭.
    axil_write(8'h0C, 32'd2);    // DEBOUNCE_MS=2 (2000클럭)
    axil_write(8'h10, 32'd5);    // LONGPRESS_MS=5 (5000클럭)

    // ── 6. CTRL irq_global_en 세팅 ──────────────────────────────
    axil_write(8'h00, 32'h01);   // irq_global_en=1

    // ── 7. btn[0](BTNR) 눌림 → 디바운스 대기 → press_edge IRQ ──
    btn_in[0] = 1;
    // 2001 클럭 대기 (디바운스 임계값 2000 초과)
    wait_clk(2100);

    // STATUS 확인
    axil_read(8'h04, rd_val);
    if (rd_val[0] !== 1'b1) begin
        $display("FAIL: btn[0] STATUS 기대 1 실제 %0d", rd_val[0]);
        fail = fail + 1;
    end else
        $display("INFO: btn[0] STATUS=1 OK");

    // IRQ_STATUS 확인 (press_edge 발생 → bit[0] 세트)
    axil_read(8'h18, rd_val);
    if (rd_val[0] !== 1'b1) begin
        $display("FAIL: btn[0] IRQ_STATUS press_edge 기대 1 실제 %0d", rd_val[0]);
        fail = fail + 1;
    end else
        $display("INFO: btn[0] IRQ_STATUS press_edge OK");

    // IRQ 라인 확인
    if (!irq) begin
        $display("FAIL: IRQ 미발생 (irq=0)");
        fail = fail + 1;
    end else
        $display("INFO: IRQ asserted OK");

    // ── 8. W1C 클리어 → IRQ 해제 ────────────────────────────────
    axil_write(8'h18, 32'h1F);   // IRQ_STATUS W1C 전체 클리어
    @(posedge clk); @(posedge clk);
    if (irq) begin
        $display("FAIL: W1C 후 IRQ 여전히 assert");
        fail = fail + 1;
    end else
        $display("INFO: W1C 후 IRQ 해제 OK");

    axil_read(8'h18, rd_val);
    if (rd_val[4:0] !== 5'b0) begin
        $display("FAIL: W1C 후 IRQ_STATUS 기대 0 실제 0x%02X", rd_val[4:0]);
        fail = fail + 1;
    end else
        $display("INFO: IRQ_STATUS 클리어 OK");

    // ── 9. 버튼 놓임 → release_edge IRQ ─────────────────────────
    btn_in[0] = 0;
    wait_clk(2100);  // 디바운스 완료

    axil_read(8'h04, rd_val);
    if (rd_val[0] !== 1'b0) begin
        $display("FAIL: btn[0] STATUS 놓임 기대 0 실제 %0d", rd_val[0]);
        fail = fail + 1;
    end else
        $display("INFO: btn[0] STATUS=0 OK (놓임)");

    axil_read(8'h18, rd_val);
    if (rd_val[0] !== 1'b1) begin
        $display("FAIL: btn[0] release_edge IRQ_STATUS 기대 1 실제 %0d", rd_val[0]);
        fail = fail + 1;
    end else
        $display("INFO: btn[0] release_edge IRQ_STATUS OK");

    // 클리어
    axil_write(8'h18, 32'h1F);

    // ── 10. 긴 누름 테스트 ─────────────────────────────────────
    btn_in[1] = 1;  // btn[1]=BTNL 눌림
    wait_clk(2100); // 디바운스 완료
    // press_edge 클리어
    axil_write(8'h18, 32'h1F);

    // 긴 누름 임계값: LONGPRESS_MS=5 → 5000 클럭 대기
    wait_clk(5100);

    axil_read(8'h08, rd_val);  // LONGPRESS 레지스터
    if (rd_val[1] !== 1'b1) begin
        $display("FAIL: btn[1] LONGPRESS 기대 1 실제 %0d", rd_val[1]);
        fail = fail + 1;
    end else
        $display("INFO: btn[1] LONGPRESS=1 OK");

    // 긴 누름 IRQ_STATUS 확인
    axil_read(8'h18, rd_val);
    if (rd_val[1] !== 1'b1) begin
        $display("FAIL: btn[1] longpress IRQ_STATUS 기대 1 실제 %0d", rd_val[1]);
        fail = fail + 1;
    end else
        $display("INFO: btn[1] longpress IRQ_STATUS OK");

    // 버튼 놓임 → LONGPRESS 플래그 클리어
    btn_in[1] = 0;
    wait_clk(2100);
    axil_read(8'h08, rd_val);
    if (rd_val[1] !== 1'b0) begin
        $display("FAIL: btn[1] LONGPRESS 놓임 후 기대 0 실제 %0d", rd_val[1]);
        fail = fail + 1;
    end else
        $display("INFO: btn[1] LONGPRESS 놓임 후 클리어 OK");

    // ── 11. 5개 버튼 동시 디바운스 ──────────────────────────────
    axil_write(8'h18, 32'h1F);  // 클리어
    btn_in = 5'h1F;  // 전체 버튼 동시 누름
    wait_clk(2100);

    axil_read(8'h04, rd_val);
    if (rd_val[4:0] !== 5'h1F) begin
        $display("FAIL: 5버튼 동시 STATUS 기대 0x1F 실제 0x%02X", rd_val[4:0]);
        fail = fail + 1;
    end else
        $display("INFO: 5버튼 동시 STATUS=0x1F OK");

    axil_read(8'h18, rd_val);
    if (rd_val[4:0] !== 5'h1F) begin
        $display("FAIL: 5버튼 동시 IRQ_STATUS 기대 0x1F 실제 0x%02X", rd_val[4:0]);
        fail = fail + 1;
    end else
        $display("INFO: 5버튼 동시 IRQ_STATUS=0x1F OK");

    btn_in = 5'h00;

    // ── 12. CTRL irq_clr_all ─────────────────────────────────────
    wait_clk(2100);  // 놓임 디바운스 완료

    // IRQ_STATUS에 무언가 세트됐을 것
    axil_read(8'h18, rd_val);
    $display("INFO: irq_clr_all 전 IRQ_STATUS=0x%02X", rd_val[4:0]);

    // irq_clr_all(bit[1]) 쓰기
    axil_write(8'h00, 32'h03);   // irq_global_en=1, irq_clr_all=1
    @(posedge clk); @(posedge clk);

    axil_read(8'h18, rd_val);
    if (rd_val[4:0] !== 5'b0) begin
        $display("FAIL: irq_clr_all 후 IRQ_STATUS 기대 0 실제 0x%02X", rd_val[4:0]);
        fail = fail + 1;
    end else
        $display("INFO: irq_clr_all 후 IRQ_STATUS=0 OK");

    // ── 13. IRQ_EN 마스크 테스트 ─────────────────────────────────
    axil_write(8'h14, 32'h00);   // IRQ_EN=0 (모두 비활성화)
    axil_write(8'h00, 32'h01);   // irq_global_en=1
    btn_in[0] = 1;
    wait_clk(2100);
    // IRQ_STATUS는 세트되지만 irq 라인은 assert 안 됨
    axil_read(8'h18, rd_val);
    $display("INFO: IRQ_EN=0일 때 IRQ_STATUS=0x%02X", rd_val[4:0]);
    if (irq) begin
        $display("FAIL: IRQ_EN=0인데 irq=1");
        fail = fail + 1;
    end else
        $display("INFO: IRQ_EN=0 → irq=0 OK");

    btn_in[0] = 0;
    wait_clk(2100);

    // ── 14. 최종 보고 ────────────────────────────────────────────
    if (fail == 0)
        $display("PASS: 모든 체크 통과");
    else
        $display("FAIL: %0d 개 체크 실패", fail);

    $finish;
end

// 전역 타임아웃
initial begin
    #50_000_000;
    $display("FAIL: 전역 시뮬레이션 타임아웃");
    $finish;
end

endmodule
`default_nettype wire
