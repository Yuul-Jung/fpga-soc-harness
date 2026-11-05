`timescale 1ns/1ps
// scan_fsm.v — 서보 3방향 순차 스캔 FSM
// 좌(45°) → 중(90°) → 우(135°) 순으로 서보 이동 후 HC-SR04 측정 × 3
// SETTLE_CYC: 서보 정착 시간 클럭 수 (기본 30_000_000 = 300 ms @ 100 MHz)
// dist_L/C/R 초깃값 0x3FF (범위 초과) → 첫 스캔 완료 전 arb_fsm 오작동 방지
`default_nettype none
module scan_fsm #(
    parameter SETTLE_CYC = 30_000_000   // 서보 정착 시간 (테스트벤치에서 작은 값으로 오버라이드)
) (
    input  wire        clk,
    input  wire        rst_n,
    // 제어
    input  wire        scan_start,  // 1-클럭 스캔 개시 펄스
    // → servo_pwm
    output reg  [7:0]  scan_angle,  // 서보 목표 각도 (도)
    // → hcsr04_drv
    output reg         meas_start,  // 1-클럭 측정 개시 펄스
    // ← hcsr04_drv
    input  wire [9:0]  dist_in,     // 측정 거리 cm (hcsr04_drv.dist_cm)
    input  wire        meas_done,   // 1-클럭 측정 완료
    // 결과
    output reg  [9:0]  dist_L,
    output reg  [9:0]  dist_C,
    output reg  [9:0]  dist_R,
    output reg         scan_done,   // 1-클럭 스캔 완료
    output wire        scan_busy    // 스캔 진행 중 HIGH
);
    localparam ANGLE_L = 8'd45;
    localparam ANGLE_C = 8'd90;
    localparam ANGLE_R = 8'd135;

    // FSM 상태
    localparam S_IDLE   = 3'd0;
    localparam S_MOV_L  = 3'd1;
    localparam S_MEAS_L = 3'd2;
    localparam S_MOV_C  = 3'd3;
    localparam S_MEAS_C = 3'd4;
    localparam S_MOV_R  = 3'd5;
    localparam S_MEAS_R = 3'd6;
    localparam S_RET    = 3'd7;

    reg [2:0]  state;
    reg [24:0] scnt;   // 정착 카운터 (25-bit: 2^25 ≈ 33 M > 30 M)

    assign scan_busy = (state != S_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            scan_angle <= ANGLE_C;
            meas_start <= 1'b0;
            scan_done  <= 1'b0;
            dist_L     <= 10'h3FF;  // 미스캔 = 범위 초과
            dist_C     <= 10'h3FF;
            dist_R     <= 10'h3FF;
            scnt       <= 25'd0;
        end else begin
            meas_start <= 1'b0;
            scan_done  <= 1'b0;

            case (state)
                S_IDLE: begin
                    scan_angle <= ANGLE_C;
                    if (scan_start) begin
                        scan_angle <= ANGLE_L;
                        scnt       <= 25'd0;
                        state      <= S_MOV_L;
                    end
                end

                // ── 좌(45°) 이동 → 측정 ──
                S_MOV_L: begin
                    if (scnt == SETTLE_CYC - 1) begin
                        scnt       <= 25'd0;
                        meas_start <= 1'b1;
                        state      <= S_MEAS_L;
                    end else
                        scnt <= scnt + 25'd1;
                end
                S_MEAS_L: begin
                    if (meas_done) begin
                        dist_L     <= dist_in;
                        scan_angle <= ANGLE_C;
                        scnt       <= 25'd0;
                        state      <= S_MOV_C;
                    end
                end

                // ── 중(90°) 이동 → 측정 ──
                S_MOV_C: begin
                    if (scnt == SETTLE_CYC - 1) begin
                        scnt       <= 25'd0;
                        meas_start <= 1'b1;
                        state      <= S_MEAS_C;
                    end else
                        scnt <= scnt + 25'd1;
                end
                S_MEAS_C: begin
                    if (meas_done) begin
                        dist_C     <= dist_in;
                        scan_angle <= ANGLE_R;
                        scnt       <= 25'd0;
                        state      <= S_MOV_R;
                    end
                end

                // ── 우(135°) 이동 → 측정 ──
                S_MOV_R: begin
                    if (scnt == SETTLE_CYC - 1) begin
                        scnt       <= 25'd0;
                        meas_start <= 1'b1;
                        state      <= S_MEAS_R;
                    end else
                        scnt <= scnt + 25'd1;
                end
                S_MEAS_R: begin
                    if (meas_done) begin
                        dist_R     <= dist_in;
                        scan_angle <= ANGLE_C;
                        scnt       <= 25'd0;
                        state      <= S_RET;
                    end
                end

                // ── 중립(90°) 복귀 ──
                S_RET: begin
                    if (scnt == SETTLE_CYC - 1) begin
                        scan_done <= 1'b1;
                        state     <= S_IDLE;
                    end else
                        scnt <= scnt + 25'd1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
