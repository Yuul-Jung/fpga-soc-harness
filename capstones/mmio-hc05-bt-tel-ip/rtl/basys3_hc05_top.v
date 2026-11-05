`timescale 1ns/1ps
// basys3_hc05_top.v — Basys3 보드 래퍼
// HC-05 BT 텔레메트리 브리지 IP 최상위 모듈
// AXI4-Lite 마스터 포트를 외부로 노출해 CPU 교체 지점으로 둔다.
// 핀 배정 (예시): Pmod JA1=TX, JA2=RX, JA3=EN, JA4=STATE
`default_nettype none
module basys3_hc05_top (
    // 보드 클럭 · 리셋
    input  wire        clk100,
    input  wire        btnC,         // 중앙 버튼 = 리셋 (active-high)

    // AXI4-Lite 마스터 포트 (CPU 연결용)
    input  wire [31:0] m_axi_awaddr,
    input  wire        m_axi_awvalid,
    output wire        m_axi_awready,
    input  wire [31:0] m_axi_wdata,
    input  wire [3:0]  m_axi_wstrb,
    input  wire        m_axi_wvalid,
    output wire        m_axi_wready,
    output wire [1:0]  m_axi_bresp,
    output wire        m_axi_bvalid,
    input  wire        m_axi_bready,
    input  wire [31:0] m_axi_araddr,
    input  wire        m_axi_arvalid,
    output wire        m_axi_arready,
    output wire [31:0] m_axi_rdata,
    output wire [1:0]  m_axi_rresp,
    output wire        m_axi_rvalid,
    input  wire        m_axi_rready,

    // IRQ
    output wire        irq,

    // Pmod JA
    output wire        ja_tx,        // JA1 → HC-05 RX
    input  wire        ja_rx,        // JA2 ← HC-05 TX
    output wire        ja_en,        // JA3 → HC-05 EN
    input  wire        ja_state      // JA4 ← HC-05 STATE
);
    wire rst_n = ~btnC;

    axil_hc05_bt #(.BAUD_DIV(10417)) u_ip (
        .s_axi_aclk    (clk100),
        .s_axi_aresetn (rst_n),
        .s_axi_awaddr  (m_axi_awaddr),
        .s_axi_awvalid (m_axi_awvalid),
        .s_axi_awready (m_axi_awready),
        .s_axi_wdata   (m_axi_wdata),
        .s_axi_wstrb   (m_axi_wstrb),
        .s_axi_wvalid  (m_axi_wvalid),
        .s_axi_wready  (m_axi_wready),
        .s_axi_bresp   (m_axi_bresp),
        .s_axi_bvalid  (m_axi_bvalid),
        .s_axi_bready  (m_axi_bready),
        .s_axi_araddr  (m_axi_araddr),
        .s_axi_arvalid (m_axi_arvalid),
        .s_axi_arready (m_axi_arready),
        .s_axi_rdata   (m_axi_rdata),
        .s_axi_rresp   (m_axi_rresp),
        .s_axi_rvalid  (m_axi_rvalid),
        .s_axi_rready  (m_axi_rready),
        .uart_tx_pin   (ja_tx),
        .uart_rx_pin   (ja_rx),
        .bt_en         (ja_en),
        .bt_state      (ja_state),
        .irq           (irq)
    );

endmodule
`default_nettype wire
