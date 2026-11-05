// frame_buf.v
// 8×16 비트맵 프레임 버퍼
// 모드에 따라 IIR 에너지(막대) 또는 ADXL 기울기(점)로 갱신
// MAX7219 체인 드라이버에 bitmap[127:0] 제공
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
    // 에너지 → 열 높이 (8행 중 몇 행 켤지)
    // energy는 32비트 → 상위 3비트를 사용해 0~7 범위로 스케일
    // 각 열(대역)의 높이: 에너지가 높을수록 아래에서 위로 채움

    reg [ENERGY_W-1:0] energy [0:N_BANDS-1];
    reg signed [9:0]   x_hold, y_hold;

    integer b, r, c;

    // 에너지 추출
    genvar gi;
    generate
        for (gi=0; gi<N_BANDS; gi=gi+1) begin : unpack
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) energy[gi] <= 0;
                else if (energy_update)
                    energy[gi] <= energy_flat[gi*ENERGY_W +: ENERGY_W];
            end
        end
    endgenerate

    // ADXL 최신값 유지
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin x_hold <= 0; y_hold <= 0; end
        else if (adxl_valid) begin x_hold <= x_tilt; y_hold <= y_tilt; end
    end

    // 비트맵 갱신
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || soft_rst) begin
            bitmap  <= 0;
            refresh <= 0;
        end else begin
            refresh <= 0;

            if (energy_update || adxl_valid) begin
                for (r=0; r<ROWS; r=r+1) begin
                    for (c=0; c<COLS; c=c+1) begin
                        bitmap[r*COLS + c] <= 0;  // 초기화
                    end
                end

                // ---- 소리 막대 모드 (mode==2'b00 또는 2'b10) ----
                if (mode[1:0] != 2'b01) begin
                    for (b=0; b<N_BANDS; b=b+1) begin
                        // 에너지 → 높이 (상위 3비트, 0~7)
                        // 열 2개를 한 대역에 사용 (16열 / 8대역)
                        begin : bar_draw
                            reg [2:0] bar_h;
                            integer   row_idx, col_l, col_r;
                            bar_h = energy[b][ENERGY_W-1:ENERGY_W-3];
                            col_l = b * 2;
                            col_r = b * 2 + 1;
                            for (row_idx=0; row_idx<ROWS; row_idx=row_idx+1) begin
                                // 아래에서 채우기: row ROWS-1 이 맨 아래
                                if ((ROWS-1 - row_idx) < bar_h) begin
                                    bitmap[row_idx*COLS + col_l] <= 1;
                                    bitmap[row_idx*COLS + col_r] <= 1;
                                end
                            end
                        end
                    end
                end

                // ---- 기울기 점 모드 (mode==2'b01 또는 2'b10) ----
                if (mode[1:0] != 2'b00) begin
                    begin : dot_draw
                        reg [3:0] dot_col;
                        reg [2:0] dot_row;
                        // X(±512) → 열 0~15, Y(±512) → 행 0~7
                        // x_hold: -512~511 → 0~15 선형 매핑
                        dot_col = x_hold[9:6] + 4'd8;  // 상위 4비트 + 중점 보정
                        dot_row = y_hold[9:7] + 3'd4;  // 상위 3비트 + 중점 보정
                        // 범위 클램프
                        if (dot_col > 4'd15) dot_col = 4'd15;
                        if (dot_row > 3'd7)  dot_row = 3'd7;
                        bitmap[dot_row*COLS + dot_col] <= 1;
                    end
                end

                refresh <= 1;
            end
        end
    end

endmodule
`default_nettype wire
