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
//   TC3: 불가능 전이(글리치 주입 00→11) → ERROR_CNT >= 1, ERR_LATCH == 1
//   TC4: 소프트 리셋 → POSITION == 0, ERROR_CNT == 0
//   TC5: 창 속도 (WINDOW_EN=1, 2펄스 → VELOCITY >= 1)
//        테스트용 WINDOW_CYCLES=100으로 설정
//
// 설계 메모:
//   enc_fwd_step / enc_rev_step = 1전이(1카운트). Gray 위상을 enc_state로 추적.
//   4번 호출 = 1 기계 사이클 (00→10→11→01→00).
//   2단 FF 전파를 위해 상태마다 클럭 4개를 대기.
//
//   TC5 타이밍 (WINDOW_CYCLES=100):
//     1) WINDOW_EN 쓰기 후 105클럭 대기 → 첫 창 완료, 새 창 시작 보장
//     2) enc_fwd_step × 2 (8클럭, << 100클럭 창)
//     3) 105클럭 대기 → 해당 창 완료 → VELOCITY = 2

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

    // ── 엔코더 위상 추적 (enc_fwd_step / enc_rev_step 공유) ─
    // {enc_a, enc_b}의 현재 Gray 위상
    reg [1:0] enc_state;

    // ── DUT 인스턴스 (WINDOW_CYCLES=100 짧게) ────────────
    axil_qenc_wrap #(
        .WINDOW_CYCLES(100)
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

    // ── 엔코더 정방향 1전이 ──────────────────────────────
    // Gray 정방향: 00→10→11→01→00. 한 번 호출 = 카운트 +1.
    // 4번 호출하면 1 기계 사이클 완성 (enc_state가 00으로 복귀).
    // 2단 FF 전파를 위해 클럭 4개 대기.
    task enc_fwd_step;
        begin
            case (enc_state)
                2'b00: enc_state = 2'b10;
                2'b10: enc_state = 2'b11;
                2'b11: enc_state = 2'b01;
                2'b01: enc_state = 2'b00;
            endcase
            enc_a = enc_state[1];
            enc_b = enc_state[0];
            repeat(4) @(posedge aclk);
        end
    endtask

    // ── 엔코더 역방향 1전이 ──────────────────────────────
    // Gray 역방향: 00→01→11→10→00. 한 번 호출 = 카운트 -1.
    task enc_rev_step;
        begin
            case (enc_state)
                2'b00: enc_state = 2'b01;
                2'b01: enc_state = 2'b11;
                2'b11: enc_state = 2'b10;
                2'b10: enc_state = 2'b00;
            endcase
            enc_a = enc_state[1];
            enc_b = enc_state[0];
            repeat(4) @(posedge aclk);
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
                if (got < threshold) begin
                    $display("FAIL %0s: got=%0h < threshold=%0h", name, got, threshold);
                    fail_cnt = fail_cnt + 1;
                end else begin
                    $display("pass %0s: got=%0h >= %0h", name, got, threshold);
                end
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
        enc_state = 2'b00;
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
        // 각 enc_fwd_step = 1전이 = 카운트 +1
        // 4회 호출: 00→10→11→01→00, POSITION = 4
        // ────────────────────────────────────────────────
        $display("=== TC1: 정방향 4스텝 ===");
        for (i = 0; i < 4; i = i + 1)
            enc_fwd_step;
        repeat(5) @(posedge aclk);

        axil_read(8'h04, rd); check_eq("TC1:POSITION", rd, 32'd4);
        axil_read(8'h0C, rd); check_eq("TC1:DIR",      rd & 32'h1, 32'h0);

        // ────────────────────────────────────────────────
        // TC2: 역방향 4스텝 → POSITION == 0, DIR == 1
        // TC1 종료 후 enc_state=00. 역방향 4전이로 복귀.
        // ────────────────────────────────────────────────
        $display("=== TC2: 역방향 4스텝 ===");
        for (i = 0; i < 4; i = i + 1)
            enc_rev_step;
        repeat(5) @(posedge aclk);

        axil_read(8'h04, rd); check_eq("TC2:POSITION", rd, 32'd0);
        axil_read(8'h0C, rd); check_eq("TC2:DIR",      rd & 32'h1, 32'h1);

        // ────────────────────────────────────────────────
        // TC3: 글리치 주입 (불가능 전이 00→11)
        // TC2 종료 후 enc_state=00. 직접 신호 조작.
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
        //
        // WINDOW_CYCLES=100 타이밍:
        //   1) WINDOW_EN 쓰기 후 105클럭 대기 → 첫 창 완료, 새 창 시작 보장
        //   2) enc_fwd_step × 2 (8클럭, << 100클럭 창)
        //   3) 105클럭 대기 → 해당 창 완료 → VELOCITY = 2 (안전 여유 92클럭)
        // ────────────────────────────────────────────────
        $display("=== TC5: 창 속도 ===");
        axil_write(8'h00, 32'h5);  // EN=1, WINDOW_EN=1
        // 창 경계 동기화: 첫 창이 완료되고 새 창이 시작될 때까지 기다린다
        repeat(105) @(posedge aclk);
        // 새 창 안에 2펄스를 넣는다 (8클럭 << 100클럭 창)
        enc_fwd_step;
        enc_fwd_step;
        // 이 창이 완료될 때까지 기다린다
        repeat(105) @(posedge aclk);
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
