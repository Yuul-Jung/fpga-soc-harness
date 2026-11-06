// basys3_top.v — Basys3 최상위 래퍼
// 캡스톤: mmio-vga-doublebuf-ip  (2026-11-06)
// 100MHz 입력 → 25MHz 픽셀 클럭 (2비트 분주, clk_div[1])
// 단일 클럭 도메인 단순화 (실 MicroBlaze V 연결 시 CDC 필요)
// Verilog-2001

`default_nettype none
`timescale 1ns/1ps

module basys3_top (
    input  wire        clk100,       // W5: 100MHz 온보드 오실레이터
    input  wire        cpu_resetn,   // U18: active-low 푸시버튼

    // AXI4-Lite 슬레이브 포트 (MicroBlaze V 연결 지점)
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [13:0] s_axi_awaddr,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    output wire [1:0]  s_axi_bresp,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    input  wire [13:0] s_axi_araddr,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,

    // VGA 출력
    output wire        vga_hs,
    output wire        vga_vs,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b
);

// ---- 클럭 분주: 100MHz → 25MHz ----
reg [1:0] clk_div;
always @(posedge clk100) clk_div <= clk_div + 2'd1;
wire clk_25m = clk_div[1];

// ---- 리셋 동기화 (2단 플립플롭) ----
reg rst_meta, rst_sync;
always @(posedge clk_25m) begin
    rst_meta <= ~cpu_resetn;
    rst_sync <= rst_meta;
end
wire rst_n = ~rst_sync;

// ---- IP 인스턴스 ----
vga_doublebuf u_ip (
    .clk             (clk_25m),
    .rst_n           (rst_n),
    .s_axi_awvalid   (s_axi_awvalid),
    .s_axi_awready   (s_axi_awready),
    .s_axi_awaddr    (s_axi_awaddr),
    .s_axi_wvalid    (s_axi_wvalid),
    .s_axi_wready    (s_axi_wready),
    .s_axi_wdata     (s_axi_wdata),
    .s_axi_wstrb     (s_axi_wstrb),
    .s_axi_bvalid    (s_axi_bvalid),
    .s_axi_bready    (s_axi_bready),
    .s_axi_bresp     (s_axi_bresp),
    .s_axi_arvalid   (s_axi_arvalid),
    .s_axi_arready   (s_axi_arready),
    .s_axi_araddr    (s_axi_araddr),
    .s_axi_rvalid    (s_axi_rvalid),
    .s_axi_rready    (s_axi_rready),
    .s_axi_rdata     (s_axi_rdata),
    .s_axi_rresp     (s_axi_rresp),
    .vga_hs          (vga_hs),
    .vga_vs          (vga_vs),
    .vga_r           (vga_r),
    .vga_g           (vga_g),
    .vga_b           (vga_b)
);

endmodule
`default_nettype wire
