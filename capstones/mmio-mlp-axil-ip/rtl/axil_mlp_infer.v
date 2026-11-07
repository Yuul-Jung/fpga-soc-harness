// axil_mlp_infer.v — AXI4-Lite MLP 추론 IP
// capstone: mmio-mlp-axil-ip
// 슬롯: [2F] 0x402F_0000 (동결 맵 mbv-frozen-v2 free slot)
// 참조: columbia-4840-sp26-mnist-accelerator (Avalon-MM 레지스터 맵 → AXI4-Lite 변환)
// 2026-11-08
//
// 레지스터 맵 (AXI4-Lite, 오프셋 단위 4):
//   0x00  CONTROL   W   [0]=start, [1]=load_mode, [2]=clear_done
//   0x04  STATUS    R   [0]=busy, [1]=done(sticky)
//   0x08  RESULT    R   예측 클래스 [3:0]
//   0x0C  CONFIDENCE R  FC2 최대 누산값 [31:0]
//   0x10  LOAD_ADDR R/W 로드 대상 인덱스
//   0x14  LOAD_DATA  W  스트리밍 데이터 (하위 8비트 INT8, 32비트 B1/B2)
//   0x18  LOAD_TARGET W  0=W1, 1=B1, 2=W2, 3=B2, 4=INPUT
//   0x1C  VERSION    R  0x00010000
//
// Verilog-2001 호환: $clog2 대신 명시적 주소 폭 파라미터 사용
`default_nettype none

module axil_mlp_infer #(
    parameter BASE_ADDR = 32'h402F_0000,
    parameter N_IN      = 784,
    parameter N_H       = 128,
    parameter N_OUT     = 10,
    parameter IN_W      = 8,
    parameter W_W       = 8,
    parameter B_W       = 32,
    parameter ACC_W     = 32,
    // BRAM 깊이
    parameter D_W1      = N_IN * N_H,   // 100352
    parameter D_B1      = N_H,           // 128
    parameter D_W2      = N_H * N_OUT,   // 1280
    parameter D_B2      = N_OUT,          // 10
    parameter D_INPUT   = N_IN,           // 784
    // 명시적 주소 폭 (Verilog-2001: $clog2 미지원 시 직접 지정)
    // 기본값: 784 입력, 128 은닉, 10 출력
    parameter AW_IN  = 10,   // ceil(log2(N_IN))    : 784→10
    parameter AW_H   = 7,    // ceil(log2(N_H))     : 128→7
    parameter AW_OUT = 4,    // ceil(log2(N_OUT))   : 10→4
    parameter AW_W1  = 17,   // ceil(log2(N_H*N_IN)): 100352→17
    parameter AW_W2  = 11    // ceil(log2(N_H*N_OUT)): 1280→11
)(
    input  wire        clk,
    input  wire        rst,

    // AXI4-Lite 슬레이브 포트
    input  wire [7:0]  s_awaddr,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output wire        s_wready,
    output wire [1:0]  s_bresp,
    output wire        s_bvalid,
    input  wire        s_bready,
    input  wire [7:0]  s_araddr,
    input  wire        s_arvalid,
    output wire        s_arready,
    output wire [31:0] s_rdata,
    output wire [1:0]  s_rresp,
    output wire        s_rvalid,
    input  wire        s_rready,

    // 외부 출력 (디버그용)
    output wire [3:0]  result_out,
    output wire        done_out
);

    // ───────── 내부 BRAM (register-file 형태) ─────────
    // W1: N_H × N_IN INT8
    reg signed [W_W-1:0]  bram_w1   [0:D_W1-1];
    // B1: N_H INT32
    reg signed [B_W-1:0]  bram_b1   [0:D_B1-1];
    // W2: N_OUT × N_H INT8
    reg signed [W_W-1:0]  bram_w2   [0:D_W2-1];
    // B2: N_OUT INT32
    reg signed [B_W-1:0]  bram_b2   [0:D_B2-1];
    // INPUT: N_IN INT8
    reg signed [IN_W-1:0] bram_inp  [0:D_INPUT-1];
    // 은닉층 버퍼: N_H INT32 (ReLU 후)
    reg signed [ACC_W-1:0] bram_h   [0:N_H-1];
    // FC2 출력 버퍼: N_OUT INT32
    reg signed [ACC_W-1:0] bram_fc2 [0:N_OUT-1];

    // $readmemh 초기화 (파일 없으면 가중치=0으로 동작)
    initial begin
        $readmemh("tb/weights/w1.hex",   bram_w1);
        $readmemh("tb/weights/b1.hex",   bram_b1);
        $readmemh("tb/weights/w2.hex",   bram_w2);
        $readmemh("tb/weights/b2.hex",   bram_b2);
        $readmemh("tb/weights/input.hex", bram_inp);
    end

    // ───────── 레지스터 ─────────
    reg [31:0] reg_load_addr;
    reg [2:0]  reg_load_target;
    reg        reg_busy, reg_done;
    reg [3:0]  reg_result;
    reg signed [ACC_W-1:0] reg_confidence;

    // ───────── AXI4-Lite 핸드셰이크 ─────────
    reg aw_ready, w_ready, b_valid, ar_ready, r_valid;
    reg [31:0] r_data;
    reg [7:0]  awaddr_lat;

    assign s_awready = aw_ready;
    assign s_wready  = w_ready;
    assign s_bvalid  = b_valid;
    assign s_bresp   = 2'b00;
    assign s_arready = ar_ready;
    assign s_rvalid  = r_valid;
    assign s_rdata   = r_data;
    assign s_rresp   = 2'b00;

    // start 요청: 쓰기 채널이 세팅, FSM 제어 블록이 1사이클 펄스로 소비
    reg start_req;
    reg start_int;

    // 쓰기 채널
    reg wr_phase;  // 0=주소 대기, 1=데이터 대기
    always @(posedge clk) begin
        if (rst) begin
            aw_ready  <= 1'b1;
            w_ready   <= 1'b0;
            b_valid   <= 1'b0;
            wr_phase  <= 1'b0;
            start_req <= 1'b0;
        end else begin
            start_req <= 1'b0;  // 기본: 1사이클 펄스 자동 소거

            if (b_valid && s_bready)
                b_valid <= 1'b0;

            if (!wr_phase) begin
                if (s_awvalid && aw_ready) begin
                    awaddr_lat <= s_awaddr;
                    aw_ready   <= 1'b0;
                    w_ready    <= 1'b1;
                    wr_phase   <= 1'b1;
                end
            end else begin
                if (s_wvalid && w_ready) begin
                    w_ready  <= 1'b0;
                    aw_ready <= 1'b1;
                    wr_phase <= 1'b0;
                    b_valid  <= 1'b1;
                    // 레지스터 디코딩
                    case (awaddr_lat[4:2])
                        3'd0: begin  // CONTROL 0x00
                            if (s_wdata[0] && !reg_busy)
                                start_req <= 1'b1;  // FSM 제어 블록이 start_int로 변환
                            if (s_wdata[2])
                                reg_done <= 1'b0;
                        end
                        3'd4: begin  // LOAD_ADDR 0x10
                            reg_load_addr <= s_wdata;
                        end
                        3'd5: begin  // LOAD_DATA 0x14
                            // AW_* 파라미터로 주소 슬라이스 (Verilog-2001: $clog2 미사용)
                            case (reg_load_target)
                                3'd0: bram_w1 [reg_load_addr[AW_W1-1:0]] <= s_wdata[W_W-1:0];
                                3'd1: bram_b1 [reg_load_addr[AW_H-1:0]]  <= s_wdata[B_W-1:0];
                                3'd2: bram_w2 [reg_load_addr[AW_W2-1:0]] <= s_wdata[W_W-1:0];
                                3'd3: bram_b2 [reg_load_addr[AW_OUT-1:0]] <= s_wdata[B_W-1:0];
                                3'd4: bram_inp[reg_load_addr[AW_IN-1:0]]  <= s_wdata[IN_W-1:0];
                                default: ;
                            endcase
                            reg_load_addr <= reg_load_addr + 1;
                        end
                        3'd6: begin  // LOAD_TARGET 0x18
                            reg_load_target <= s_wdata[2:0];
                            reg_load_addr   <= 32'd0;
                        end
                        default: ;
                    endcase
                end
            end
        end
    end

    // 읽기 채널
    always @(posedge clk) begin
        if (rst) begin
            ar_ready <= 1'b1;
            r_valid  <= 1'b0;
            r_data   <= 32'd0;
        end else begin
            if (r_valid && s_rready)
                r_valid <= 1'b0;

            if (s_arvalid && ar_ready) begin
                ar_ready <= 1'b1;
                r_valid  <= 1'b1;
                case (s_araddr[4:2])
                    3'd0: r_data <= 32'd0;  // CONTROL write-only
                    3'd1: r_data <= {30'd0, reg_done, reg_busy};  // STATUS
                    3'd2: r_data <= {28'd0, reg_result};          // RESULT
                    3'd3: r_data <= reg_confidence;               // CONFIDENCE
                    3'd4: r_data <= reg_load_addr;                // LOAD_ADDR
                    3'd5: r_data <= 32'd0;                        // LOAD_DATA write-only
                    3'd6: r_data <= {29'd0, reg_load_target};     // LOAD_TARGET
                    3'd7: r_data <= 32'h0001_0000;                // VERSION
                    default: r_data <= 32'd0;
                endcase
            end
        end
    end

    // ───────── MAC FSM ─────────
    // FSM용 BRAM 포트 신호 (AW_* 파라미터 사용, Verilog-2001 호환)
    wire [AW_IN-1:0]   fsm_inp_addr;
    wire signed [IN_W-1:0]        fsm_inp_rdata;
    wire [AW_W1-1:0]   fsm_w1_addr;
    wire signed [W_W-1:0]         fsm_w1_rdata;
    wire [AW_H-1:0]    fsm_b1_addr;
    wire signed [B_W-1:0]         fsm_b1_rdata;
    wire [AW_H-1:0]    fsm_h_wr_addr;
    wire signed [ACC_W-1:0]       fsm_h_wr_data;
    wire                           fsm_h_wr_en;
    wire [AW_H-1:0]    fsm_h_rd_addr;
    wire signed [ACC_W-1:0]       fsm_h_rd_data;
    wire [AW_W2-1:0]   fsm_w2_addr;
    wire signed [W_W-1:0]         fsm_w2_rdata;
    wire [AW_OUT-1:0]  fsm_b2_addr;
    wire signed [B_W-1:0]         fsm_b2_rdata;
    wire [AW_OUT-1:0]  fsm_fc2_wr_addr;
    wire signed [ACC_W-1:0]       fsm_fc2_wr_data;
    wire                           fsm_fc2_wr_en;
    wire [AW_OUT-1:0]  fsm_fc2_rd_addr;
    wire signed [ACC_W-1:0]       fsm_fc2_rd_data;
    wire [3:0]                     fsm_result;
    wire signed [ACC_W-1:0]       fsm_confidence;
    wire fsm_busy, fsm_done;

    // BRAM 읽기 동기 (1사이클 지연)
    reg signed [IN_W-1:0]  bram_inp_rd;
    reg signed [W_W-1:0]   bram_w1_rd, bram_w2_rd;
    reg signed [B_W-1:0]   bram_b1_rd, bram_b2_rd;
    reg signed [ACC_W-1:0] bram_h_rd, bram_fc2_rd;

    always @(posedge clk) begin
        bram_inp_rd  <= bram_inp[fsm_inp_addr];
        bram_w1_rd   <= bram_w1[fsm_w1_addr];
        bram_b1_rd   <= bram_b1[fsm_b1_addr];
        bram_h_rd    <= bram_h[fsm_h_rd_addr];
        bram_w2_rd   <= bram_w2[fsm_w2_addr];
        bram_b2_rd   <= bram_b2[fsm_b2_addr];
        bram_fc2_rd  <= bram_fc2[fsm_fc2_rd_addr];
        if (fsm_h_wr_en)
            bram_h[fsm_h_wr_addr] <= fsm_h_wr_data;
        if (fsm_fc2_wr_en)
            bram_fc2[fsm_fc2_wr_addr] <= fsm_fc2_wr_data;
    end

    assign fsm_inp_rdata  = bram_inp_rd;
    assign fsm_w1_rdata   = bram_w1_rd;
    assign fsm_b1_rdata   = bram_b1_rd;
    assign fsm_h_rd_data  = bram_h_rd;
    assign fsm_w2_rdata   = bram_w2_rd;
    assign fsm_b2_rdata   = bram_b2_rd;
    assign fsm_fc2_rd_data = bram_fc2_rd;

    mlp_mac_fsm #(
        .N_IN(N_IN), .N_H(N_H), .N_OUT(N_OUT),
        .IN_W(IN_W), .W_W(W_W), .B_W(B_W), .ACC_W(ACC_W),
        .AW_IN(AW_IN), .AW_H(AW_H), .AW_OUT(AW_OUT),
        .AW_W1(AW_W1), .AW_W2(AW_W2)
    ) u_mac (
        .clk        (clk),
        .rst        (rst),
        .start      (start_int),
        .busy       (fsm_busy),
        .done       (fsm_done),
        .inp_addr   (fsm_inp_addr),
        .inp_rdata  (fsm_inp_rdata),
        .w1_addr    (fsm_w1_addr),
        .w1_rdata   (fsm_w1_rdata),
        .b1_addr    (fsm_b1_addr),
        .b1_rdata   (fsm_b1_rdata),
        .h_wr_addr  (fsm_h_wr_addr),
        .h_wr_data  (fsm_h_wr_data),
        .h_wr_en    (fsm_h_wr_en),
        .h_rd_addr  (fsm_h_rd_addr),
        .h_rd_data  (fsm_h_rd_data),
        .w2_addr    (fsm_w2_addr),
        .w2_rdata   (fsm_w2_rdata),
        .b2_addr    (fsm_b2_addr),
        .b2_rdata   (fsm_b2_rdata),
        .fc2_wr_addr(fsm_fc2_wr_addr),
        .fc2_wr_data(fsm_fc2_wr_data),
        .fc2_wr_en  (fsm_fc2_wr_en),
        .fc2_rd_addr(fsm_fc2_rd_addr),
        .fc2_rd_data(fsm_fc2_rd_data),
        .result     (fsm_result),
        .confidence (fsm_confidence)
    );

    // start_int 1사이클 펄스 생성 + FSM 상태 캡처
    always @(posedge clk) begin
        if (rst) begin
            start_int      <= 1'b0;
            reg_busy       <= 1'b0;
            reg_done       <= 1'b0;
            reg_result     <= 4'd0;
            reg_confidence <= 0;
        end else begin
            // start_req(쓰기 채널) → start_int 1사이클 펄스
            start_int <= start_req;

            if (fsm_busy)
                reg_busy <= 1'b1;
            else
                reg_busy <= 1'b0;

            if (fsm_done) begin
                reg_done       <= 1'b1;
                reg_result     <= fsm_result;
                reg_confidence <= fsm_confidence;
            end
        end
    end

    assign result_out = reg_result;
    assign done_out   = reg_done;

endmodule
`default_nettype wire
