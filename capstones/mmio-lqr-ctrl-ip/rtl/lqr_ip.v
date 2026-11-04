// lqr_ip.v — LQR 상태 되먹임 제어기 IP (Q8.8 MAC FSM)
// 기능:
//   u = K[0]*x + K[1]*dx + K[2]*θ + K[3]*dθ
//   Q8.8 고정소수점 (16비트 부호): 정수부 8비트, 소수부 8비트
//   40비트 부호 누산기로 Q16.16 곱 4개를 더한 뒤 비트[23:8] 추출, 포화
//   start 펄스 → 7클럭 이내 done 펄스 출력
//
// 포트 단위:
//   K[0..3], x,dx,θ,dθ: Q8.8 (16비트 부호) — 1.0 = 0x0100
//   u_out: Q8.8 포화 (범위 0x8000=-128.0 ~ 0x7FFF≈+127.996)
//
// FSM: IDLE → MAC0 → MAC1 → MAC2 → MAC3 → SAT → DONE → IDLE
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)
`default_nettype none

module lqr_ip (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,          // 1클럭 펄스
    output reg         done,           // 1클럭 펄스 (완료)
    output reg         busy,
    // 이득 K[0..3] (Q8.8 부호)
    input  wire signed [15:0] k0,
    input  wire signed [15:0] k1,
    input  wire signed [15:0] k2,
    input  wire signed [15:0] k3,
    // 상태 (Q8.8 부호)
    input  wire signed [15:0] x_state,
    input  wire signed [15:0] dx_state,
    input  wire signed [15:0] theta,
    input  wire signed [15:0] dtheta,
    // 제어 출력 (Q8.8 부호, 포화)
    output reg  signed [15:0] u_out
);

    // ─── FSM 상태 ────────────────────────────────────────────────────────────
    localparam [2:0]
        S_IDLE = 3'd0,
        S_MAC0 = 3'd1,
        S_MAC1 = 3'd2,
        S_MAC2 = 3'd3,
        S_MAC3 = 3'd4,
        S_SAT  = 3'd5,
        S_DONE = 3'd6;

    reg [2:0] state;

    // ─── 누산기 (40비트 부호: Q17.16 에 여유 추가) ───────────────────────────
    // K(Q8.8) × state(Q8.8) = Q16.16 (32비트). 4개 합 최대 Q17.16 (33비트).
    // 40비트로 오버플로 방지.
    reg signed [39:0] accum;

    // ─── 곱셈 선택 MUX (레지스터에서 래치된 값 사용) ─────────────────────────
    reg signed [15:0] k_lat [0:3];
    reg signed [15:0] s_lat [0:3];

    wire signed [31:0] product0 = k_lat[0] * s_lat[0]; // Q16.16
    wire signed [31:0] product1 = k_lat[1] * s_lat[1];
    wire signed [31:0] product2 = k_lat[2] * s_lat[2];
    wire signed [31:0] product3 = k_lat[3] * s_lat[3];

    // ─── FSM ─────────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            state  <= S_IDLE;
            done   <= 1'b0;
            busy   <= 1'b0;
            accum  <= 40'sd0;
            u_out  <= 16'sd0;
            k_lat[0] <= 16'sd0; k_lat[1] <= 16'sd0;
            k_lat[2] <= 16'sd0; k_lat[3] <= 16'sd0;
            s_lat[0] <= 16'sd0; s_lat[1] <= 16'sd0;
            s_lat[2] <= 16'sd0; s_lat[3] <= 16'sd0;
        end else begin
            done <= 1'b0; // 기본: 클리어

            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (start) begin
                    // 입력 래치
                    k_lat[0] <= k0; k_lat[1] <= k1;
                    k_lat[2] <= k2; k_lat[3] <= k3;
                    s_lat[0] <= x_state; s_lat[1] <= dx_state;
                    s_lat[2] <= theta;   s_lat[3] <= dtheta;
                    accum <= 40'sd0;
                    busy  <= 1'b1;
                    state <= S_MAC0;
                end
            end

            S_MAC0: begin
                accum <= {{8{product0[31]}}, product0}; // 부호 확장
                state <= S_MAC1;
            end

            S_MAC1: begin
                accum <= accum + {{8{product1[31]}}, product1};
                state <= S_MAC2;
            end

            S_MAC2: begin
                accum <= accum + {{8{product2[31]}}, product2};
                state <= S_MAC3;
            end

            S_MAC3: begin
                accum <= accum + {{8{product3[31]}}, product3};
                state <= S_SAT;
            end

            S_SAT: begin
                // Q16.16 → Q8.8: 비트[23:8] 추출, 포화 처리
                // 오버플로 감지: accum[39:23]이 모두 0 or 모두 1이 아니면 포화
                if (!accum[39] && (|accum[39:23])) begin
                    // 양의 오버플로 → 최대값
                    u_out <= 16'sh7FFF;
                end else if (accum[39] && !(& accum[39:23])) begin
                    // 음의 오버플로 → 최소값
                    u_out <= 16'sh8000;
                end else begin
                    u_out <= accum[23:8];
                end
                state <= S_DONE;
            end

            S_DONE: begin
                done  <= 1'b1;
                busy  <= 1'b0;
                state <= S_IDLE;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
