// step_ramp_core.v — 사다리꼴 가감속 FSM
// 출처: 하네스 직접 작성 Verilog-2001 원본 (외부 코드 없음)
// 알고리즘: 주기 기반(period-countdown) DDA. 곱셈·나눗셈 없음.
//   ACCEL: 스텝마다 current_period -= delta (MIN_PERIOD에서 클램프)
//   DECEL: 스텝마다 current_period += delta (MAX_PERIOD에서 클램프)
//   전환: step_cnt >= target>>1 이면 ACCEL→DECEL
//   완료: step_cnt >= target 이면 DONE
`default_nettype none
`timescale 1ns/1ps

module step_ramp_core (
    input  wire        clk,
    input  wire        rst,          // active-high synchronous
    // 제어
    input  wire        start,        // 1펄스 → IDLE에서 ACCEL로
    input  wire        stop,         // 1펄스 → 즉시 IDLE
    // 파라미터 (start 전에 설정)
    input  wire [23:0] i_target,     // 총 스텝 수. 0이면 무시.
    input  wire [23:0] i_min_period, // 최소 주기(클럭), 최소 2
    input  wire [23:0] i_max_period, // 최대 주기(클럭)
    input  wire [15:0] i_delta,      // 스텝당 주기 변화량
    // 출력
    output reg         step_pulse,   // 1클럭 펄스, 스텝 1회
    output wire        dir,          // 방향 (상시 1 = CW, 추후 확장)
    output reg  [1:0]  state,        // 0=IDLE,1=ACCEL,2=DECEL,3=DONE
    output wire        busy,
    output reg         done          // 완료 플래그 (레지스터가 읽고 클리어)
);
    localparam IDLE  = 2'd0;
    localparam ACCEL = 2'd1;
    localparam DECEL = 2'd2;
    localparam S_DONE = 2'd3;

    assign dir  = 1'b1;
    assign busy = (state == ACCEL) || (state == DECEL);

    // ── 내부 레지스터 ──────────────────────────────────────────────
    reg [23:0] step_cnt;      // 완료된 스텝 수
    reg [23:0] period_cnt;    // 현재 스텝의 남은 클럭 수
    reg [23:0] cur_period;    // 현재 적용 주기

    // ── 다음 주기 계산 (조합) ──────────────────────────────────────
    wire [24:0] accel_sub = {1'b0, cur_period} - {8'b0, i_delta};
    wire [24:0] decel_add = {1'b0, cur_period} + {8'b0, i_delta};

    wire [23:0] nxt_accel =
        (accel_sub[24] || accel_sub[23:0] < i_min_period)
            ? i_min_period : accel_sub[23:0];

    wire [23:0] nxt_decel =
        (decel_add[24] || decel_add[23:0] > i_max_period)
            ? i_max_period : decel_add[23:0];

    // ── 다음 step_cnt (조합) ──────────────────────────────────────
    wire [23:0] nxt_cnt = step_cnt + 24'd1;

    // ── FSM + 주기 카운터 (1개 always) ────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            step_cnt   <= 24'd0;
            period_cnt <= 24'd0;
            cur_period <= 24'd0;
            step_pulse <= 1'b0;
            done       <= 1'b0;
        end else begin
            step_pulse <= 1'b0; // 기본: 펄스 없음

            case (state)

            IDLE: begin
                done <= 1'b0;
                if (start && (i_target != 24'd0)) begin
                    cur_period <= i_max_period;
                    period_cnt <= i_max_period;
                    step_cnt   <= 24'd0;
                    state      <= ACCEL;
                end
            end

            ACCEL, DECEL: begin
                if (stop) begin
                    state <= IDLE;
                end else if (period_cnt == 24'd1) begin
                    // ── 이번 사이클에 스텝 발생 ──
                    step_pulse <= 1'b1;

                    if (nxt_cnt >= i_target) begin
                        // 목표 완료
                        state      <= S_DONE;
                        step_cnt   <= nxt_cnt;
                        done       <= 1'b1;
                        period_cnt <= 24'd1;
                    end else begin
                        step_cnt <= nxt_cnt;
                        if (state == ACCEL) begin
                            // 절반 이상 왔으면 DECEL로 전환
                            if (nxt_cnt >= (i_target >> 1))
                                state <= DECEL;
                            cur_period <= nxt_accel;
                            period_cnt <= nxt_accel;
                        end else begin
                            // DECEL
                            cur_period <= nxt_decel;
                            period_cnt <= nxt_decel;
                        end
                    end
                end else begin
                    period_cnt <= period_cnt - 24'd1;
                end
            end

            S_DONE: begin
                // done 플래그는 외부(axil_stepper)가 읽고 클리어
                if (start && (i_target != 24'd0)) begin
                    // 재시작
                    cur_period <= i_max_period;
                    period_cnt <= i_max_period;
                    step_cnt   <= 24'd0;
                    state      <= ACCEL;
                    done       <= 1'b0;
                end
            end

            endcase
        end
    end

endmodule
`default_nettype wire
