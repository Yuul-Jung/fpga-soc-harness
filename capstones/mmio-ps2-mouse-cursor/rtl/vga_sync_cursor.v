// vga_sync_cursor.v
// VGA 640×480 60Hz 타이밍 생성 + 5×5 픽셀 커서 오버레이
// 프레임 버퍼 없는 경량 구현 (BRAM 미사용)
// Verilog-2001. iverilog/verilator/yosys 호환.
// 원작자: 하네스 자체 작성 (2026-11-04)

`default_nettype none

module vga_sync_cursor (
    input  wire        clk,         // 100 MHz 시스템 클럭
    input  wire        rst,

    // 커서 위치 및 활성화
    input  wire [9:0]  cursor_x,    // 0~639
    input  wire [9:0]  cursor_y,    // 0~479
    input  wire        cursor_en,

    // VGA 출력
    output reg         hs,          // HSYNC (active-low)
    output reg         vs,          // VSYNC (active-low)
    output reg  [3:0]  red,
    output reg  [3:0]  green,
    output reg  [3:0]  blue
);

// ─── 픽셀 클럭: 100MHz / 4 = 25MHz ──────────────────────
reg [1:0] clk_div;
wire      pix_clk;

always @(posedge clk or posedge rst) begin
    if (rst) clk_div <= 2'd0;
    else     clk_div <= clk_div + 2'd1;
end
assign pix_clk = (clk_div == 2'd3);

// ─── VGA 타이밍 파라미터 (640×480 @ 60Hz) ────────────────
// 수평: 800 픽셀 클럭 / 라인
//   활성: 0~639 (640)
//   프론트 포치: 640~655 (16)
//   HSYNC: 656~751 (96) [active-low]
//   백 포치: 752~799 (48)
// 수직: 525 라인
//   활성: 0~479 (480)
//   프론트 포치: 480~489 (10)
//   VSYNC: 490~491 (2) [active-low]
//   백 포치: 492~524 (33)

localparam H_TOTAL = 10'd800;
localparam H_SYNC_START = 10'd656;
localparam H_SYNC_END   = 10'd752;

localparam V_TOTAL = 10'd525;
localparam V_SYNC_START = 10'd490;
localparam V_SYNC_END   = 10'd492;

reg [9:0] h_cnt;
reg [9:0] v_cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_cnt <= 10'd0;
        v_cnt <= 10'd0;
    end else if (pix_clk) begin
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 10'd0;
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= 10'd0;
            else
                v_cnt <= v_cnt + 10'd1;
        end else begin
            h_cnt <= h_cnt + 10'd1;
        end
    end
end

// ─── 활성 화면 영역 ──────────────────────────────────────
wire h_active = (h_cnt < 10'd640);
wire v_active = (v_cnt < 10'd480);
wire display  = h_active && v_active;

// ─── 커서 범위 판별 (5×5 박스, 중심 = cursor_x/y) ───────
// 가장자리 클램프: 중심이 2 이하이면 왼쪽 상한을 0으로
wire [9:0] cx_lo = (cursor_x >= 10'd2) ? (cursor_x - 10'd2) : 10'd0;
wire [9:0] cx_hi = (cursor_x <= 10'd637) ? (cursor_x + 10'd2) : 10'd639;
wire [9:0] cy_lo = (cursor_y >= 10'd2) ? (cursor_y - 10'd2) : 10'd0;
wire [9:0] cy_hi = (cursor_y <= 10'd477) ? (cursor_y + 10'd2) : 10'd479;

wire in_cursor_x = (h_cnt >= cx_lo) && (h_cnt <= cx_hi);
wire in_cursor_y = (v_cnt >= cy_lo) && (v_cnt <= cy_hi);
wire in_cursor   = in_cursor_x && in_cursor_y && cursor_en && display;

// ─── 픽셀 출력 (레지스터: pix_clk 사이클에 샘플) ─────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        hs    <= 1'b1;
        vs    <= 1'b1;
        red   <= 4'h0;
        green <= 4'h0;
        blue  <= 4'h0;
    end else if (pix_clk) begin
        // SYNC (active-low)
        hs <= ~((h_cnt >= H_SYNC_START) && (h_cnt < H_SYNC_END));
        vs <= ~((v_cnt >= V_SYNC_START) && (v_cnt < V_SYNC_END));

        // 픽셀 색상
        if (!display) begin
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else if (in_cursor) begin
            // 커서: 흰색
            red   <= 4'hF;
            green <= 4'hF;
            blue  <= 4'hF;
        end else begin
            // 배경: 어두운 파랑
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h2;
        end
    end
end

endmodule
`default_nettype wire
