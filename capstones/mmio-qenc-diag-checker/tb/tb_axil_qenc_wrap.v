// tb_axil_qenc_wrap.v — 자체 점검형 테스트벤치
// I-016 엔코더 난이도 사다리 (mmio-qenc-diag-checker, T2)
// Verilog-2001. iverilog 호환.
//
// 통과 → "PASS" 로 시작하는 줄, 실패 → "FAIL" 로 시작하는 줄 출력.
// 비교는 !== 로 X/Z도 실패로 센다.
//
// 테스트 케이스:
//   TC1: 정방향 4스텝 → POSITION == 4, DIR == 0
//   TC2: 역방향 4스텝 → POSITION == 0, DIR == 1
//   TC3: 불가능 전이(글리치 주입) → ERROR_CNT >= 1, ERR_LATCH == 1
//   TC4: 소프트 리셋 → POSITION == 0, ERROR_CNT == 0
//   TC5: 창 속도 (WINDOW_EN=1, 2펄스 → VELOCITY >= 1)
//        테스트용 WINDOW_CYCLES=20으로 짧게 설정

`timescale 1ns/1ps
`default_nettype none

module tb_axil_qenc_wrap;

    // ── 클럭 ──────────────────────────────────────────────
    reg aclk;
    initial aclk = 0;
    always #5 aclk = ~aclk;  // 100 MHz (10 ns 주기)

    // ── DUT 포트 ──────────────────────────────────────────
    reg        aresetn;
    reg  [7:0] s_awaddr;
    reg        s_awvalid;
    wire       s_awready;
    reg  [31:0] s_wdata;
    reg  [3:0]  s_wstrb;
    reg         s_wvalid;
    wire        s_wready;
    wire [1:0]  s_bresp;
    wire        s_bvalid;
    reg         s_bready;
    reg  [7:0]  s_araddr;
    reg         s_arvalid;
    wire        s_arready;
    wire [31:0] s_rdata;
    wire [1:0]  s_rresp;
    wire        s_rvalid;
    reg         s_rready;
    reg         enc_a;
    reg         enc_b;

    // ── DUT 인스턴스 (WINDOW_CYCLES=20 짧게) ─────────────
    axil_qenc_wrap #(
        .WINDOW_CYCLES(20)
    ) dut (
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
        .enc_a     (enc_a),
        .enc_b     (enc_b)
    );

    // ── 실패 카운터 ───────────────────────────────────────
    integer fail_cnt;

    // ── AXI4-Lite 헬퍼 태스크 ────────────────────────────
    task axil_write;
        input [7:0]  addr;
        input [31:0] data;
        begin
            @(posedge aclk); #1;
            s_awaddr = addr; s_awvalid = 1;
            s_wdata  = data; s_wvalid  = 1; s_wstrb = 4'hF;
            // awready 대기
            wait(s_awready); @(posedge aclk); #1;
            s_awvalid = 0;
            // wready 대기
            wait(s_wready);  @(posedge aclk); #1;
            s_wvalid  = 0;
            // bresp 대기
            s_bready = 1;
            wait(s_bvalid);  @(posedge aclk); #1;
            s_bready = 0;
        end
    endtask

    task axil_read;
        input  [7:0]  addr;
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

    // ── 엔코더 정방향 1스텝 (Gray: 00→10→11→01→00 반복) ─
    // 한 스텝 = 1/4 turn. 초기 상태: {A,B}=00
    // 정방향 순서: 00→10→11→01→00
    task enc_fwd_step;
        // 2단 FF 전파를 위해 클럭 3개 이상 대기
        begin
            enc_a = 1; enc_b = 0; repeat(4) @(posedge aclk);
            enc_a = 1; enc_b = 1; repeat(4) @(posedge aclk);
            enc_a = 0; enc_b = 1; repeat(4) @(posedge aclk);
            enc_a = 0; enc_b = 0; repeat(4) @(posedge aclk);
        end
    endtask

    // ── 엔코더 역방향 1스텝 ──────────────────────────────
    // 역방향 순서: 00→01→11→10→00
    task enc_rev_step;
        begin
            enc_a = 0; enc_b = 1; repeat(4) @(posedge aclk);
            enc_a = 1; enc_b = 1; repeat(4) @(posedge aclk);
            enc_a = 1; enc_b = 0; repeat(4) @(posedge aclk);
            enc_a = 0; enc_b = 0; repeat(4) @(posedge aclk);
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

    task check_ge;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  threshold;
        begin
            if (got < threshold) begin
                $display("FAIL %0s: got=%0h < threshold=%0h", name, got, threshold);
                fail_cnt = fail_cnt + 1;
            end else begin
                $display("pass %0s: got=%0h >= %0h", name, got, threshold);
            end
        end
    endtask

    // ── 메인 ─────────────────────────────────────────────
    reg [31:0] rd;
    integer    i;

    initial begin
        // 초기화
        fail_cnt  = 0;
        aresetn   = 0;
        s_awvalid = 0; s_wvalid = 0; s_bready = 0;
        s_arvalid = 0; s_rready = 0;
        s_awaddr  = 0; s_wdata = 0; s_wstrb = 0;
        s_araddr  = 0;
        enc_a = 0; enc_b = 0;

        repeat(5) @(posedge aclk);
        aresetn = 1;
        repeat(2) @(posedge aclk);

        // ── CTRL: EN=1, WINDOW_EN=0 먼저 ────────────────
        axil_write(8'h00, 32'h1);  // EN=1

        // ────────────────────────────────────────────────
        // TC1: 정방향 4스텝 → POSITION == 4, DIR == 0
        // ────────────────────────────────────────────────
        $display("=== TC1: 정방향 4스텝 ===");
        for (i = 0; i < 4; i = i + 1)
            enc_fwd_step;
        repeat(5) @(posedge aclk);

        axil_read(8'h04, rd); check_eq("TC1:POSITION", rd, 32'd4);
        axil_read(8'h0C, rd); check_eq("TC1:DIR",      rd & 32'h1, 32'h0);

        // ────────────────────────────────────────────────
        // TC2: 역방향 4스텝 → POSITION == 0, DIR == 1
        // ────────────────────────────────────────────────
        $display("=== TC2: 역방향 4스텝 ===");
        for (i = 0; i < 4; i = i + 1)
            enc_rev_step;
        repeat(5) @(posedge aclk);

        axil_read(8'h04, rd); check_eq("TC2:POSITION", rd, 32'd0);
        axil_read(8'h0C, rd); check_eq("TC2:DIR",      rd & 32'h1, 32'h1);

        // ────────────────────────────────────────────────
        // TC3: 글리치 주입 (불가능 전이 00→11)
        // ────────────────────────────────────────────────
        $display("=== TC3: 글리치 주입 ===");
        enc_a = 0; enc_b = 0; repeat(4) @(posedge aclk);
        enc_a = 1; enc_b = 1; repeat(4) @(posedge aclk);  // 00→11: 불가능
        enc_a = 0; enc_b = 0; repeat(4) @(posedge aclk);  // 11→00: 불가능
        repeat(5) @(posedge aclk);

        axil_read(8'h10, rd); check_ge("TC3:ERROR_CNT",  rd, 32'd1);
        axil_read(8'h0C, rd); check_eq("TC3:ERR_LATCH",  (rd >> 2) & 1, 32'h1);

        // ────────────────────────────────────────────────
        // TC4: 소프트 리셋 → POSITION==0, ERROR_CNT==0
        // ────────────────────────────────────────────────
        $display("=== TC4: 소프트 리셋 ===");
        // CTRL: EN=1, SRST=1
        axil_write(8'h00, 32'h3);
        repeat(3) @(posedge aclk);
        // SRST 해제
        axil_write(8'h00, 32'h1);
        repeat(3) @(posedge aclk);

        axil_read(8'h04, rd); check_eq("TC4:POSITION",  rd, 32'd0);
        axil_read(8'h10, rd); check_eq("TC4:ERROR_CNT", rd, 32'd0);

        // ────────────────────────────────────────────────
        // TC5: 창 속도 (WINDOW_EN=1, 2펄스 발생, 창 완료 후 VELOCITY>=1)
        // ────────────────────────────────────────────────
        $display("=== TC5: 창 속도 ===");
        axil_write(8'h00, 32'h5);  // EN=1, WINDOW_EN=1
        repeat(3) @(posedge aclk);
        enc_fwd_step;
        enc_fwd_step;
        // WINDOW_CYCLES=20이므로 창 완료를 기다린다
        repeat(60) @(posedge aclk);
        axil_read(8'h08, rd); check_ge("TC5:VELOCITY", rd & 32'hFFFF, 32'd1);

        // ────────────────────────────────────────────────
        // 최종 판정
        // ────────────────────────────────────────────────
        if (fail_cnt === 0)
            $display("PASS all %0d checks", 7);
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
