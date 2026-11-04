// tb_axil_wdt_wrap.v — 자체 점검형 테스트벤치
// I-070 AXI4-Lite 워치독 IP (mmio-wdt-tier1, T1)
// Verilog-2001. iverilog 호환.
//
// 통과 → "PASS" 로 시작하는 줄, 실패 → "FAIL" 로 시작하는 줄 출력.
// 비교는 !== 로 X/Z도 실패로 센다.
//
// 테스트 케이스:
//   TC1: LOAD=10 → ENABLE → 10클럭 뒤 STATUS.TIMEOUT_LAT=1
//   TC2: LOAD=20 → ENABLE → 5클럭 뒤 KICK → TIMEOUT_LAT 없음 (킥이 타임아웃 방지)
//   TC3: SRST → 타임아웃 클리어 후 카운터 재적재 확인
//   TC4: IRQ 동작 → TIMEOUT 후 IRQ_PEND=1, W1C 클리어
//   TC5: ENABLE=0 → 카운터 정지, TIMEOUT_LAT 없음

`timescale 1ns/1ps
`default_nettype none

module tb_axil_wdt_wrap;

    // ── 클럭 ──────────────────────────────────────────────
    reg aclk;
    initial aclk = 0;
    always #5 aclk = ~aclk;  // 100 MHz

    // ── DUT 포트 ──────────────────────────────────────────
    reg        aresetn;
    reg [15:0] s_awaddr;
    reg        s_awvalid;
    wire       s_awready;
    reg [31:0] s_wdata;
    reg  [3:0] s_wstrb;
    reg        s_wvalid;
    wire       s_wready;
    wire [1:0] s_bresp;
    wire       s_bvalid;
    reg        s_bready;
    reg [15:0] s_araddr;
    reg        s_arvalid;
    wire       s_arready;
    wire [31:0] s_rdata;
    wire [1:0]  s_rresp;
    wire        s_rvalid;
    reg         s_rready;
    wire        wdt_rst;
    wire        wdt_irq;

    // ── DUT 인스턴스 ─────────────────────────────────────
    axil_wdt_wrap dut (
        .aclk      (aclk),
        .aresetn   (aresetn),
        .s_awaddr  (s_awaddr),
        .s_awvalid (s_awvalid),
        .s_awready (s_awready),
        .s_wdata   (s_wdata),
        .s_wstrb   (s_wstrb),
        .s_wvalid  (s_wvalid),
        .s_wready  (s_wready),
        .s_bresp   (s_bresp),
        .s_bvalid  (s_bvalid),
        .s_bready  (s_bready),
        .s_araddr  (s_araddr),
        .s_arvalid (s_arvalid),
        .s_arready (s_arready),
        .s_rdata   (s_rdata),
        .s_rresp   (s_rresp),
        .s_rvalid  (s_rvalid),
        .s_rready  (s_rready),
        .wdt_rst   (wdt_rst),
        .wdt_irq   (wdt_irq)
    );

    // ── 실패 카운터 ───────────────────────────────────────
    integer fail_cnt;

    // ── AXI4-Lite 헬퍼 태스크 ────────────────────────────
    task axil_write;
        input [15:0] addr;
        input [31:0] data;
        begin
            @(posedge aclk); #1;
            s_awaddr = addr; s_awvalid = 1;
            s_wdata  = data; s_wvalid  = 1; s_wstrb = 4'hF;
            s_bready = 1;
            wait(s_bvalid); @(posedge aclk); #1;
            s_awvalid = 0;
            s_wvalid  = 0;
            s_bready  = 0;
        end
    endtask

    task axil_read;
        input  [15:0] addr;
        output [31:0] data;
        begin
            @(posedge aclk); #1;
            s_araddr = addr; s_arvalid = 1;
            wait(s_arready); @(posedge aclk); #1;
            s_arvalid = 0;
            s_rready  = 1;
            wait(s_rvalid);
            data = s_rdata;
            @(posedge aclk); #1;
            s_rready = 0;
        end
    endtask

    // ── 체크 헬퍼 ────────────────────────────────────────
    task check_eq;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got !== exp) begin
                $display("FAIL %0s: got=%0h exp=%0h", name, got, exp);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("pass %0s: %0h", name, got);
            end
        end
    endtask

    // ── 메인 ─────────────────────────────────────────────
    reg [31:0] rd;
    integer i;

    initial begin
        // 초기화
        fail_cnt  = 0;
        aresetn   = 0;
        s_awvalid = 0; s_wvalid = 0; s_bready = 0;
        s_arvalid = 0; s_rready = 0;
        s_awaddr  = 0; s_wdata = 0; s_wstrb = 0;
        s_araddr  = 0;

        repeat(5) @(posedge aclk);
        aresetn = 1;
        repeat(2) @(posedge aclk);

        // ────────────────────────────────────────────────
        // TC1: LOAD=10 → ENABLE → 타임아웃 확인
        //   10클럭 카운트다운 후 TIMEOUT_LAT=1, wdt_rst 펄스
        // ────────────────────────────────────────────────
        $display("=== TC1: LOAD=10, ENABLE → 타임아웃 ===");
        axil_write(16'h0004, 32'd10);    // LOAD=10
        axil_write(16'hFFF8, 32'h0);     // IRQ_EN=0
        axil_write(16'h0000, 32'h1);     // CTRL: ENABLE=1

        // 10클럭 감소 + 여유
        repeat(20) @(posedge aclk);

        axil_read(16'h0008, rd);
        check_eq("TC1:TIMEOUT_LAT", rd & 32'h1, 32'h1);
        check_eq("TC1:RUNNING",     (rd >> 1) & 32'h1, 32'h0);

        // ID/VER 확인
        axil_read(16'hFFF0, rd);
        check_eq("TC1:ID_REG",  rd, 32'h57445431);
        axil_read(16'hFFF4, rd);
        check_eq("TC1:VER_REG", rd, 32'h00010000);

        // ────────────────────────────────────────────────
        // TC2: KICK이 타임아웃을 방지한다
        //   LOAD=20, ENABLE, 10클럭 후 KICK → 추가 20클럭 후 TIMEOUT_LAT=1
        //   단, KICK 직후 20클럭 이내에는 TIMEOUT_LAT=0 이어야 함
        // ────────────────────────────────────────────────
        $display("=== TC2: KICK이 타임아웃을 방지 ===");
        // 먼저 현재 타임아웃 상태 클리어 (SRST)
        axil_write(16'h0000, 32'h2);     // CTRL: SRST=1
        repeat(3) @(posedge aclk);

        axil_write(16'h0004, 32'd20);    // LOAD=20
        axil_write(16'h0000, 32'h1);     // ENABLE=1

        repeat(10) @(posedge aclk);
        axil_write(16'h000C, 32'h1);     // KICK

        repeat(5) @(posedge aclk);
        axil_read(16'h0008, rd);
        check_eq("TC2:TIMEOUT_LAT_after_kick", rd & 32'h1, 32'h0);
        check_eq("TC2:RUNNING_after_kick",     (rd >> 1) & 32'h1, 32'h1);

        // 20클럭 더 대기 → 타임아웃
        repeat(25) @(posedge aclk);
        axil_read(16'h0008, rd);
        check_eq("TC2:TIMEOUT_LAT_eventual", rd & 32'h1, 32'h1);

        // ────────────────────────────────────────────────
        // TC3: SRST가 타임아웃을 클리어하고 카운터를 재적재한다
        // ────────────────────────────────────────────────
        $display("=== TC3: SRST 클리어 ===");
        axil_write(16'h0004, 32'd50);    // LOAD=50
        axil_write(16'h0000, 32'h2);     // SRST

        repeat(3) @(posedge aclk);
        axil_read(16'h0008, rd);
        check_eq("TC3:TIMEOUT_LAT_cleared", rd & 32'h1, 32'h0);

        axil_read(16'h0010, rd);         // COUNT 읽기
        // SRST 후 enable=1이면 RUNNING 상태, count_out≈50
        // (AXI 레이턴시로 정확한 값이 아닐 수 있으나 50 이하여야 함)
        if (rd > 32'd50) begin
            $display("FAIL TC3:COUNT_after_SRST: got=%0d (expected <=50)", rd);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("pass TC3:COUNT_after_SRST: %0d (<=50)", rd);
        end

        // ────────────────────────────────────────────────
        // TC4: IRQ 동작 — TIMEOUT 후 IRQ_PEND=1, W1C 클리어
        // ────────────────────────────────────────────────
        $display("=== TC4: IRQ 동작 ===");
        // 현재 카운터 클리어
        axil_write(16'h0000, 32'h2);     // SRST
        repeat(3) @(posedge aclk);
        axil_write(16'h0000, 32'h0);     // ENABLE=0
        repeat(2) @(posedge aclk);

        axil_write(16'hFFF8, 32'h1);     // IRQ_EN=1
        axil_write(16'h0004, 32'd5);     // LOAD=5
        axil_write(16'h0000, 32'h1);     // ENABLE=1

        repeat(15) @(posedge aclk);     // 타임아웃 대기

        axil_read(16'hFFFC, rd);
        check_eq("TC4:IRQ_PEND", rd & 32'h1, 32'h1);

        // W1C 클리어
        axil_write(16'hFFFC, 32'h1);
        repeat(2) @(posedge aclk);
        axil_read(16'hFFFC, rd);
        check_eq("TC4:IRQ_PEND_cleared", rd & 32'h1, 32'h0);

        // ────────────────────────────────────────────────
        // TC5: ENABLE=0 → 카운터 정지, TIMEOUT_LAT 없음
        // ────────────────────────────────────────────────
        $display("=== TC5: ENABLE=0 카운터 정지 ===");
        axil_write(16'h0000, 32'h2);     // SRST 클리어
        repeat(3) @(posedge aclk);
        axil_write(16'h0000, 32'h0);     // ENABLE=0
        repeat(2) @(posedge aclk);

        axil_write(16'h0004, 32'd5);     // LOAD=5
        // ENABLE=0 상태 유지

        repeat(20) @(posedge aclk);     // 많이 기다려도

        axil_read(16'h0008, rd);
        check_eq("TC5:TIMEOUT_LAT_disabled", rd & 32'h1, 32'h0);
        check_eq("TC5:RUNNING_disabled",     (rd >> 1) & 32'h1, 32'h0);

        // ────────────────────────────────────────────────
        // 최종 판정
        // ────────────────────────────────────────────────
        if (fail_cnt === 0)
            $display("PASS all 11 checks");
        else
            $display("FAIL %0d check(s) failed", fail_cnt);

        $finish;
    end

    // ── 타임아웃 ─────────────────────────────────────────
    initial begin
        #500000;
        $display("FAIL timeout");
        $finish;
    end

endmodule

`default_nettype wire
