`timescale 1ns/1ps
// soc_top.v — 최소 SoC: AXI4-Lite 버스 + ble_trilat_ip 슬롯
// 슬롯 [16] = 0x4016_0000 (mbv-frozen-v2 free_slots)
// 마스터 포트를 밖으로 노출해 CPU 교체 지점을 열어 둔다.
`default_nettype none
module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    // AXI4-Lite 마스터 포트 (CPU 또는 demo_master 연결)
    input  wire [31:0] m_awaddr,
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    input  wire        m_wvalid,
    output wire        m_wready,
    output wire [1:0]  m_bresp,
    output wire        m_bvalid,
    input  wire        m_bready,
    input  wire [31:0] m_araddr,
    input  wire        m_arvalid,
    output wire        m_arready,
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,
    output wire        m_rvalid,
    input  wire        m_rready,
    // 주변장치 핀
    input  wire        ble_uart_rx,
    output wire        ble_irq
);
    // ── 슬롯 디코드: 주소 [27:16]으로 슬롯 선택 ───────────────────
    // 슬롯 [16] = 0x4016_0000 → addr[27:16] = 12'h016
    localparam [11:0] SLOT_BLE = 12'h016;

    wire sel_ble_w = (m_awaddr[27:16] == SLOT_BLE);
    wire sel_ble_r = (m_araddr[27:16] == SLOT_BLE);

    // ── ble_trilat_ip ──────────────────────────────────────────────
    ble_trilat_ip u_ble (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        .s_axi_awaddr  (m_awaddr),
        .s_axi_awvalid (m_awvalid && sel_ble_w),
        .s_axi_awready (m_awready),
        .s_axi_wdata   (m_wdata),
        .s_axi_wstrb   (m_wstrb),
        .s_axi_wvalid  (m_wvalid  && sel_ble_w),
        .s_axi_wready  (m_wready),
        .s_axi_bresp   (m_bresp),
        .s_axi_bvalid  (m_bvalid),
        .s_axi_bready  (m_bready),
        .s_axi_araddr  (m_araddr),
        .s_axi_arvalid (m_arvalid && sel_ble_r),
        .s_axi_arready (m_arready),
        .s_axi_rdata   (m_rdata),
        .s_axi_rresp   (m_rresp),
        .s_axi_rvalid  (m_rvalid),
        .s_axi_rready  (m_rready),
        .uart_rx       (ble_uart_rx),
        .irq           (ble_irq)
    );

endmodule
`default_nettype wire
