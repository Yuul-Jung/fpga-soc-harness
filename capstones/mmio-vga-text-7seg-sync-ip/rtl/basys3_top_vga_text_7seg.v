// basys3_top_vga_text_7seg.v
// Basys3 최상위 래퍼 — mmio-vga-text-7seg-sync-ip
// 보드: Basys3 (XC7A35T-1CPG236C)
// 클럭: 100MHz W5 → 25MHz (4분주) → axil_vga_text_7seg_ip
// AXI4-Lite: 외부에서 직접 주입 (SoC 연결 테스트용)
// 언어: Verilog-2001

`default_nettype none
`timescale 1ns/1ps

module basys3_top_vga_text_7seg (
    input  wire        clk_100mhz,   // W5
    input  wire        cpu_resetn,   // U18 (LOW=리셋)

    // AXI4-Lite (SoC 버스에서 연결)
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [7:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // VGA (JA Pmod B 또는 보드 직결 커넥터)
    output wire        vga_hsync,    // P19
    output wire        vga_vsync,    // R19
    output wire [3:0]  vga_r,        // [N19,J19,H19,G19]
    output wire [3:0]  vga_g,        // [J17,H17,G17,D17]
    output wire [3:0]  vga_b,        // [N18,L18,K18,J18]

    // 7세그먼트
    output wire [6:0]  seg,          // CA~CG
    output wire        dp,           // 소수점 (미사용, 항상 1)
    output wire [3:0]  an            // 자리 선택
);

// ─────────────────────────────────────────────
// 1. 클럭 분주 (100MHz → 25MHz)
// ─────────────────────────────────────────────
reg [1:0] clk_div;
reg       clk_25m;

always @(posedge clk_100mhz or posedge rst) begin
    if (rst) begin
        clk_div <= 2'd0;
        clk_25m <= 1'b0;
    end else begin
        clk_div <= clk_div + 2'd1;
        if (clk_div == 2'd1)
            clk_25m <= ~clk_25m;
    end
end

// ─────────────────────────────────────────────
// 2. 리셋 동기화
// ─────────────────────────────────────────────
wire rst = ~cpu_resetn;
reg  rst_sync1, rst_sync2;
always @(posedge clk_25m or posedge rst) begin
    if (rst) begin
        rst_sync1 <= 1'b1;
        rst_sync2 <= 1'b1;
    end else begin
        rst_sync1 <= 1'b0;
        rst_sync2 <= rst_sync1;
    end
end
wire rst_n_25m = ~rst_sync2;

// ─────────────────────────────────────────────
// 3. IP 인스턴스
// ─────────────────────────────────────────────
wire [6:0] seg_int;

axil_vga_text_7seg_ip u_ip (
    .clk             (clk_25m),
    .rst_n           (rst_n_25m),

    .s_axil_awaddr   (s_axil_awaddr),
    .s_axil_awvalid  (s_axil_awvalid),
    .s_axil_awready  (s_axil_awready),
    .s_axil_wdata    (s_axil_wdata),
    .s_axil_wstrb    (s_axil_wstrb),
    .s_axil_wvalid   (s_axil_wvalid),
    .s_axil_wready   (s_axil_wready),
    .s_axil_bresp    (s_axil_bresp),
    .s_axil_bvalid   (s_axil_bvalid),
    .s_axil_bready   (s_axil_bready),
    .s_axil_araddr   (s_axil_araddr),
    .s_axil_arvalid  (s_axil_arvalid),
    .s_axil_arready  (s_axil_arready),
    .s_axil_rdata    (s_axil_rdata),
    .s_axil_rresp    (s_axil_rresp),
    .s_axil_rvalid   (s_axil_rvalid),
    .s_axil_rready   (s_axil_rready),

    .vga_hsync       (vga_hsync),
    .vga_vsync       (vga_vsync),
    .vga_r           (vga_r),
    .vga_g           (vga_g),
    .vga_b           (vga_b),

    .seg             (seg_int),
    .an              (an)
);

assign seg = seg_int;
assign dp  = 1'b1; // 소수점 미사용

endmodule
`default_nettype wire
