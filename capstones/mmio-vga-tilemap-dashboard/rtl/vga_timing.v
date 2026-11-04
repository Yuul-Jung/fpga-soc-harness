// vga_timing.v — 640×480 @ 60 Hz VGA 타이밍 생성기
// 픽셀 클럭: 25 MHz (25.175 MHz 공칭; 2비트 분주기로 25 MHz 사용)
// H: 640 가시 + 16 FP + 96 SYNC + 48 BP = 800
// V: 480 가시 + 10 FP +  2 SYNC + 33 BP = 525
// SYNC 극성: 양쪽 활성 로우 (CEA-861 표준)

module vga_timing (
    input  wire        clk_25m,
    input  wire        rst,
    output reg  [9:0]  h_count,   // 0..799
    output reg  [9:0]  v_count,   // 0..524
    output wire        hsync,     // 활성 로우
    output wire        vsync,     // 활성 로우
    output wire        active,    // 가시 영역
    output wire        frame_end  // vsync 하강 에지(1사이클 펄스)
);

localparam H_VIS  = 640, H_FP = 16, H_SYNC = 96, H_BP = 48;
localparam V_VIS  = 480, V_FP = 10, V_SYNC =  2, V_BP = 33;
localparam H_TOTAL = H_VIS + H_FP + H_SYNC + H_BP; // 800
localparam V_TOTAL = V_VIS + V_FP + V_SYNC + V_BP; // 525

// h/v 카운터
always @(posedge clk_25m) begin
    if (rst) begin
        h_count <= 10'd0;
        v_count <= 10'd0;
    end else begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 10'd0;
            if (v_count == V_TOTAL - 1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 10'd1;
        end else begin
            h_count <= h_count + 10'd1;
        end
    end
end

assign hsync    = ~((h_count >= H_VIS + H_FP) &&
                    (h_count <  H_VIS + H_FP + H_SYNC));
assign vsync    = ~((v_count >= V_VIS + V_FP) &&
                    (v_count <  V_VIS + V_FP + V_SYNC));
assign active   = (h_count < H_VIS) && (v_count < V_VIS);

// frame_end: vsync 하강 에지 = v_count가 V_VIS+V_FP에 도달하고 h_count==0
assign frame_end = (v_count == V_VIS + V_FP) && (h_count == 10'd0);

endmodule
