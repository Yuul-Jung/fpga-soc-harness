`timescale 1ns/1ps
// motor_ctrl.v — 2-채널 DC 모터 PWM 드라이버 (TB6612FNG 호환)
// PWM 주파수: 20 kHz (5000 클럭 @ 100 MHz)
// dir: 00=STOP(coast), 01=FWD, 10=BWD, 11=SPIN_L
// arb_stop=1 → 양쪽 PWM 강제 0 (안전 정지)
// speed 0=0 %, 255≒99.6 % duty (duty = speed × 5000 / 256 ≒ speed × 20)
`default_nettype none
module motor_ctrl (
    input  wire       clk,
    input  wire       rst_n,
    // 명령
    input  wire [1:0] dir,       // 00=STOP,01=FWD,10=BWD,11=SPIN_L
    input  wire [7:0] speed,     // 0-255
    input  wire       arb_stop,  // 1 → 모든 PWM = 0
    // TB6612FNG 채널 A (왼쪽 모터)
    output reg        ain1,
    output reg        ain2,
    output wire       pwm_a,
    // TB6612FNG 채널 B (오른쪽 모터)
    output reg        bin1,
    output reg        bin2,
    output wire       pwm_b
);
    localparam DIR_STOP  = 2'b00;
    localparam DIR_FWD   = 2'b01;
    localparam DIR_BWD   = 2'b10;
    localparam DIR_SPINL = 2'b11;

    // PWM 카운터와 듀티
    // 20 kHz → 주기 5000 클럭 (100 MHz). 듀티 = speed × 20 (0~5100, 5100>5000이면 항상 ON)
    // speed[7:0] 범위 0~255. speed × 20 최대 5100 → clamp to 5000
    localparam [12:0] PWM_PERIOD = 13'd5000;

    reg  [12:0] cnt;
    reg  [12:0] duty;
    wire        pwm_on;

    // 듀티 계산: speed * 20. speed=255 → 5100 > 5000 → 클램프
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            duty <= 13'd0;
        else begin
            // speed * 20 = speed * 16 + speed * 4
            // 최대 255 * 20 = 5100 → 5000으로 클램프
            if (speed >= 8'd250)
                duty <= PWM_PERIOD;
            else
                duty <= {5'd0, speed} * 13'd20;
        end
    end

    // PWM 카운터
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 13'd0;
        else if (cnt == PWM_PERIOD - 1)
            cnt <= 13'd0;
        else
            cnt <= cnt + 13'd1;
    end

    assign pwm_on = (cnt < duty) && !arb_stop;
    assign pwm_a  = pwm_on;
    assign pwm_b  = pwm_on;

    // 방향 제어 (조합 논리)
    // arb_stop=1 또는 dir=STOP → AIN1=AIN2=0 (공회전 정지)
    always @(*) begin
        if (arb_stop) begin
            ain1 = 1'b0; ain2 = 1'b0;
            bin1 = 1'b0; bin2 = 1'b0;
        end else begin
            case (dir)
                DIR_FWD: begin             // 양쪽 전진
                    ain1 = 1'b1; ain2 = 1'b0;
                    bin1 = 1'b1; bin2 = 1'b0;
                end
                DIR_BWD: begin             // 양쪽 후진
                    ain1 = 1'b0; ain2 = 1'b1;
                    bin1 = 1'b0; bin2 = 1'b1;
                end
                DIR_SPINL: begin           // 왼쪽 제자리 회전
                    ain1 = 1'b0; ain2 = 1'b1;  // 왼쪽 후진
                    bin1 = 1'b1; bin2 = 1'b0;  // 오른쪽 전진
                end
                default: begin             // STOP (coast)
                    ain1 = 1'b0; ain2 = 1'b0;
                    bin1 = 1'b0; bin2 = 1'b0;
                end
            endcase
        end
    end
endmodule
`default_nettype wire
