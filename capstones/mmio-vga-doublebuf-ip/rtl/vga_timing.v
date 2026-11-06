// vga_timing.v — 640×480@60Hz VGA 타이밍 생성기
// 출처: capstones/mmio-vga-tilemap-dashboard/rtl/vga_timing.v (동일 파일, 귀속 유지)
// 원본 경로: library/rtl/vga_timing.v 계열
// 수정: 없음 (그대로 복사, Verilog-2001)

`default_nettype none
`timescale 1ns/1ps

module vga_timing (
    input  wire       clk_25m,
    input  wire       rst,       // 동기 리셋, active-high
    output reg  [9:0] h_count,
    output reg  [9:0] v_count,
    output reg        hsync,
    output reg        vsync,
    output reg        active,
    output reg        frame_end
);

// 640×480@60Hz (25.175 MHz 기준, 25 MHz로 근사)
// H: visible 640 + fp 16 + sync 96 + bp 48 = 800
// V: visible 480 + fp 10 + sync 2  + bp 33 = 525
localparam H_VIS  = 640, H_FP  = 16, H_SYNC = 96, H_BP  = 48;
localparam V_VIS  = 480, V_FP  = 10, V_SYNC = 2,  V_BP  = 33;
localparam H_TOTAL = H_VIS + H_FP + H_SYNC + H_BP; // 800
localparam V_TOTAL = V_VIS + V_FP + V_SYNC + V_BP; // 525

always @(posedge clk_25m) begin
    if (rst) begin
        h_count  <= 10'd0;
        v_count  <= 10'd0;
        hsync    <= 1'b1;
        vsync    <= 1'b1;
        active   <= 1'b0;
        frame_end<= 1'b0;
    end else begin
        frame_end <= 1'b0;
        if (h_count == H_TOTAL - 1) begin
            h_count <= 10'd0;
            if (v_count == V_TOTAL - 1) begin
                v_count   <= 10'd0;
                frame_end <= 1'b1;
            end else begin
                v_count <= v_count + 10'd1;
            end
        end else begin
            h_count <= h_count + 10'd1;
        end

        // hsync: active-low, pixels H_VIS+H_FP .. H_VIS+H_FP+H_SYNC-1
        hsync <= ~((h_count >= H_VIS + H_FP) && (h_count < H_VIS + H_FP + H_SYNC));
        // vsync: active-low, lines V_VIS+V_FP .. V_VIS+V_FP+V_SYNC-1
        vsync <= ~((v_count >= V_VIS + V_FP) && (v_count < V_VIS + V_FP + V_SYNC));
        // active: visible area
        active <= (h_count < H_VIS) && (v_count < V_VIS);
    end
end

endmodule
`default_nettype wire
