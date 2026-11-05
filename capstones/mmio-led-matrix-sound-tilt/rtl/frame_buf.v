// frame_buf.v
// 8×16 비트맵 프레임 버퍼
// 모드에 따라 IIR 에너지(막대) 또는 ADXL 기울기(점)로 갱신
// MAX7219 체인 드라이버에 bitmap[127:0] 제공
//
// CI fix v2 — 단일 NBA: bm_next 임시 변수로 비트맵을 조립한 뒤
// bitmap <= bm_next 한 번만 대입. 복수 비트-셀렉트 NBA의
// iverilog 처리 순서 문제(coalesce 버그)를 회피한다.
// 동기 리셋 전용 (yosys proc_dff 호환).
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
    reg [ENERGY_W-1:0] energy [0:N_BANDS-1];
    reg signed [9:0]   x_hold, y_hold;

    // 비트맵 조립용 임시 변수 (블로킹 대입 전용, NBA 아님)
    reg [ROWS*COLS-1:0] bm_next;
    reg [3:0] bh;    // bar height 0~8
    reg [3:0] dc;    // dot column 0~15
    reg [3:0] dri;   // dot row intermediate (오버플로 방지용 4비트)
    reg [2:0] dr;    // dot row 0~7
    integer   gi, bb, ri;

    // 에너지 추출 (단일 always 블록으로 yosys 호환성 확보)
    // 동기 리셋 — negedge rst_n 감도 제거, proc_dff "Multiple edge" 오류 회피
    always @(posedge clk) begin : energy_unpack
        integer ui;
        if (!rst_n) begin
            for (ui = 0; ui < N_BANDS; ui = ui+1) energy[ui] <= 0;
        end else if (energy_update) begin
            for (ui = 0; ui < N_BANDS; ui = ui+1)
                energy[ui] <= energy_flat[ui*ENERGY_W +: ENERGY_W];
        end
    end

    // ADXL 최신값 유지
    always @(posedge clk) begin
        if (!rst_n) begin x_hold <= 0; y_hold <= 0; end
        else if (adxl_valid) begin x_hold <= x_tilt; y_hold <= y_tilt; end
    end

    // 비트맵 갱신 — 단일 NBA 방식
    // bm_next를 블로킹(=)으로 조립한 뒤, 마지막에 bitmap <= bm_next 한 번만.
    // iverilog의 "복수 비트-셀렉트 NBA coalesce" 버그를 회피한다.
    always @(posedge clk) begin
        if (!rst_n || soft_rst) begin
            bitmap  <= 0;
            refresh <= 0;
        end else begin
            refresh <= 0;

            if (energy_update || adxl_valid) begin
                // 1) bm_next를 0으로 초기화 (블로킹)
                bm_next = {(ROWS*COLS){1'b0}};

                // ---- 소리 막대 모드 (mode==2'b00 또는 2'b10) ----
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

                // ---- 기울기 점 모드 (mode==2'b01 또는 2'b10) ----
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

                // 2) 단일 NBA로 bitmap 갱신
                bitmap  <= bm_next;
                refresh <= 1;
            end
        end
    end

endmodule
`default_nettype wire
