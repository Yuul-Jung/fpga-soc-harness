// sla_core.v — 소프트 논리 분석기 코어 (16채널 BRAM 샘플 메모리 + 에지 트리거 FSM)
// I-067 소프트 논리 분석기 IP (mmio-sla-bram-capture, T2)
// Verilog-2001. iverilog/verilator/yosys 호환.
//
// 포트:
//   clk        — 시스템 클럭
//   rst        — 동기 active-high 리셋
//   arm        — 1사이클 펄스: IDLE→ARMED 전이
//   force_trig — 1사이클 펄스: 트리거 강제 발생 (ARMED 상태에서만 유효)
//   srst       — 소프트 리셋 (모든 카운터·상태 초기화)
//   trig_ch    — [3:0] 트리거 채널 번호 (0~15)
//   trig_pol   — 1=하강 에지, 0=상승 에지
//   pretrig    — [DEPTH_LOG2-1:0] 트리거 전 보관 샘플 수
//   ch_en      — [15:0] 채널 활성 마스크
//   ch_in      — [15:0] 디지털 입력 (외부 메타스테이블 방지 2단 FF 적용 후 연결)
//   rd_addr    — [DEPTH_LOG2-1:0] BRAM 읽기 주소
//
//   sample_out — [15:0] rd_addr의 샘플 데이터
//   armed      — 1=ARMED 상태
//   capturing  — 1=캡처 진행 중 (pre-trigger 포함)
//   full       — 1=BRAM 가득 참 (캡처 완료)
//   trig_found — 1=트리거 발생 확인
//   trig_addr  — [DEPTH_LOG2-1:0] 트리거 발생 시점의 쓰기 주소

