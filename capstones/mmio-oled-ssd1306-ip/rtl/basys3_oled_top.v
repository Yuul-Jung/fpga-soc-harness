// basys3_oled_top.v — Basys3 최상위 래퍼 (axil_oled_ssd1306 + 클럭 버퍼)
// 하네스 원본. 외부 코드 복사 아님.
// 클럭 소스: W5 (100MHz 온보드 클럭)
// Pmod 연결: JB[0]=CS_N, JB[1]=MOSI, JB[2]=SCK, JB[3]=DC, JB[4]=RES_N
`default_nettype none
`timescale 1ns/1ps

module basys3_oled_top (
    input  wire        clk,        // W5 100MHz
    input  wire        cpu_resetn, // 리셋 버튼 (active-low)

    // AXI4-Lite — 외부 MicroBlaze V M_AXI_DP에서 연결
    input  wire [7:0]  s_awaddr,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output wire        s_wready,
    output wire [1:0]  s_bresp,
    output wire        s_bvalid,
    input  wire        s_bready,
    input  wire [7:0]  s_araddr,
    input  wire        s_arvalid,
    output wire        s_arready,
    output wire [31:0] s_rdata,
    output wire [1:0]  s_rresp,
    output wire        s_rvalid,
    input  wire        s_rready,

    // IRQ
    output wire        irq_refresh_done,

    // Pmod JB (SSD1306 SPI)
    output wire        JB0_CS_N,
    output wire        JB1_MOSI,
    output wire        JB2_SCK,
    output wire        JB3_DC,
    output wire        JB4_RES_N
);

    wire rst_n = cpu_resetn;

    // ── OLED IP ──────────────────────────────────────────
    wire oled_sck, oled_mosi, oled_cs_n, oled_dc, oled_res_n;

    axil_oled_ssd1306 #(
        .CLK_DIV (10),   // 100MHz / 20 = 5MHz SCK (SSD1306 max 10MHz)
        .INIT_LEN(24)
    ) u_oled (
        .clk              (clk),
        .rst_n            (rst_n),
        .s_awaddr         (s_awaddr),
        .s_awvalid        (s_awvalid),
        .s_awready        (s_awready),
        .s_wdata          (s_wdata),
        .s_wstrb          (s_wstrb),
        .s_wvalid         (s_wvalid),
        .s_wready         (s_wready),
        .s_bresp          (s_bresp),
        .s_bvalid         (s_bvalid),
        .s_bready         (s_bready),
        .s_araddr         (s_araddr),
        .s_arvalid        (s_arvalid),
        .s_arready        (s_arready),
        .s_rdata          (s_rdata),
        .s_rresp          (s_rresp),
        .s_rvalid         (s_rvalid),
        .s_rready         (s_rready),
        .oled_sck         (oled_sck),
        .oled_mosi        (oled_mosi),
        .oled_cs_n        (oled_cs_n),
        .oled_dc          (oled_dc),
        .oled_res_n       (oled_res_n),
        .irq_refresh_done (irq_refresh_done)
    );

    // ── Pmod JB 핀 연결 ───────────────────────────────────
    assign JB0_CS_N  = oled_cs_n;
    assign JB1_MOSI  = oled_mosi;
    assign JB2_SCK   = oled_sck;
    assign JB3_DC    = oled_dc;
    assign JB4_RES_N = oled_res_n;

endmodule
`default_nettype wire
