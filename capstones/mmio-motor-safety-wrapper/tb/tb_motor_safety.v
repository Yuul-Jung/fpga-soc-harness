// tb_motor_safety.v — motor_safety_ip PASS/FAIL 자체 점검 테스트벤치
//
// 테스트 항목:
//   TC1: ID 레지스터 = 0x4D535731 ("MSW1")
//   TC2: 슛스루 차단 — AH_in & AL_in 동시=1 → 둘 다 출력=0
//   TC3: 데드타임 — AH_in 하강 후 AL_in 상승 시, AL_out은 dt_cycles 경과 후 등장
//   TC4: 과전류 래치 — oc_fault_i 상승 → 모든 출력=0, STATUS.oc_latched=1
//   TC5: 과전류 해제 — CTRL.oc_clear → oc_latched=0, 출력 복귀
//   TC6: dt_bypass — bypass=1 시 슛스루 차단 없이 그대로 출력
//
// 비교: !== 사용 (X/Z도 실패로 센다)

`timescale 1ns/1ps
`default_nettype none

module tb_motor_safety;

    // ---- 클럭 / 리셋 -------------------------------------------------------
    reg clk, rst;

    localparam CLK_PERIOD = 10; // 10 ns = 100 MHz
    initial begin clk = 0; forever #(CLK_PERIOD/2) clk = ~clk; end
    initial begin rst = 1; #(CLK_PERIOD*5); rst = 0; end

    // ---- DUT ---------------------------------------------------------------
    reg         valid;
    reg         we;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;
    reg         oc_fault;
    wire        pwm_ah, pwm_al, pwm_bh, pwm_bl;
    wire        irq_o;

    motor_safety_ip dut (
        .clk        (clk),
        .rst        (rst),
        .valid      (valid),
        .we         (we),
        .addr       (addr),
        .wdata      (wdata),
        .rdata      (rdata),
        .oc_fault_i (oc_fault),
        .pwm_ah_o   (pwm_ah),
        .pwm_al_o   (pwm_al),
        .pwm_bh_o   (pwm_bh),
        .pwm_bl_o   (pwm_bl),
        .irq_o      (irq_o)
    );

    // ---- 헬퍼 태스크 -------------------------------------------------------
    integer fail_cnt;
    integer tc_num;

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
            valid = 1; we = 0; addr = a; wdata = 0;
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

    // 베이스 (DUT는 직접 연결이므로 주소 하위 비트만 사용)
    localparam B = 32'h1002_0000;
    localparam OFF_CTRL      = 32'h00;
    localparam OFF_DT_CYCLES = 32'h04;
    localparam OFF_STATUS    = 32'h08;
    localparam OFF_PWM_IN    = 32'h0C;
    localparam OFF_PWM_OUT   = 32'h10;
    localparam OFF_ID        = 32'hFFF0;
    localparam OFF_VER       = 32'hFFF4;
    localparam OFF_IRQ_STS   = 32'hFFF8;
    localparam OFF_IRQ_EN    = 32'hFFFC;

    localparam DT_CYCLES = 10;

    reg [31:0] rd;
    integer    i;

    // ---- 메인 테스트 -------------------------------------------------------
    initial begin
        fail_cnt = 0;
        valid = 0; we = 0; addr = 0; wdata = 0;
        oc_fault = 0;

        // 리셋 해제 대기
        @(negedge rst);
        repeat(3) @(posedge clk);

        // -----------------------------------------------------------------
        // TC1: ID 레지스터
        // -----------------------------------------------------------------
        tc_num = 1;
        mmio_read(B + OFF_ID, rd);
        check_eq(rd, 32'h4D535731, "ID=MSW1");
        mmio_read(B + OFF_VER, rd);
        check_eq(rd, 32'h01000001, "VER");

        // -----------------------------------------------------------------
        // TC2: 슛스루 차단 — AH&AL 동시=1 → 출력 둘 다 0
        // -----------------------------------------------------------------
        tc_num = 2;
        // DT_CYCLES=10, enable=1
        mmio_write(B + OFF_DT_CYCLES, DT_CYCLES);
        mmio_write(B + OFF_CTRL, 32'h1);           // enable
        // PWM_IN[1:0] = 2'b11 (AH=1, AL=1)
        mmio_write(B + OFF_PWM_IN, 32'h3);         // {BL,BH,AL,AH}=0011
        @(posedge clk); @(posedge clk); #1;
        // 슛스루: AH_out & AL_out 모두 0
        check_eq(pwm_ah, 1'b0, "TC2:pwm_ah=0");
        check_eq(pwm_al, 1'b0, "TC2:pwm_al=0");

        // 초기화 — AH→0 하강이 DT_CYCLES짜리 데드타임을 유발하므로
        //          FSM이 S_IDLE로 복귀할 때까지 충분히 기다린다
        mmio_write(B + OFF_PWM_IN, 32'h0);
        repeat(DT_CYCLES + 5) @(posedge clk);

        // -----------------------------------------------------------------
        // TC3: 데드타임 — AH_in 하강 후 AL_out은 DT_CYCLES 뒤에 등장
        // -----------------------------------------------------------------
        tc_num = 3;
        // AH=1 설정
        mmio_write(B + OFF_PWM_IN, 32'h1);         // AH_in=1
        @(posedge clk); @(posedge clk); #1;
        check_eq(pwm_ah, 1'b1, "TC3:AH_on");

        // AH→0, AL=1 로 전환
        mmio_write(B + OFF_PWM_IN, 32'h2);         // AL_in=1
        // 전환 직후(1사이클): AL_out 아직 0 (데드타임 중)
        @(posedge clk); #1;
        check_eq(pwm_al, 1'b0, "TC3:AL_still_0_dt");

        // DT_CYCLES+2 사이클 대기 후 AL_out=1 확인
        repeat(DT_CYCLES + 2) @(posedge clk);
        #1;
        check_eq(pwm_al, 1'b1, "TC3:AL_up_after_dt");

        // 초기화
        mmio_write(B + OFF_PWM_IN, 32'h0);
        repeat(DT_CYCLES + 5) @(posedge clk);

        // -----------------------------------------------------------------
        // TC4: 과전류 래치 — oc_fault_i 상승 → 출력=0, oc_latched=1
        // -----------------------------------------------------------------
        tc_num = 4;
        // BH=1 설정
        mmio_write(B + OFF_PWM_IN, 32'h4);         // BH_in=1
        @(posedge clk); @(posedge clk); #1;
        check_eq(pwm_bh, 1'b1, "TC4:BH_on");

        // 과전류 발생
        oc_fault = 1;
        @(posedge clk); @(posedge clk); @(posedge clk); #1; // 2단 동기화 + 1
        // 출력 모두 0
        check_eq(pwm_ah, 1'b0, "TC4:AH=0 on OC");
        check_eq(pwm_al, 1'b0, "TC4:AL=0 on OC");
        check_eq(pwm_bh, 1'b0, "TC4:BH=0 on OC");
        check_eq(pwm_bl, 1'b0, "TC4:BL=0 on OC");
        // STATUS.oc_latched=1
        mmio_read(B + OFF_STATUS, rd);
        check_eq(rd[0], 1'b1, "TC4:oc_latched=1");
        // IRQ_STATUS.oc_event=1
        mmio_read(B + OFF_IRQ_STS, rd);
        check_eq(rd[0], 1'b1, "TC4:irq_status=1");

        oc_fault = 0; // 외부 신호 해제 (래치는 소프트웨어 해제)
        repeat(3) @(posedge clk);

        // -----------------------------------------------------------------
        // TC5: 과전류 해제 — CTRL.oc_clear → oc_latched=0, 출력 복귀
        // -----------------------------------------------------------------
        tc_num = 5;
        // IRQ_STATUS RW1C 소거
        mmio_write(B + OFF_IRQ_STS, 32'h1);
        // oc_clear(bit1)=1 + enable(bit0)=1
        mmio_write(B + OFF_CTRL, 32'h3);
        @(posedge clk); @(posedge clk); #1;
        // oc_latched 해제 확인
        mmio_read(B + OFF_STATUS, rd);
        check_eq(rd[0], 1'b0, "TC5:oc_latched=0");
        // IRQ 소거 확인
        mmio_read(B + OFF_IRQ_STS, rd);
        check_eq(rd[0], 1'b0, "TC5:irq_cleared");
        // BH_in=1이 여전히 설정 → BH_out=1 복귀
        @(posedge clk); #1;
        check_eq(pwm_bh, 1'b1, "TC5:BH_restored");

        // 초기화
        mmio_write(B + OFF_PWM_IN, 32'h0);
        repeat(5) @(posedge clk);

        // -----------------------------------------------------------------
        // TC6: dt_bypass — bypass=1 시 슛스루 차단 없이 그대로 출력
        // -----------------------------------------------------------------
        tc_num = 6;
        // dt_bypass=1 (bit2), enable=1 (bit0)
        mmio_write(B + OFF_CTRL, 32'h5);
        // AH=1, AL=1 동시 (bypass 모드)
        mmio_write(B + OFF_PWM_IN, 32'h3);
        @(posedge clk); @(posedge clk); #1;
        // bypass 모드: 슛스루 허용 → 둘 다 1
        check_eq(pwm_ah, 1'b1, "TC6:bypass AH=1");
        check_eq(pwm_al, 1'b1, "TC6:bypass AL=1");

        // 최종 초기화
        mmio_write(B + OFF_CTRL,   32'h0);
        mmio_write(B + OFF_PWM_IN, 32'h0);
        repeat(5) @(posedge clk);

        // -----------------------------------------------------------------
        // 결과 보고
        // -----------------------------------------------------------------
        if (fail_cnt == 0) begin
            $display("PASS: motor_safety_ip 모든 항목(%0d개) 통과", 6);
        end else begin
            $display("FAIL: %0d개 항목 실패", fail_cnt);
        end

        $finish;
    end

    // 타임아웃 (5 µs)
    initial begin
        #5000;
        $display("FAIL: 시뮬레이션 타임아웃");
        $finish;
    end

endmodule

`default_nettype wire
