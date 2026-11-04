// tb_multi_axis_motion.v — multi_axis_motion_ip 자체 점검 테스트벤치
//
// 테스트 항목:
//   TC1: ID 레지스터 = 0x4D435431 ("MCT1")
//   TC2: 리셋 직후 PWM=0, 활성화 전 PWM=0
//   TC3: setpoint=0, enable → 1주기 후 PWM=0 (에러 없음)
//   TC4: setpoint>0, Kp>0 → 1주기 후 PWM>0 (비례 출력)
//   TC5: 긴급정지(emstop) → PWM=0 즉시
//   TC6: IRQ period_tick 발생 확인 (짧은 주기로)
//   TC7: 채널 A·B 독립 setpoint → 각 채널 별도 출력
//
// 비교: !== 사용 (X/Z도 실패로 센다)

`timescale 1ns/1ps
`default_nettype none

module tb_multi_axis_motion;

    // ---- 클럭 / 리셋 -------------------------------------------------------
    reg clk, rst;
    localparam CLK_PERIOD = 10;  // 10ns = 100MHz
    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end
    initial begin rst = 1; #(CLK_PERIOD*5); rst = 0; end

    // ---- DUT ---------------------------------------------------------------
    reg         valid, we;
    reg  [31:0] addr, wdata;
    wire [31:0] rdata;
    reg         enc_a_a, enc_a_b;
    reg         enc_b_a, enc_b_b;
    wire        pwm_a_o, pwm_a_dir;
    wire        pwm_b_o, pwm_b_dir;
    wire        irq_o;

    multi_axis_motion_ip dut (
        .clk        (clk),
        .rst        (rst),
        .valid      (valid),
        .we         (we),
        .addr       (addr),
        .wdata      (wdata),
        .rdata      (rdata),
        .enc_a_a    (enc_a_a),
        .enc_a_b    (enc_a_b),
        .enc_b_a    (enc_b_a),
        .enc_b_b    (enc_b_b),
        .pwm_a_o    (pwm_a_o),
        .pwm_a_dir  (pwm_a_dir),
        .pwm_b_o    (pwm_b_o),
        .pwm_b_dir  (pwm_b_dir),
        .irq_o      (irq_o)
    );

    // ---- 헬퍼 태스크 -------------------------------------------------------
    integer fail_cnt;
    integer tc_num;

    localparam B = 32'h4017_0000;

    task mmio_write;
        input [31:0] a;
        input [31:0] d;
        begin
            @(posedge clk); #1;
            valid = 1; we = 1; addr = a; wdata = d;
            @(posedge clk); #1;
            valid = 0; we = 0;
        end
    endtask

    task mmio_read;
        input  [31:0] a;
        output [31:0] d;
        begin
            @(posedge clk); #1;
            valid = 1; we = 0; addr = a;
            @(posedge clk); #1;
            d = rdata;
            valid = 0;
        end
    endtask

    task check_eq;
        input [63:0] got;
        input [63:0] exp;
        input [127:0] msg;
        begin
            if (got !== exp) begin
                $display("  FAIL TC%0d [%s]: got=%0h exp=%0h", tc_num, msg, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_gt;
        input [63:0] got;
        input [63:0] threshold;
        input [127:0] msg;
        begin
            if (got <= threshold) begin
                $display("  FAIL TC%0d [%s]: got=%0d, expected >%0d", tc_num, msg, got, threshold);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // 짧은 테스트용 주기 (100클럭 = 1μs@100MHz)
    localparam TEST_PERIOD = 20'd100;

    reg  [31:0] rd;
    integer i;

    // ---- 메인 테스트 -------------------------------------------------------
    initial begin
        fail_cnt = 0;
        valid = 0; we = 0; addr = 0; wdata = 0;
        enc_a_a = 0; enc_a_b = 0;
        enc_b_a = 0; enc_b_b = 0;

        @(negedge rst);
        repeat(3) @(posedge clk);

        // -----------------------------------------------------------------
        // TC1: ID 레지스터
        // -----------------------------------------------------------------
        tc_num = 1;
        mmio_read(B + 32'hFFF0, rd);
        check_eq(rd, 32'h4D435431, "TC1:ID=MCT1");
        mmio_read(B + 32'hFFF4, rd);
        check_eq(rd, 32'h01000001, "TC1:VER");

        // -----------------------------------------------------------------
        // TC2: 리셋 직후 PWM 출력 = 0
        // -----------------------------------------------------------------
        tc_num = 2;
        @(posedge clk); #1;
        check_eq(pwm_a_o, 1'b0, "TC2:pwm_a_rst=0");
        check_eq(pwm_b_o, 1'b0, "TC2:pwm_b_rst=0");

        // 활성화 전 (enable=0) PWM = 0
        mmio_write(B + 32'h0004, {12'd0, TEST_PERIOD});  // PERIOD=100클럭
        mmio_write(B + 32'h0010, 32'd50);                 // CA_SETPT=50
        mmio_write(B + 32'h0014, 32'd1024);               // CA_KP = 1.0 (Q4.12)
        repeat(TEST_PERIOD + 10) @(posedge clk); #1;
        // enable=0이므로 PWM은 게이트되어 0
        check_eq(pwm_a_o, 1'b0, "TC2:pwm_a_no_enable=0");

        // -----------------------------------------------------------------
        // TC3: setpoint=0, enable → 1주기 후 PWM=0 (에러 없음)
        // -----------------------------------------------------------------
        tc_num = 3;
        mmio_write(B + 32'h0010, 32'd0);       // CA_SETPT=0
        mmio_write(B + 32'h0030, 32'd0);       // CB_SETPT=0
        mmio_write(B + 32'h0014, 32'd1024);    // CA_KP=1.0
        mmio_write(B + 32'h0018, 32'd0);       // CA_KI=0
        mmio_write(B + 32'h0034, 32'd1024);    // CB_KP=1.0
        mmio_write(B + 32'h0038, 32'd0);       // CB_KI=0
        mmio_write(B + 32'h0000, 32'h1);       // enable=1

        // 2주기 대기 (에러=0 → PWM=0)
        repeat(TEST_PERIOD * 3) @(posedge clk); #1;
        mmio_read(B + 32'h0020, rd);
        check_eq(rd[9:0], 10'd0, "TC3:ca_pwm=0_when_sp=0");
        mmio_read(B + 32'h0040, rd);
        check_eq(rd[9:0], 10'd0, "TC3:cb_pwm=0_when_sp=0");

        // -----------------------------------------------------------------
        // TC4: setpoint>0, Kp>0 → 1주기 후 PWM>0
        // -----------------------------------------------------------------
        tc_num = 4;
        // iterm 클리어
        mmio_write(B + 32'h0024, 32'd0);    // CA_ITERM=0
        mmio_write(B + 32'h0044, 32'd0);    // CB_ITERM=0
        mmio_write(B + 32'h0010, 32'd20);   // CA_SETPT=20 카운트/주기
        mmio_write(B + 32'h0014, 32'd4096); // CA_KP=1.0 (Q4.12: 4096>>12=1.0)
        // 엔코더 입력 없음(cnt_lat=0) → error=20 → P=20*1.0=20

        repeat(TEST_PERIOD * 2 + 5) @(posedge clk); #1;
        mmio_read(B + 32'h0020, rd);
        check_gt(rd[9:0], 10'd0, "TC4:ca_pwm>0_when_sp=20");

        // -----------------------------------------------------------------
        // TC5: 긴급정지(emstop) → PWM 즉시 0
        // -----------------------------------------------------------------
        tc_num = 5;
        // 현재 CA_PWM > 0 상태에서 emstop 설정
        mmio_write(B + 32'h0000, 32'h3);  // enable=1, emstop=1
        @(posedge clk); #1;
        // 게이트 즉시 차단 (combinational)
        check_eq(pwm_a_o, 1'b0, "TC5:pwm_a_emstop=0");
        check_eq(pwm_b_o, 1'b0, "TC5:pwm_b_emstop=0");
        // 레지스터 읽기도 0
        mmio_read(B + 32'h0020, rd);
        // ca_duty_r 자체는 아직 남아있지만 출력은 0
        // emstop 해제
        mmio_write(B + 32'h0000, 32'h1);  // emstop 해제

        // -----------------------------------------------------------------
        // TC6: IRQ period_tick 발생
        // -----------------------------------------------------------------
        tc_num = 6;
        // IRQ_ENABLE 활성화
        mmio_write(B + 32'hFFFC, 32'h1);
        // IRQ_STATUS 클리어
        mmio_write(B + 32'hFFF8, 32'h1);
        // 1주기 대기
        repeat(TEST_PERIOD + 5) @(posedge clk); #1;
        // irq_o 확인
        check_eq(irq_o, 1'b1, "TC6:irq_fires");
        // IRQ_STATUS 클리어
        mmio_write(B + 32'hFFF8, 32'h1);
        mmio_read(B + 32'hFFF8, rd);
        check_eq(rd[0], 1'b0, "TC6:irq_status_cleared");

        // -----------------------------------------------------------------
        // TC7: 채널 A·B 독립 — 채널B setpoint=0이면 pwm_b=0
        // -----------------------------------------------------------------
        tc_num = 7;
        mmio_write(B + 32'h0024, 32'd0);    // CA_ITERM 클리어
        mmio_write(B + 32'h0044, 32'd0);    // CB_ITERM 클리어
        mmio_write(B + 32'h0010, 32'd30);   // CA_SETPT=30
        mmio_write(B + 32'h0030, 32'd0);    // CB_SETPT=0
        mmio_write(B + 32'h0014, 32'd4096); // CA_KP=1.0
        mmio_write(B + 32'h0034, 32'd4096); // CB_KP=1.0
        mmio_write(B + 32'h0000, 32'h1);    // enable=1

        repeat(TEST_PERIOD * 2 + 5) @(posedge clk); #1;
        mmio_read(B + 32'h0020, rd);
        check_gt(rd[9:0], 10'd0, "TC7:ca_pwm>0");
        mmio_read(B + 32'h0040, rd);
        check_eq(rd[9:0], 10'd0, "TC7:cb_pwm=0_when_sp=0");

        // -----------------------------------------------------------------
        // 최종 결과
        // -----------------------------------------------------------------
        if (fail_cnt == 0) begin
            $display("PASS: multi_axis_motion_ip 모든 항목(%0d개) 통과", 7);
        end else begin
            $display("FAIL: %0d개 항목 실패", fail_cnt);
        end
        $finish;
    end

    // 타임아웃 (50 µs — 7개 TC × 최대 300클럭 × 10ns + 여유)
    initial begin
        #50000;
        $display("FAIL: 시뮬레이션 타임아웃");
        $finish;
    end

endmodule

`default_nettype wire
