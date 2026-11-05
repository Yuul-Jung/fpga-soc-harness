`timescale 1ns/1ps
// servo_pwm.v — 50 Hz 서보 PWM 발생기
// 100 MHz 클럭, 20 ms 주기(2_000_000 클럭)
// angle[7:0]: 0 → 1 ms 펄스(0°), 180 → 2 ms 펄스(180°)
// 펄스폭(클럭) = 100_000 + angle × 555  (≒ 1 ms + angle/180 × 1 ms)
`default_nettype none
module servo_pwm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] angle,   // 0~180 (도)
    output reg        pwm_out
);

    localparam PERIOD   = 2_000_000;  // 20 ms @ 100 MHz
    localparam PULSE_MIN = 100_000;   // 1 ms
    // pulse = PULSE_MIN + angle * 555 (최대 100_000 + 180*555 = 199_900 ≒ 2 ms)

    reg [20:0] cnt;
    reg [20:0] pulse_w;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 21'd0;
            pulse_w <= PULSE_MIN;
            pwm_out <= 1'b0;
        end else begin
            if (cnt == PERIOD - 1) begin
                cnt     <= 21'd0;
                // 주기 시작 시 펄스폭 갱신
                pulse_w <= PULSE_MIN + ({13'd0, angle} * 21'd555);
                pwm_out <= 1'b1;
            end else begin
                cnt <= cnt + 21'd1;
                if (cnt == pulse_w) begin
                    pwm_out <= 1'b0;
                end
            end
        end
    end

endmodule
`default_nettype wire
