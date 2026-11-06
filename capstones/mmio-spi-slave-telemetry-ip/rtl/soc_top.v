// soc_top.v — SoC 코어 최상위 (CPU 없이 AXI4-Lite 버스 마스터 포트만 노출)
// 테스트벤치가 AXI4-Lite 마스터로 직접 연결한다.
// 원본: capstones/mmio-spi-slave-telemetry-ip/rtl/soc_top.v

`timescale 1ns/1ps
`default_nettype none

module soc_top (
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    // AXI4-Lite 마스터 포트 (CPU 교체 지점)
    output wire [7:0]  m_axi_awaddr,
    output wire        m_axi_awvalid,
    input  wire        m_axi_awready,

    output wire [31:0] m_axi_wdata,
    output wire [3:0]  m_axi_wstrb,
    output wire        m_axi_wvalid,
    input  wire        m_axi_wready,

    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output wire        m_axi_bready,

    output wire [7:0]  m_axi_araddr,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,

    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output wire        m_axi_rready,

    // SPI 슬레이브 패스스루
    input  wire        spi_sclk,
    input  wire        spi_mosi,
    output wire        spi_miso,
    input  wire        spi_cs_n
);

    // AXI4-Lite SPI 슬레이브 IP 인스턴스
    axil_spi_slave #(
        .BASE_ADDR  (32'h401A_0000),
        .FIFO_DEPTH (4)
    ) u_spi_slave (
        .s_axi_aclk    (sys_clk),
        .s_axi_aresetn (sys_rst_n),

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

        .spi_sclk      (spi_sclk),
        .spi_mosi      (spi_mosi),
        .spi_miso      (spi_miso),
        .spi_cs_n      (spi_cs_n)
    );

endmodule

`default_nettype wire
