// frame_buf.v
// 8×16 비트맵 프레임 버퍼
// 모드에 따라 IIR 에너지(막대) 또는 ADXL 기울기(점)로 갱신
// MAX7219 체인 드라이버에 bitmap[127:0] 제공
//
// CI fix v3 — 조합 논리와 순차 논리 완전 분리.
//   bm_next: always @(*) 블록에서 블로킹으로 계산.
//   bitmap:  always @(posedge clk) 블록에서 NBA 한 번만.
//   이 구조는 iverilog/verilator/yosys 모두에서 동작이 정의된다.
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
    // 기울기 보유 레지스터
    reg signed [9:0]   x_hold, y_hold;

    // 비트맵 조합 계산용 중간 변수 (always @(*) 전용)
    reg [ROWS*COLS-1:0] bm_next;
    reg [3:0] bh;    // bar height 0~8
    reg [3:0] dc;    // dot column 0~15
    reg [3:0] dri;   // dot row (4비트 임시, 오버플로 방지)
    reg [2:0] dr;    // dot row 0~7
    integer   gi, bb, ri;

    // ----------------------------------------------------------------
    // ADXL 최신값 유지 (순차)
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            x_hold <= 0;
            y_hold <= 0;
        end else if (adxl_valid) begin
            x_hold <= x_tilt;
            y_hold <= y_tilt;
        end
    end

    // ----------------------------------------------------------------
    // 비트맵 조합 계산 — always @(*) 로 bm_next를 항상 최신으로 유지.
    // 블로킹 대입(=)만 사용. NBA 없음.
    // ----------------------------------------------------------------
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
                bh = {1'b0, energy_flat[(bb+1)*ENERGY_W - 1 -: 3]}
                   + {3'b0, energy_flat[(bb+1)*ENERGY_W - 4]};
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
    // 비트맵 등록 (순차) — bm_next를 NBA 한 번으로 래치.
    // ----------------------------------------------------------------
    always @(posedge clk) begin : bitmap_reg
        integer ui;
        if (!rst_n || soft_rst) begin
            bitmap  <= 0;
            refresh <= 0;
        end else begin
            refresh <= 0;
            if (energy_update || adxl_valid) begin
                bitmap  <= bm_next;
                refresh <= 1;
            end
        end
    end

endmodule
`default_nettype wire
