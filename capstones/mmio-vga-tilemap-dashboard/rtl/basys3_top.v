// basys3_top.v — Basys3 최상위 래퍼
// 100 MHz 입력을 2비트 분주기로 25 MHz로 낮추어 VGA 타이밍과 타일맵 IP에 공급한다.
// 주의: clk_div는 jitter가 크므로 프로덕션에서는 MMCM으로 교체 권장.

module basys3_top (
    input  wire        clk100,       // Basys3 100 MHz 입력 (W5)
    input  wire        cpu_resetn,   // 활성 로우 리셋 (U18)
    // VGA
    output wire        vga_hs,       // 수평 동기
    output wire        vga_vs,       // 수직 동기
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    // AXI4-Lite 슬레이브 — SoC 버스에 연결 (합성 테스트용 더미 포트)
    input  wire [15:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [15:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,
    output wire        irq
);

// 2비트 분주기: 100 MHz → 25 MHz (clk_div[1])
reg [1:0] clk_div;
always @(posedge clk100) clk_div <= clk_div + 2'd1;
wire clk_25m = clk_div[1];
wire rst = !cpu_resetn;

// VGA 타이밍
wire [9:0] h_count, v_count;
wire       hsync, vsync, active, frame_end;

vga_timing u_vga_timing (
    .clk_25m   (clk_25m),
    .rst       (rst),
    .h_count   (h_count),
    .v_count   (v_count),
    .hsync     (hsync),
    .vsync     (vsync),
    .active    (active),
    .frame_end (frame_end)
);

// 타일맵 AXI4-Lite IP
wire [3:0] pix_r, pix_g, pix_b;

tilemap_axil u_tilemap (
    .clk            (clk_25m),
    .rst_n          (!rst),
    .s_axil_awaddr  (s_axil_awaddr),
    .s_axil_awvalid (s_axil_awvalid),
    .s_axil_awready (s_axil_awready),
    .s_axil_wdata   (s_axil_wdata),
    .s_axil_wstrb   (s_axil_wstrb),
    .s_axil_wvalid  (s_axil_wvalid),
    .s_axil_wready  (s_axil_wready),
    .s_axil_bresp   (s_axil_bresp),
    .s_axil_bvalid  (s_axil_bvalid),
    .s_axil_bready  (s_axil_bready),
    .s_axil_araddr  (s_axil_araddr),
    .s_axil_arvalid (s_axil_arvalid),
    .s_axil_arready (s_axil_arready),
    .s_axil_rdata   (s_axil_rdata),
    .s_axil_rresp   (s_axil_rresp),
    .s_axil_rvalid  (s_axil_rvalid),
    .s_axil_rready  (s_axil_rready),
    .h_count        (h_count),
    .v_count        (v_count),
    .active         (active),
    .frame_end      (frame_end),
    .pix_r          (pix_r),
    .pix_g          (pix_g),
    .pix_b          (pix_b),
    .irq            (irq)
);

// VGA 출력 등록 (타이밍 개선)
reg [3:0] vga_r_r, vga_g_r, vga_b_r;
reg       vga_hs_r, vga_vs_r;
always @(posedge clk_25m) begin
    vga_r_r  <= pix_r;
    vga_g_r  <= pix_g;
    vga_b_r  <= pix_b;
    vga_hs_r <= hsync;
    vga_vs_r <= vsync;
end

assign vga_r  = vga_r_r;
assign vga_g  = vga_g_r;
assign vga_b  = vga_b_r;
assign vga_hs = vga_hs_r;
assign vga_vs = vga_vs_r;

endmodule
