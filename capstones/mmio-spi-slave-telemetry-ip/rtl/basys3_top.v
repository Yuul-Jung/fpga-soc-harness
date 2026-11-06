// basys3_top.v — Basys3 보드 최상위 래퍼
// Pmod JA 핀: JA[0]=SCLK, JA[1]=MOSI, JA[2]=MISO, JA[3]=CS_N
// 원본: capstones/mmio-spi-slave-telemetry-ip/rtl/basys3_top.v

`timescale 1ns/1ps
`default_nettype none

module basys3_top (
    input  wire        clk,         // 100 MHz 온보드 클럭
    input  wire        btnC,        // 중앙 버튼 — 리셋 (액티브 하이)

    // Pmod JA — SPI 슬레이브 (ESP32 마스터)
    input  wire        ja0,         // JA1 — SCLK
    input  wire        ja1,         // JA2 — MOSI
    output wire        ja2,         // JA3 — MISO
    input  wire        ja3,         // JA4 — CS_N

    // 상태 LED (옵션)
    output wire [3:0]  led
);

    wire sys_rst_n = !btnC;

    // AXI4-Lite 버스 — soc_top 마스터 포트
    wire [7:0]  m_awaddr;
    wire        m_awvalid, m_awready;
    wire [31:0] m_wdata;
    wire [3:0]  m_wstrb;
    wire        m_wvalid, m_wready;
    wire [1:0]  m_bresp;
    wire        m_bvalid, m_bready;
    wire [7:0]  m_araddr;
    wire        m_arvalid, m_arready;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rvalid, m_rready;

    // SPI 신호 풀업 (외부 연결 없을 때)
    // cs_n HIGH → 슬레이브 비선택 상태 유지

    soc_top u_soc (
        .sys_clk     (clk),
        .sys_rst_n   (sys_rst_n),

        .m_axi_awaddr  (m_awaddr),
        .m_axi_awvalid (m_awvalid),
        .m_axi_awready (m_awready),
        .m_axi_wdata   (m_wdata),
        .m_axi_wstrb   (m_wstrb),
        .m_axi_wvalid  (m_wvalid),
        .m_axi_wready  (m_wready),
        .m_axi_bresp   (m_bresp),
        .m_axi_bvalid  (m_bvalid),
        .m_axi_bready  (m_bready),
        .m_axi_araddr  (m_araddr),
        .m_axi_arvalid (m_arvalid),
        .m_axi_arready (m_arready),
        .m_axi_rdata   (m_rdata),
        .m_axi_rresp   (m_rresp),
        .m_axi_rvalid  (m_rvalid),
        .m_axi_rready  (m_rready),

        .spi_sclk  (ja0),
        .spi_mosi  (ja1),
        .spi_miso  (ja2),
        .spi_cs_n  (ja3)
    );

    // 상태 LED: [0]=CS 활성, [1]=RX valid — soc_top의 STATUS 레지스터를 직접 읽지 않고
    // 단순히 Pmod 신호로 가시화 (보드 디버그용)
    assign led[0] = !ja3;       // CS 활성
    assign led[1] = ja0;        // SCLK 토글
    assign led[2] = ja1;        // MOSI
    assign led[3] = sys_rst_n;  // 리셋 상태

endmodule

`default_nettype wire
