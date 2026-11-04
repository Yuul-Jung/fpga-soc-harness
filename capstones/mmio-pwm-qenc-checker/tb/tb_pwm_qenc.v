// tb_pwm_qenc.v — PASS/FAIL 자체 점검형 테스트벤치
// 테스트 항목:
//   CHECK1: PWM PERIOD=100, DUTY0=25 → pwm0 HIGH 사이클 == 25
//   CHECK2: DUTY1=75              → pwm1 HIGH 사이클 == 75
//   CHECK3: CW 4 에지 주입       → POS 레지스터 == 4
//   CHECK4: CCW 3 에지 추가 주입 → POS 레지스터 == 1
// 최종: PASS 또는 FAIL로 시작하는 줄 출력 후 $finish
`timescale 1ns/1ps
module tb_pwm_qenc;
    // 클럭 (10 ns = 100 MHz)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    reg rst;

    // 마스터 버스 신호
    reg         m_valid;
    reg         m_we;
    reg  [31:0] m_addr;
    reg  [31:0] m_wdata;
    wire [31:0] m_rdata;
    wire        m_ready;

    // GPIO
    reg  [15:0] sw;
    wire [15:0] led;

    // UART
    wire txd;

    // PWM 출력 관찰
    wire pwm0, pwm1, pwm_irq;

    // 직교 엔코더 입력
    reg  enc_a, enc_b;
    wire qdec_irq;

    // DUT
    soc_top dut (
        .clk      (clk),
        .rst      (rst),
        .m_valid  (m_valid),
        .m_we     (m_we),
        .m_addr   (m_addr),
        .m_wdata  (m_wdata),
        .m_rdata  (m_rdata),
        .m_ready  (m_ready),
        .sw       (sw),
        .led      (led),
        .txd      (txd),
        .pwm0     (pwm0),
        .pwm1     (pwm1),
        .pwm_irq  (pwm_irq),
        .enc_a    (enc_a),
        .enc_b    (enc_b),
        .qdec_irq (qdec_irq)
    );

    // 오류 카운터
    integer fail_cnt;
    integer i;

    // 측정 카운터
    integer ch0_hi_cnt;
    integer ch1_hi_cnt;

    // MMIO 쓰기 태스크
    task mmio_write;
        input [31:0] a;
        input [31:0] d;
        begin
            @(posedge clk);
            m_valid <= 1'b1;
            m_we    <= 1'b1;
            m_addr  <= a;
            m_wdata <= d;
            @(posedge clk);
            // ready는 항상 1이므로 1사이클
            m_valid <= 1'b0;
            m_we    <= 1'b0;
        end
    endtask

    // MMIO 읽기 태스크
    task mmio_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge clk);
            m_valid <= 1'b1;
            m_we    <= 1'b0;
            m_addr  <= a;
            @(posedge clk);
            d       = m_rdata;
            m_valid <= 1'b0;
        end
    endtask

    reg [31:0] rd_val;

    // CW 직교 시퀀스: 00→01→11→10→00
    task inject_cw_edge;
        input [1:0] next_ab;
        begin
            enc_a <= next_ab[1];
            enc_b <= next_ab[0];
            repeat(4) @(posedge clk); // 2단 동기화 + 여유
        end
    endtask

    initial begin
        // 초기화
        rst     = 1'b1;
        m_valid = 1'b0;
        m_we    = 1'b0;
        m_addr  = 32'd0;
        m_wdata = 32'd0;
        sw      = 16'd0;
        enc_a   = 1'b0;
        enc_b   = 1'b0;
        fail_cnt = 0;

        repeat(4) @(posedge clk);
        rst = 1'b0;
        repeat(2) @(posedge clk);

        // ── CHECK1: pwm0 HIGH 사이클 == 25 ──────────────────────────────
        $display("CHECK1: PWM DUTY0=25%% (period=100)");
        // PWM 설정
        mmio_write(32'h1003_0004, 32'd100);  // PERIOD = 100
        mmio_write(32'h1003_0008, 32'd25);   // DUTY0 = 25
        mmio_write(32'h1003_000C, 32'd75);   // DUTY1 = 75 (CHECK2용으로 미리 설정)
        mmio_write(32'h1003_0000, 32'd1);    // enable = 1

        // 첫 period_end IRQ 대기 후 카운팅 시작 (IRQ_ENABLE은 0이므로 IRQ_STATUS 폴링)
        // 먼저 현재 카운터가 한 번 돌 때까지 최대 150사이클 대기
        // (enable 직후 cnt=0에서 시작하므로 ~100사이클이면 충분)
        begin : blk_check1
            integer wait_lim;
            wait_lim = 0;
            while (wait_lim < 150) begin
                @(posedge clk);
                wait_lim = wait_lim + 1;
            end
        end

        // 정확히 1 period (100사이클) 동안 pwm0 HIGH 카운트
        ch0_hi_cnt = 0;
        repeat(100) begin
            @(posedge clk);
            if (pwm0 === 1'b1) ch0_hi_cnt = ch0_hi_cnt + 1;
        end

        if (ch0_hi_cnt !== 25) begin
            $display("FAIL CHECK1: pwm0 HIGH=%0d expected 25", ch0_hi_cnt);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("  PASS CHECK1: pwm0 HIGH=%0d", ch0_hi_cnt);
        end

        // ── CHECK2: pwm1 HIGH 사이클 == 75 ──────────────────────────────
        $display("CHECK2: PWM DUTY1=75%% (period=100)");
        // DUTY1=75은 이미 설정됨. 1 period 동안 ch1 HIGH 카운트
        ch1_hi_cnt = 0;
        repeat(100) begin
            @(posedge clk);
            if (pwm1 === 1'b1) ch1_hi_cnt = ch1_hi_cnt + 1;
        end

        if (ch1_hi_cnt !== 75) begin
            $display("FAIL CHECK2: pwm1 HIGH=%0d expected 75", ch1_hi_cnt);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("  PASS CHECK2: pwm1 HIGH=%0d", ch1_hi_cnt);
        end

        // ── CHECK3: CW 4 에지 → POS == 4 ───────────────────────────────
        $display("CHECK3: QDEC CW 4 edges → POS==4");
        // QDEC 활성화 & 초기화 (enable=1, clear=1)
        mmio_write(32'h1004_0000, 32'h0000_0003);
        @(posedge clk); // clear 적용
        // clear 비트 해제 (enable만 유지)
        mmio_write(32'h1004_0000, 32'h0000_0001);

        // 초기 상태: enc_a=0, enc_b=0 (2'b00)
        enc_a = 1'b0; enc_b = 1'b0;
        repeat(4) @(posedge clk);

        // CW 4 에지: 00→01→11→10→00
        inject_cw_edge(2'b01); // step 1
        inject_cw_edge(2'b11); // step 2
        inject_cw_edge(2'b10); // step 3
        inject_cw_edge(2'b00); // step 4

        // 동기화 여유 사이클 추가
        repeat(6) @(posedge clk);

        mmio_read(32'h1004_0004, rd_val); // POS 읽기
        if (rd_val !== 32'd4) begin
            $display("FAIL CHECK3: POS=%0d expected 4", rd_val);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("  PASS CHECK3: POS=%0d", rd_val);
        end

        // ── CHECK4: CCW 3 에지 → POS == 1 ──────────────────────────────
        $display("CHECK4: QDEC CCW 3 edges → POS==1 (was 4)");
        // 현재 enc_a=0, enc_b=0 (2'b00에서 시작)
        // CCW 순서: 00→10→11→01
        enc_a = 1'b1; enc_b = 1'b0; repeat(4) @(posedge clk); // 00→10
        enc_a = 1'b1; enc_b = 1'b1; repeat(4) @(posedge clk); // 10→11
        enc_a = 1'b0; enc_b = 1'b1; repeat(4) @(posedge clk); // 11→01
        repeat(6) @(posedge clk);

        mmio_read(32'h1004_0004, rd_val); // POS 읽기
        if (rd_val !== 32'd1) begin
            $display("FAIL CHECK4: POS=%0d expected 1", rd_val);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("  PASS CHECK4: POS=%0d", rd_val);
        end

        // ── 최종 결과 출력 ───────────────────────────────────────────────
        @(posedge clk);
        if (fail_cnt === 0)
            $display("PASS all checks (4/4)");
        else
            $display("FAIL %0d check(s) failed", fail_cnt);

        $finish;
    end

    // 타임아웃 (5000사이클)
    initial begin
        #50000;
        $display("FAIL timeout");
        $finish;
    end
endmodule
