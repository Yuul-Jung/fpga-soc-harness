// mlp_mac_fsm.v — 단일 순차 MAC FSM (FC1→ReLU→FC2→argmax)
// capstone: mmio-mlp-axil-ip
// 참조: columbia-4840-sp26-mnist-accelerator (Avalon-MM 순차 MAC 구조)
//       ansh07verma-fpga-mini-npu (INT8 MAC 2사이클 파이프라인 참고)
// 2026-11-08
//
// 동작: start=1 → FC1 MAC → ReLU → FC2 MAC → argmax → done=1
// BRAM 읽기 지연: 1사이클 (동기 BRAM, `read_first`)
// Verilog-2001 호환: $clog2 대신 명시적 주소 폭 파라미터 사용
`default_nettype none

module mlp_mac_fsm #(
    parameter N_IN  = 784,     // FC1 입력
    parameter N_H   = 128,     // 은닉층 크기
    parameter N_OUT = 10,      // 출력 클래스 수
    parameter IN_W  = 8,       // 입력 비트폭 (INT8)
    parameter W_W   = 8,       // 가중치 비트폭 (INT8)
    parameter B_W   = 32,      // 편향 비트폭
    parameter ACC_W = 32,      // 누산기 비트폭
    // 명시적 주소 폭 (Verilog-2001: $clog2 미지원 시 직접 지정)
    parameter AW_IN  = 10,     // ceil(log2(N_IN))  : 784→10
    parameter AW_H   = 7,      // ceil(log2(N_H))   : 128→7
    parameter AW_OUT = 4,      // ceil(log2(N_OUT)) : 10→4
    parameter AW_W1  = 17,     // ceil(log2(N_H*N_IN)): 100352→17
    parameter AW_W2  = 11      // ceil(log2(N_OUT*N_H)): 1280→11
)(
    input  wire clk,
    input  wire rst,

    // 제어
    input  wire start,
    output reg  busy,
    output reg  done,

    // 입력 BRAM 포트 (N_IN × IN_W)
    output reg  [AW_IN-1:0]  inp_addr,
    input  wire signed [IN_W-1:0] inp_rdata,

    // W1 BRAM (N_H × N_IN, 행우선)
    output reg  [AW_W1-1:0] w1_addr,
    input  wire signed [W_W-1:0]  w1_rdata,

    // B1 BRAM (N_H × B_W)
    output reg  [AW_H-1:0]  b1_addr,
    input  wire signed [B_W-1:0]  b1_rdata,

    // 중간 은닉층 쓰기 포트 (ReLU 후)
    output reg  [AW_H-1:0]  h_wr_addr,
    output reg  signed [ACC_W-1:0] h_wr_data,
    output reg               h_wr_en,

    // 중간 은닉층 읽기 포트
    output reg  [AW_H-1:0]  h_rd_addr,
    input  wire signed [ACC_W-1:0] h_rd_data,

    // W2 BRAM (N_OUT × N_H, 행우선)
    output reg  [AW_W2-1:0] w2_addr,
    input  wire signed [W_W-1:0]  w2_rdata,

    // B2 BRAM (N_OUT × B_W)
    output reg  [AW_OUT-1:0] b2_addr,
    input  wire signed [B_W-1:0]  b2_rdata,

    // FC2 출력 쓰기 포트
    output reg  [AW_OUT-1:0] fc2_wr_addr,
    output reg  signed [ACC_W-1:0] fc2_wr_data,
    output reg                fc2_wr_en,

    // FC2 출력 읽기 포트 (argmax)
    output reg  [AW_OUT-1:0] fc2_rd_addr,
    input  wire signed [ACC_W-1:0] fc2_rd_data,

    // 최종 결과
    output reg  [3:0]         result,
    output reg  signed [ACC_W-1:0] confidence
);

    // FSM 상태
    localparam [3:0]
        S_IDLE    = 4'd0,
        S_FC1_PRE = 4'd1,
        S_FC1_RD  = 4'd2,
        S_FC1_MAC = 4'd3,
        S_FC1_END = 4'd4,
        S_RELU    = 4'd5,
        S_FC2_PRE = 4'd6,
        S_FC2_RD  = 4'd7,
        S_FC2_MAC = 4'd8,
        S_FC2_END = 4'd9,
        S_FC2_B2  = 4'd10,
        S_ARGMAX  = 4'd11,
        S_ARGMAX2 = 4'd12,
        S_DONE    = 4'd13;

    reg [3:0] state;

    // 카운터 (명시적 폭)
    reg [AW_H-1:0]   h_cnt;
    reg [AW_IN-1:0]  i_cnt;
    reg [AW_OUT-1:0] o_cnt;
    reg [AW_H-1:0]   j_cnt;

    // 누산기
    reg signed [ACC_W-1:0] acc;

    // argmax 임시
    reg signed [ACC_W-1:0] cur_max;
    reg [3:0]               cur_idx;

    // 파이프라인 1사이클 지연
    reg signed [IN_W-1:0] inp_lat;
    reg signed [W_W-1:0]  w_lat;

    // ReLU 조합 논리 (axil_mlp_infer에서 외부 인스턴스 대신 인라인)
    wire signed [ACC_W-1:0] relu_out;
    assign relu_out = acc[ACC_W-1] ? {ACC_W{1'b0}} : acc;

    // 최소 부호 정수 (argmax 초기값)
    localparam signed [ACC_W-1:0] MIN_INT = {1'b1, {(ACC_W-1){1'b0}}};

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            busy       <= 1'b0;
            done       <= 1'b0;
            h_wr_en    <= 1'b0;
            fc2_wr_en  <= 1'b0;
            result     <= 4'd0;
            confidence <= 0;
            cur_max    <= MIN_INT;
            cur_idx    <= 0;
        end else begin
            h_wr_en   <= 1'b0;
            fc2_wr_en <= 1'b0;

            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        busy    <= 1'b1;
                        h_cnt   <= 0;
                        i_cnt   <= 0;
                        acc     <= 0;
                        b1_addr <= 0;
                        state   <= S_FC1_PRE;
                    end
                end

                // FC1: 각 은닉 뉴런 h_cnt에 대해 모든 입력 i_cnt를 MAC
                S_FC1_PRE: begin
                    // B1[h_cnt] 읽기 1사이클 대기
                    state <= S_FC1_RD;
                end

                S_FC1_RD: begin
                    inp_addr <= i_cnt;
                    w1_addr  <= h_cnt * N_IN[AW_W1-1:0] + i_cnt[AW_W1-1:0];
                    state    <= S_FC1_MAC;
                end

                S_FC1_MAC: begin
                    // 1사이클 뒤 데이터 도착: 부호 확장 MAC
                    acc <= acc + ({{(ACC_W-IN_W){inp_rdata[IN_W-1]}}, inp_rdata} *
                                  {{(ACC_W-W_W){w1_rdata[W_W-1]}}, w1_rdata});

                    if (i_cnt == N_IN[AW_IN-1:0] - 1) begin
                        state <= S_FC1_END;
                    end else begin
                        i_cnt <= i_cnt + 1;
                        state <= S_FC1_RD;
                    end
                end

                S_FC1_END: begin
                    // B1[h_cnt] 더하기 (S_FC1_PRE에서 주소 세팅됨)
                    acc   <= acc + {{(ACC_W-B_W){b1_rdata[B_W-1]}}, b1_rdata};
                    state <= S_RELU;
                end

                S_RELU: begin
                    // relu_out = max(0, acc)
                    h_wr_addr <= h_cnt;
                    h_wr_data <= relu_out;
                    h_wr_en   <= 1'b1;

                    if (h_cnt == N_H[AW_H-1:0] - 1) begin
                        // FC1 완료 → FC2 시작
                        o_cnt   <= 0;
                        j_cnt   <= 0;
                        acc     <= 0;
                        b2_addr <= 0;
                        state   <= S_FC2_PRE;
                    end else begin
                        h_cnt   <= h_cnt + 1;
                        b1_addr <= h_cnt + 1;
                        i_cnt   <= 0;
                        acc     <= 0;
                        state   <= S_FC1_PRE;
                    end
                end

                // FC2: 각 출력 o_cnt에 대해 모든 은닉 j_cnt를 MAC
                S_FC2_PRE: begin
                    state <= S_FC2_RD;
                end

                S_FC2_RD: begin
                    h_rd_addr <= j_cnt;
                    w2_addr   <= o_cnt * N_H[AW_W2-1:0] + j_cnt[AW_W2-1:0];
                    state     <= S_FC2_MAC;
                end

                S_FC2_MAC: begin
                    acc <= acc + ({{(ACC_W-IN_W){h_rd_data[IN_W-1]}}, h_rd_data[IN_W-1:0]} *
                                  {{(ACC_W-W_W){w2_rdata[W_W-1]}}, w2_rdata});

                    if (j_cnt == N_H[AW_H-1:0] - 1) begin
                        state <= S_FC2_END;
                    end else begin
                        j_cnt <= j_cnt + 1;
                        state <= S_FC2_RD;
                    end
                end

                S_FC2_END: begin
                    fc2_wr_addr <= o_cnt;
                    fc2_wr_data <= acc + {{(ACC_W-B_W){b2_rdata[B_W-1]}}, b2_rdata};
                    fc2_wr_en   <= 1'b1;
                    state       <= S_FC2_B2;
                end

                S_FC2_B2: begin
                    if (o_cnt == N_OUT[AW_OUT-1:0] - 1) begin
                        // FC2 완료 → argmax
                        o_cnt       <= 0;
                        cur_max     <= MIN_INT;
                        cur_idx     <= 0;
                        fc2_rd_addr <= 0;
                        state       <= S_ARGMAX;
                    end else begin
                        o_cnt   <= o_cnt + 1;
                        b2_addr <= o_cnt + 1;
                        j_cnt   <= 0;
                        acc     <= 0;
                        state   <= S_FC2_PRE;
                    end
                end

                // argmax: 순차 비교 (1사이클 읽기 지연)
                S_ARGMAX: begin
                    state <= S_ARGMAX2;
                end

                S_ARGMAX2: begin
                    if (fc2_rd_data > cur_max) begin
                        cur_max <= fc2_rd_data;
                        cur_idx <= o_cnt[3:0];
                    end

                    if (o_cnt == N_OUT[AW_OUT-1:0] - 1) begin
                        state <= S_DONE;
                    end else begin
                        o_cnt       <= o_cnt + 1;
                        fc2_rd_addr <= o_cnt + 1;
                        state       <= S_ARGMAX;
                    end
                end

                S_DONE: begin
                    result     <= cur_idx;
                    confidence <= cur_max;
                    busy       <= 1'b0;
                    done       <= 1'b1;
                    state      <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