`default_nettype none

module sla_core #(
    parameter DEPTH_LOG2 = 12   // BRAM 깊이 (2^12 = 4096 샘플). 테스트벤치는 8로 줄임
) (
    input  wire                   clk,
    input  wire                   rst,

    // 제어
    input  wire                   arm,
    input  wire                   force_trig,
    input  wire                   srst,
    input  wire [3:0]             trig_ch,
    input  wire                   trig_pol,
    input  wire [DEPTH_LOG2-1:0]  pretrig,
    input  wire [15:0]            ch_en,

    // 채널 입력
    input  wire [15:0]            ch_in,

    // BRAM 읽기
    input  wire [DEPTH_LOG2-1:0]  rd_addr,
    output reg  [15:0]            sample_out,

    // 상태 출력
    output reg                    armed,
    output reg                    capturing,
    output reg                    full,
    output reg                    trig_found,
    output reg  [DEPTH_LOG2-1:0]  trig_addr
);

    localparam DEPTH = 1 << DEPTH_LOG2;

    // ── 2단 메타스테이블 방지 ──────────────────────────────
    reg [15:0] ch0, ch1;
    always @(posedge clk) begin
        ch0 <= ch_in;
        ch1 <= ch0;
    end

    // ── 이전 사이클 ch1 (에지 검출용) ────────────────────
    reg [15:0] ch1_d;
    always @(posedge clk)
        ch1_d <= ch1;

    // ── 채널 마스크 ──────────────────────────────────────
    wire [15:0] masked = ch1 & ch_en;

    // ── 트리거 에지 검출 ──────────────────────────────────
    wire trig_bit     = ch1[trig_ch];
    wire trig_bit_d   = ch1_d[trig_ch];
    // 상승 에지(pol=0): d=0, now=1 / 하강 에지(pol=1): d=1, now=0
    wire edge_hit = trig_pol ? ( trig_bit_d & ~trig_bit)
                              : (~trig_bit_d &  trig_bit);

    // ── BRAM (추론 BRAM, Xilinx Block RAM 매핑 대상) ──────
    (* ram_style = "block" *)
    reg [15:0] bram [0:DEPTH-1];

    // ── 쓰기 포인터와 샘플 카운터 ─────────────────────────
    reg [DEPTH_LOG2-1:0] wr_addr;
    reg [DEPTH_LOG2:0]   sample_cnt;   // DEPTH_LOG2+1 비트 (DEPTH까지 셀 수 있음)

    // ── pre-trigger 카운터 ───────────────────────────────
    // pretrig 샘플을 쌓을 때까지 트리거 검출을 억제한다.
    reg [DEPTH_LOG2-1:0] pre_cnt;
    reg                  pre_done;     // pre-trigger 채움 완료

    // ── FSM ───────────────────────────────────────────────
    // IDLE: armed=0, capturing=0, full=0
    // ARMED: armed=1, capturing=0, full=0  — arm 펄스로 진입, pre-trigger 채움 중
    // CAPTURING: armed=1, capturing=1, full=0  — 트리거 발생 후 나머지 채움
    // FULL: full=1
    localparam S_IDLE      = 2'd0;
    localparam S_ARMED     = 2'd1;
    localparam S_CAPTURING = 2'd2;
    localparam S_FULL      = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst || srst) begin
            state      <= S_IDLE;
            armed      <= 1'b0;
            capturing  <= 1'b0;
            full       <= 1'b0;
            trig_found <= 1'b0;
            trig_addr  <= {DEPTH_LOG2{1'b0}};
            wr_addr    <= {DEPTH_LOG2{1'b0}};
            sample_cnt <= {(DEPTH_LOG2+1){1'b0}};
            pre_cnt    <= {DEPTH_LOG2{1'b0}};
            pre_done   <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (arm) begin
                        state      <= S_ARMED;
                        armed      <= 1'b1;
                        capturing  <= 1'b0;
                        full       <= 1'b0;
                        trig_found <= 1'b0;
                        wr_addr    <= {DEPTH_LOG2{1'b0}};
                        sample_cnt <= {(DEPTH_LOG2+1){1'b0}};
                        pre_cnt    <= {DEPTH_LOG2{1'b0}};
                        pre_done   <= (pretrig == {DEPTH_LOG2{1'b0}});
                    end
                end

                S_ARMED: begin
                    // 샘플을 계속 써넣는다 (링 버퍼처럼 순환)
                    bram[wr_addr] <= masked;
                    wr_addr    <= wr_addr + 1'b1;

                    // pre-trigger 카운터
                    if (!pre_done) begin
                        if (pre_cnt >= pretrig - 1'b1)
                            pre_done <= 1'b1;
                        else
                            pre_cnt <= pre_cnt + 1'b1;
                    end

                    // 트리거 검출 (pre_done 후에만)
                    if (pre_done && (edge_hit || force_trig)) begin
                        state      <= S_CAPTURING;
                        capturing  <= 1'b1;
                        trig_found <= 1'b1;
                        trig_addr  <= wr_addr;
                        sample_cnt <= {{DEPTH_LOG2{1'b0}}, 1'b1};
                    end
                end

                S_CAPTURING: begin
                    // 트리거 이후 나머지 DEPTH 샘플을 채운다
                    bram[wr_addr] <= masked;
                    wr_addr    <= wr_addr + 1'b1;
                    sample_cnt <= sample_cnt + 1'b1;

                    if (sample_cnt >= DEPTH - 1) begin
                        state     <= S_FULL;
                        capturing <= 1'b0;
                        full      <= 1'b1;
                    end
                end

                S_FULL: begin
                    // arm 펄스가 오면 재무장
                    if (arm) begin
                        state      <= S_ARMED;
                        armed      <= 1'b1;
                        capturing  <= 1'b0;
                        full       <= 1'b0;
                        trig_found <= 1'b0;
                        wr_addr    <= {DEPTH_LOG2{1'b0}};
                        sample_cnt <= {(DEPTH_LOG2+1){1'b0}};
                        pre_cnt    <= {DEPTH_LOG2{1'b0}};
                        pre_done   <= (pretrig == {DEPTH_LOG2{1'b0}});
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ── BRAM 읽기 포트 (1사이클 레이턴시) ────────────────
    always @(posedge clk)
        sample_out <= bram[rd_addr];

endmodule

`default_nettype wire
