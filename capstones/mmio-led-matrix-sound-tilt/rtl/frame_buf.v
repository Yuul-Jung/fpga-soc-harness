// frame_buf.v
// 8×16 비트맵 프레임 버퍼
// 모드에 따라 IIR 에너지(막대) 또는 ADXL 기울기(점)로 갱신
// MAX7219 체인 드라이버에 bitmap[127:0] 제공
//
// CI fix v5 — 에너지 블록과 bitmap_reg 블록 완전 병합.
//
//   근본 원인: iverilog에서 NBA 적용이 별도 always @(posedge clk) 블록에서
//   일어날 때, 그 NBA를 읽는 always @(*) 블록이 재트리거되지 않는다.
//   energy_stored가 별도 블록에 있으면 bitmap 캡처 시 bm_next가 0으로 남는다.
//
//   수정 (TB1+TB2 모두): energy_stored/energy_pend 를 bitmap_reg 블록에 합침.
//   모든 상태 레지스터가 한 always 블록 안에 있으면,
//   NBA 완료 후 always @(*) 가 올바르게 발화해 bm_next가 에너지를 반영한다.
//   동작 타이밍은 v4와 동일: energy_pend는 energy_update의 1사이클 지연이다.
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module frame_buf #(
    parameter N_BANDS  = 8,
    parameter ENERGY_W = 32,
    parameter COLS     = 16,  // 열 수 (MAX7219 2개 × 8열)
    parameter ROWS     = 8    // 행 수
)(
    input  wire        clk,
    input  wire        rst_n,
    // 소리 에너지 입력
    input  wire [N_BANDS*ENERGY_W-1:0] energy_flat,
    input  wire                         energy_update,
    // ADXL 기울기 입력
    input  wire signed [9:0] x_tilt,
    input  wire signed [9:0] y_tilt,
    input  wire              adxl_valid,
    // AXI4-Lite 제어
    input  wire [1:0]  mode,      // 00=소리막대, 01=기울기점, 10=혼합
    input  wire [3:0]  bright,    // MAX7219 밝기 (그대로 전달)
    input  wire        soft_rst,
    // 비트맵 출력 (열 우선, col0=왼쪽)
    // bitmap[row*COLS + col] = pixel(row,col)
    output reg [ROWS*COLS-1:0] bitmap,
    output reg                  refresh   // 갱신 완료 펄스
);
    // ----------------------------------------------------------------
    // 에너지 내부 래치 (flat wide reg — 배열 아님)
    // energy_stored: energy_update 클럭에 energy_flat 래치
    // energy_pend:   energy_stored가 유효해진 다음 사이클 표시
    // (bitmap_reg 블록에서 함께 처리 — 아래 순차 블록 참조)
    // ----------------------------------------------------------------
    reg [N_BANDS*ENERGY_W-1:0] energy_stored;
    reg                         energy_pend;

    // ----------------------------------------------------------------
    // 기울기 보유 레지스터 (조합 블록에서 읽음)
    // ----------------------------------------------------------------
    reg signed [9:0] x_hold, y_hold;

    // ----------------------------------------------------------------
    // 비트맵 조합 계산 — always @(*) 로 bm_next를 항상 최신으로 유지.
    // energy_stored와 x_hold/y_hold를 읽음 (포트 직접 읽기 없음).
    // 블로킹 대입(=)만 사용.
    // ----------------------------------------------------------------
    reg [ROWS*COLS-1:0] bm_next;
    reg [3:0] bh;    // bar height 0~8
    reg [3:0] dc;    // dot column 0~15
    reg [3:0] dri;   // dot row (4비트 임시, 오버플로 방지)
    reg [2:0] dr;    // dot row 0~7
    integer   bb, ri;

    always @(*) begin
        // 초기화
        bm_next = {(ROWS*COLS){1'b0}};
        bh  = 4'd0;
        dc  = 4'd0;
        dri = 4'd0;
        dr  = 3'd0;

        // ---- 소리 막대 모드 (mode==00 또는 10) ----
        if (mode[1:0] != 2'b01) begin
            for (bb = 0; bb < N_BANDS; bb = bb+1) begin
                // 에너지 → 높이: 상위3비트 + 4번째비트(반올림)
                bh = {1'b0, energy_stored[(bb+1)*ENERGY_W - 1 -: 3]}
                   + {3'b0, energy_stored[(bb+1)*ENERGY_W - 4]};
                for (ri = 0; ri < ROWS; ri = ri+1) begin
                    // 아래에서 채우기: row ROWS-1 이 맨 아래
                    if ((ROWS-1 - ri) < bh) begin
                        bm_next[ri*COLS + bb*2]     = 1'b1;
                        bm_next[ri*COLS + bb*2 + 1] = 1'b1;
                    end
                end
            end
        end

        // ---- 기울기 점 모드 (mode==01 또는 10) ----
        if (mode[1:0] != 2'b00) begin
            // X(±512) → 열 0~15, Y(±512) → 행 0~7
            dc  = x_hold[9:6] + 4'd8;
            dri = {1'b0, y_hold[9:7]} + 4'd4;
            // 범위 클램프
            if (dc  > 4'd15) dc  = 4'd15;
            if (dri > 4'd7)  dri = 4'd7;
            dr  = dri[2:0];
            bm_next[dr*COLS + dc] = 1'b1;
        end
    end

    // ----------------------------------------------------------------
    // 순차 블록 (통합) — energy_stored/energy_pend + x_hold/y_hold +
    // bitmap + refresh 를 한 블록에서 처리.
    //
    // 이유: iverilog에서 별도 always 블록의 NBA가 always@(*)를 재트리거하지
    // 않으므로, 모든 상태 레지스터를 한 블록에 두어야 한다.
    // bitmap <= bm_next 의 RHS는 NBA 적용 전 bm_next 값으로 평가된다.
    // → x_hold/y_hold NBA 완료 후 always@(*)가 갱신한 bm_next를
    //   다음 클럭에 bitmap이 캡처한다(adxl 경로: 2사이클 지연, 정상).
    // → energy_stored NBA 완료 후 always@(*)가 갱신한 bm_next를
    //   energy_pend=1인 다음 사이클에 bitmap이 캡처한다(에너지 경로: 정상).
    // ----------------------------------------------------------------
    always @(posedge clk) begin : bitmap_reg
        if (!rst_n || soft_rst) begin
            energy_stored <= 0;
            energy_pend   <= 0;
            x_hold  <= 0;
            y_hold  <= 0;
            bitmap  <= 0;
            refresh <= 0;
        end else begin
            refresh <= 0;

            // 에너지 래치 (energy_pend는 1사이클 지연)
            energy_pend <= energy_update;
            if (energy_update)
                energy_stored <= energy_flat;

            // ADXL 최신값 갱신
            if (adxl_valid) begin
                x_hold <= x_tilt;
                y_hold <= y_tilt;
            end

            // 비트맵 갱신: 에너지 래치 완료(energy_pend) 또는 기울기 갱신(adxl_valid)
            if (energy_pend || adxl_valid) begin
                bitmap  <= bm_next;
                refresh <= 1;
            end
        end
    end

endmodule
`default_nettype wire
