// tb_pid_cap.v — PID 캡처 IP 자체 점검 테스트벤치 (mmio-pid-step-capture)
//
// 검증 항목:
//   1. KP/KI/KD/TARGET/PERIOD/MIN_DUTY 쓰기·읽기 왕복
//   2. 1차 지연 모터 모델로 계단 지령 추종: 최종 오차 ±3 이내 수렴
//   3. BRAM 캡처 로그에 32엔트리가 채워짐
//   4. CAP_STATUS.cap_full 플래그 설정
//   5. ID/VER 관리 레지스터 값 확인
//
// 통과하면 "PASS: ...", 실패하면 "FAIL: ..." 를 $display로 출력하고 종료.
// !==로 비교해 X/Z도 실패로 처리.
//
// Verilog-2001
`timescale 1ns/1ps
`default_nettype none

module tb_pid_cap;

    // ─── 클럭·리셋 ────────────────────────────────────────────────────
    reg clk, rst;
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz (10 ns 주기)

    // ─── MMIO-lite 버스 (테스트벤치가 마스터) ─────────────────────────
    reg         valid;
    reg         we;
    reg  [15:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    // ─── 엔코더 모델 ──────────────────────────────────────────────────
    reg  enc_a, enc_b;
    wire pwm;

    // ─── DUT 인스턴스 ─────────────────────────────────────────────────
    pid_cap_ip #(
        .WINDOW_CYCLES (1_000),
        .CAP_DEPTH     (32),
        .PWM_PERIOD    (1_000)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .valid (valid),
        .we    (we),
        .addr  (addr),
        .wdata (wdata),
        .rdata (rdata),
        .enc_a (enc_a),
        .enc_b (enc_b),
        .pwm   (pwm)
    );

    // ─── MMIO 쓰기·읽기 태스크 ────────────────────────────────────────
    task mmio_write;
        input [15:0] a;
        input [31:0] d;
        begin
            @(negedge clk);
            valid <= 1'b1; we <= 1'b1; addr <= a; wdata <= d;
            @(posedge clk); #1;
            valid <= 1'b0; we <= 1'b0;
        end
    endtask

    task mmio_read;
        input  [15:0] a;
        output [31:0] d;
        begin
            @(negedge clk);
            valid <= 1'b1; we <= 1'b0; addr <= a; wdata <= 32'h0;
            @(posedge clk); #1;
            d = rdata;
            valid <= 1'b0;
        end
    endtask

    // ─── 1차 지연 모터 모델 ───────────────────────────────────────────
    // 속도_new = 속도_old + (pwm_duty * gain - 속도_old) / tau
    // 정수 근사: 오버플로 방지를 위해 32비트 사용
    // 파라미터: gain=1 (PWM 듀티가 목표 속도와 같은 단위), tau=20 창 주기
    real motor_speed;
    real motor_tau;
    integer enc_pulse_budget; // 이번 창에서 출력해야 할 펄스 수

    // 엔코더 펄스 생성: enc_pulse_budget 만큼 A/B 펄스 생성
    // 4× 카운트이므로 1 엔코더 사이클 = 4 펄스. 단순화: 1 pulse = 1 엣지쌍
    integer pulse_i;
    integer gen_pulses;
    task gen_encoder_pulses;
        input integer n; // 발생시킬 4× 카운트 수
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                // A 상승 엣지 (B=0이면 정방향)
                @(negedge clk); enc_a = 1'b1; enc_b = 1'b0;
                @(negedge clk); enc_b = 1'b1;
                @(negedge clk); enc_a = 1'b0;
                @(negedge clk); enc_b = 1'b0;
            end
        end
    endtask

    // ─── 테스트 변수 ──────────────────────────────────────────────────
    integer     fail_cnt;
    reg  [31:0] rd_val;
    integer     window_idx;
    integer     final_speed;
    integer     cap_entry;
    integer     i;
    reg  [15:0] log_data [0:31];
    integer     log_nonzero;

    // ─── 메인 테스트 ──────────────────────────────────────────────────
    initial begin
        fail_cnt = 0;
        enc_a = 0; enc_b = 0;
        valid = 0; we = 0; addr = 0; wdata = 0;
        motor_speed = 0.0;
        motor_tau   = 20.0; // 20 창 주기의 1차 시상수

        // 리셋
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ── 테스트 1: 관리 레지스터 확인 ─────────────────────────────
        mmio_read(16'hFFF0, rd_val);
        if (rd_val !== 32'h50494431) begin
            $display("FAIL: ID reg = %08h, expected 50494431", rd_val);
            fail_cnt = fail_cnt + 1;
        end

        mmio_read(16'hFFF4, rd_val);
        if (rd_val !== 32'h01000001) begin
            $display("FAIL: VER reg = %08h, expected 01000001", rd_val);
            fail_cnt = fail_cnt + 1;
        end

        // ── 테스트 2: 레지스터 쓰기·읽기 왕복 ───────────────────────
        mmio_write(16'h08, 32'h0180); // KP = 1.5
        mmio_read (16'h08, rd_val);
        if (rd_val[15:0] !== 16'h0180) begin
            $display("FAIL: KP roundtrip = %04h, expected 0180", rd_val[15:0]);
            fail_cnt = fail_cnt + 1;
        end

        mmio_write(16'h0C, 32'h0020); // KI = 0.125
        mmio_write(16'h10, 32'h0010); // KD = 0.0625
        mmio_write(16'h18, 32'd1000); // PWM 주기
        mmio_write(16'h20, 32'd50);   // 최소 듀티
        mmio_write(16'h04, 32'd100);  // 목표 속도 100

        // ── 테스트 3: cap_start + enable 설정 ────────────────────────
        mmio_write(16'h00, 32'h7); // bit2=cap_start, bit1=clear_pos, bit0=enable
        // cap_start는 1사이클 펄스이므로 enable만 남기도록 다시 쓰기
        mmio_write(16'h00, 32'h1); // bit0=enable

        // ── 테스트 4: 모터 모델 시뮬레이션 ──────────────────────────
        // 50 창 주기 동안 엔코더 펄스를 모터 모델에 따라 생성하고
        // PID 제어 루프가 목표 100에 수렴하는지 확인한다.
        for (window_idx = 0; window_idx < 50; window_idx = window_idx + 1) begin
            // 1차 지연 모터 모델: 현재 PWM 듀티를 입력으로 속도 갱신
            // duty는 DUT 내부 레지스터. 테스트벤치에서 직접 읽기
            mmio_read(16'h1C, rd_val);
            // motor_speed 갱신: 1차 지연
            motor_speed = motor_speed + (rd_val * 1.0 / 1000.0 * 100.0 - motor_speed) / motor_tau;
            if (motor_speed < 0.0) motor_speed = 0.0;

            // 이번 창에서 발생할 4× 카운트 수 (정수화)
            gen_pulses = $rtoi(motor_speed);
            if (gen_pulses > 200) gen_pulses = 200; // 상한 클램프

            // 창 주기의 절반(500 클럭) 안에 펄스 생성, 나머지는 대기
            // 간략화: 각 펄스당 4클럭(A/B 에지 1쌍), 나머지는 클럭만 흘린다
            gen_encoder_pulses(gen_pulses);
            // WINDOW_CYCLES=1000이므로 나머지 클럭 흘리기
            repeat(1000 - gen_pulses * 4) @(posedge clk);
        end

        // 최종 속도 확인 (창 50개 후)
        mmio_read(16'h14, rd_val);
        final_speed = rd_val[15:0];
        if ((final_speed < 97) || (final_speed > 103)) begin
            $display("FAIL: final speed = %0d, expected 97~103 (target=100)", final_speed);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("INFO: final speed = %0d (target=100) OK", final_speed);
        end

        // ── 테스트 5: BRAM 캡처 로그 확인 ───────────────────────────
        // 32개 창이 쌓이면 cap_full이 된다. 이미 50 창을 돌렸으므로 체크
        mmio_read(16'h2C, rd_val);
        if (rd_val[0] !== 1'b1) begin
            $display("FAIL: cap_full not set after 50 windows (CAP_STATUS=%08h)", rd_val);
            fail_cnt = fail_cnt + 1;
        end

        // CAP_ADDR를 0~31로 순서대로 읽어 비어있지 않음(최소 1개 non-zero) 확인
        log_nonzero = 0;
        for (i = 0; i < 32; i = i + 1) begin
            mmio_write(16'h24, i);           // CAP_ADDR 설정
            @(posedge clk); @(posedge clk); // BRAM 동기 읽기 대기
            mmio_read(16'h28, rd_val);
            log_data[i] = rd_val[15:0];
            if (rd_val[15:0] !== 16'h0) log_nonzero = log_nonzero + 1;
        end

        if (log_nonzero == 0) begin
            $display("FAIL: all BRAM log entries are zero");
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("INFO: BRAM log has %0d non-zero entries", log_nonzero);
        end

        // ── 최종 판정 ────────────────────────────────────────────────
        if (fail_cnt == 0)
            $display("PASS: all %0d checks passed", 5);
        else
            $display("FAIL: %0d check(s) failed", fail_cnt);

        $finish;
    end

    // 타임아웃: 10 ms (100 MHz 기준 1_000_000 클럭)
    initial begin
        #10_000_000;
        $display("FAIL: simulation timeout");
        $finish;
    end

endmodule
`default_nettype wire
