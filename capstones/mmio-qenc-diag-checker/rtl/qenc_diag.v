// qenc_diag.v — 4체배 직교 엔코더 디코더 + 불가능 전이 카운터
// I-016 엔코더 난이도 사다리 (mmio-qenc-diag-checker, T2)
// Verilog-2001. iverilog/verilator/yosys 호환.
//
// 포트:
//   clk        — 100 MHz 시스템 클럭
//   rst        — 동기 active-high 리셋
//   en         — 1이면 디코드 활성
//   srst       — 소프트 리셋 (카운터 0으로 초기화, en 무관)
//   window_en  — 1이면 10 ms 창 속도 계산 활성
//   a_in, b_in — 엔코더 A/B 신호 (Basys3 Pmod, 3.3V)
//
//   position   — 32비트 부호 있는 위치 카운터
//   velocity   — 16비트 최근 10 ms 창 카운트
//   dir        — 0=정방향(A 먼저 올라감), 1=역방향
//   ovfl       — 위치 오버플로 래치 (부호 비트 토글)
//   err_latch  — 불가능 전이 발생 래치
//   error_cnt  — 16비트 불가능 전이 누산 카운터

`default_nettype none

module qenc_diag #(
    parameter WINDOW_CYCLES = 1_000_000  // 10 ms @ 100 MHz
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire        srst,
    input  wire        window_en,

    // 엔코더 입력 (외부에서 메타스테이블 방지 2단 FF 적용 후 연결)
    input  wire        a_in,
    input  wire        b_in,

    // 출력
    output reg  [31:0] position,
    output reg  [15:0] velocity,
    output reg         dir,
    output reg         ovfl,
    output reg         err_latch,
    output reg  [15:0] error_cnt
);

    // ── 2단 메타스테이블 방지 ──────────────────────────────
    reg a0, a1, b0, b1;
    always @(posedge clk) begin
        a0 <= a_in; a1 <= a0;
        b0 <= b_in; b1 <= b0;
    end

    // ── 직전/현재 상태 레지스터 ───────────────────────────
    reg [1:0] prev_ab;
    wire [1:0] curr_ab = {a1, b1};

    // 4체배 Gray 전이 테이블
    // {prev[1],prev[0],curr[1],curr[0]} → {valid, dir_now}
    // dir_now: 0=정방향(+1), 1=역방향(-1)
    // 불가능 전이: 2비트 동시 변화 (00→11, 11→00, 01→10, 10→01)
    reg       trans_valid;
    reg       trans_dir;    // 0=CW(+), 1=CCW(-)

    always @(*) begin
        case ({prev_ab, curr_ab})
            // 정방향 (+1): 00→10, 10→11, 11→01, 01→00
            4'b00_10: begin trans_valid = en; trans_dir = 1'b0; end
            4'b10_11: begin trans_valid = en; trans_dir = 1'b0; end
            4'b11_01: begin trans_valid = en; trans_dir = 1'b0; end
            4'b01_00: begin trans_valid = en; trans_dir = 1'b0; end
            // 역방향 (-1): 00→01, 01→11, 11→10, 10→00
            4'b00_01: begin trans_valid = en; trans_dir = 1'b1; end
            4'b01_11: begin trans_valid = en; trans_dir = 1'b1; end
            4'b11_10: begin trans_valid = en; trans_dir = 1'b1; end
            4'b10_00: begin trans_valid = en; trans_dir = 1'b1; end
            // 정지(변화 없음): valid이지만 카운트하지 않음
            4'b00_00,
            4'b01_01,
            4'b10_10,
            4'b11_11: begin trans_valid = 1'b1; trans_dir = dir; end
            // 그 외: 불가능 전이 (2비트 동시 변화)
            default:  begin trans_valid = 1'b0; trans_dir = dir; end
        endcase
    end

    // ── 위치 카운터 ───────────────────────────────────────
    reg [31:0] pos_next;
    always @(*) begin
        if (trans_valid && en && (curr_ab !== prev_ab)) begin
            if (trans_dir == 1'b0)
                pos_next = position + 1;
            else
                pos_next = position - 1;
        end else begin
            pos_next = position;
        end
    end

    // 오버플로 감지: 부호 비트가 바뀌면서 절대값이 작아지는 경우
    wire ovfl_now = (pos_next[31] !== position[31]) &&
                    (pos_next[30:0] < position[30:0]);

    // ── 창 속도 카운터 ────────────────────────────────────
    reg [26:0] win_timer;    // log2(1_000_000) ≈ 20비트 → 27비트 여유
    reg [15:0] win_acc;      // 현재 창 누산
    reg        win_tick;     // 창 완료 플래그

    always @(posedge clk) begin
        if (rst || srst) begin
            win_timer <= 0;
            win_acc   <= 0;
            win_tick  <= 0;
            velocity  <= 0;
        end else if (!window_en) begin
            win_timer <= 0;
            win_acc   <= 0;
            win_tick  <= 0;
        end else begin
            win_tick <= 0;
            if (win_timer >= WINDOW_CYCLES - 1) begin
                win_timer <= 0;
                win_tick  <= 1;
            end else begin
                win_timer <= win_timer + 1;
            end
            // 창 내 카운트 누산 (정방향·역방향 모두 절댓값으로)
            if (trans_valid && en && (curr_ab !== prev_ab))
                win_acc <= win_acc + 1;
            // 창 완료 시 velocity 갱신, 누산 초기화
            // win_tick=1일 때 velocity는 현재 win_acc를 캡처하고, 다음 클럭에 win_acc를 초기화
            if (win_tick) begin
                velocity <= win_acc;
                win_acc  <= 0;
            end
        end
    end

    // ── 메인 레지스터 클록 ────────────────────────────────
    always @(posedge clk) begin
        if (rst || srst) begin
            position  <= 0;
            dir       <= 0;
            ovfl      <= 0;
            err_latch <= 0;
            error_cnt <= 0;
            prev_ab   <= 0;
        end else begin
            prev_ab <= curr_ab;

            // 위치 갱신
            if (en && trans_valid && (curr_ab !== prev_ab)) begin
                position <= pos_next;
                dir      <= trans_dir;
                if (ovfl_now)
                    ovfl <= 1'b1;
            end

            // 오류 카운터
            if (en && !trans_valid && (curr_ab !== prev_ab)) begin
                err_latch <= 1'b1;
                if (error_cnt != 16'hFFFF)
                    error_cnt <= error_cnt + 1;
            end
        end
    end

endmodule

`default_nettype wire
