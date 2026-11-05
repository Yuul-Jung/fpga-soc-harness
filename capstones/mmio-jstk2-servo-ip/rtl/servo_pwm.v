// servo_pwm.v — 2채널 RC 서보 PWM 생성기
// 하네스 원본 (외부 코드 포함 없음)
// 50 Hz 주기: 2,000,000 클럭 @ 100 MHz
// 펄스 폭: 1,000,000~2,000,000 클럭 (1 ms~2 ms), 클램프 적용
`timescale 1ns/1ps
`default_nettype none

module servo_pwm #(
    parameter CLK_FREQ_HZ  = 100_000_000,
    parameter SERVO_PERIOD  = 2_000_000, // 20 ms @ 100 MHz
    parameter PULSE_MIN     = 1_000_000, // 1 ms @ 100 MHz
    parameter PULSE_MAX     = 2_000_000  // 2 ms @ 100 MHz
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,            // 1=PWM 출력 활성
    input  wire [31:0] pos_a,         // 채널 A 펄스 폭 (클럭 수)
    input  wire [31:0] pos_b,         // 채널 B 펄스 폭 (클럭 수)
    input  wire [31:0] slew,          // 기울기 제한 (0=제한 없음)
    output reg         pwm_a,         // 서보 A 신호
    output reg         pwm_b          // 서보 B 신호
);

// 현재 출력 위치 (기울기 제한 적용)
reg [31:0] cur_a;
reg [31:0] cur_b;

// 주기 카운터
reg [20:0] period_cnt;

// 목표 위치 클램프 함수 (combinational)
function [31:0] clamp;
    input [31:0] val;
    begin
        if (val < PULSE_MIN) clamp = PULSE_MIN;
        else if (val > PULSE_MAX) clamp = PULSE_MAX;
        else clamp = val;
    end
endfunction

// 기울기 제한 적용 (슬루율 제어)
// slew != 0일 때 주기마다 최대 slew 클럭만큼 이동
// 주기 경계에서 목표 갱신
wire [31:0] target_a = clamp(pos_a);
wire [31:0] target_b = clamp(pos_b);

reg period_tick; // 주기 경계 1클럭 펄스

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        period_cnt <= 21'd0;
        period_tick <= 1'b0;
        cur_a <= PULSE_MIN + (PULSE_MAX - PULSE_MIN) / 2; // 중앙
        cur_b <= PULSE_MIN + (PULSE_MAX - PULSE_MIN) / 2;
        pwm_a <= 1'b0;
        pwm_b <= 1'b0;
    end else begin
        period_tick <= 1'b0;

        if (period_cnt >= SERVO_PERIOD - 1) begin
            period_cnt  <= 21'd0;
            period_tick <= 1'b1;
        end else begin
            period_cnt <= period_cnt + 1'b1;
        end

        // 주기 경계에서 목표 위치 갱신 (기울기 제한)
        if (period_tick) begin
            // 채널 A 기울기 제한
            if (slew == 32'd0) begin
                cur_a <= target_a;
            end else if (target_a > cur_a) begin
                cur_a <= (target_a - cur_a > slew) ? cur_a + slew : target_a;
            end else begin
                cur_a <= (cur_a - target_a > slew) ? cur_a - slew : target_a;
            end
            // 채널 B 기울기 제한
            if (slew == 32'd0) begin
                cur_b <= target_b;
            end else if (target_b > cur_b) begin
                cur_b <= (target_b - cur_b > slew) ? cur_b + slew : target_b;
            end else begin
                cur_b <= (cur_b - target_b > slew) ? cur_b - slew : target_b;
            end
        end

        // PWM 출력: period_cnt < cur_x 동안 HIGH
        if (!en) begin
            pwm_a <= 1'b0;
            pwm_b <= 1'b0;
        end else begin
            pwm_a <= (period_cnt < cur_a) ? 1'b1 : 1'b0;
            pwm_b <= (period_cnt < cur_b) ? 1'b1 : 1'b0;
        end
    end
end

endmodule
`default_nettype wire
