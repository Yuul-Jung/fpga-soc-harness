// arb_fsm.v — 명령 우선순위 중재 FSM
// dist_min < threshold  → arb_stop = 1 (안전 정지, 명령 무관)
// dist_min >= threshold + HYST(5cm) → arb_stop = 0 (복귀)
// best_dir: 세 방향 중 거리 최대 방향 (00=L, 01=C, 10=R)
// fsm_state: 0=IDLE(EN=0), 1=RUN, 2=SAFE_STOP
`default_nettype none
module arb_fsm (
    input  wire        clk,
    input  wire        rst_n,
    // 거리 (← scan_fsm)
    input  wire [9:0]  dist_L,
    input  wire [9:0]  dist_C,
    input  wire [9:0]  dist_R,
    // CPU 명령 (← AXI 레지스터)
    input  wire [7:0]  threshold,   // 임계 거리 cm (8-bit, 최대 255 cm)
    input  wire        ctrl_en,     // CTRL[0]: IP 활성화
    // 출력 (→ STATUS 레지스터, → motor_ctrl)
    output reg         arb_stop,    // 안전 정지 플래그
    output reg  [1:0]  best_dir,    // 여유 최대 방향 (00=L, 01=C, 10=R)
    output reg  [3:0]  fsm_state    // STATUS[3:0]
);
    // 히스테리시스 상수 (5 cm)
    localparam [7:0] HYST = 8'd5;

    // 상태 코드
    localparam [3:0] ST_IDLE = 4'd0, ST_RUN = 4'd1, ST_SAFE = 4'd2;

    // threshold를 10-bit로 확장해 dist_L/C/R 과 비교
    wire [9:0] thr10  = {2'b00, threshold};
    wire [9:0] hys10  = thr10 + {2'b00, HYST};

    // dist_min: 세 방향 중 최솟값
    wire [9:0] min_LC = (dist_L < dist_C) ? dist_L : dist_C;
    wire [9:0] dist_min = (min_LC < dist_R) ? min_LC : dist_R;

    // best_dir 조합 논리 (clk에 무관하게 계산)
    wire [1:0] comb_best_dir =
        (dist_L >= dist_C && dist_L >= dist_R) ? 2'b00 :
        (dist_R >= dist_C && dist_R >= dist_L) ? 2'b10 : 2'b01;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            arb_stop  <= 1'b0;
            best_dir  <= 2'b01;         // 초기: 중앙
            fsm_state <= ST_IDLE;
        end else begin
            best_dir <= comb_best_dir;

            if (!ctrl_en) begin
                // IP 비활성화
                arb_stop  <= 1'b0;
                fsm_state <= ST_IDLE;
            end else if (!arb_stop) begin
                // RUN 상태: 진입 조건 검사
                if (dist_min < thr10) begin
                    arb_stop  <= 1'b1;
                    fsm_state <= ST_SAFE;
                end else begin
                    fsm_state <= ST_RUN;
                end
            end else begin
                // SAFE_STOP 상태: 복귀 조건 검사 (히스테리시스)
                if (dist_min >= hys10) begin
                    arb_stop  <= 1'b0;
                    fsm_state <= ST_RUN;
                end
                // else: 계속 SAFE_STOP
            end
        end
    end
endmodule
`default_nettype wire
