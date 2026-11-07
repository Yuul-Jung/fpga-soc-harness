// soc_top.v — SoC-level wrapper for mmio-spi-dbg-axil-bridge
// Instantiates axil_spi_dbg_bridge and exposes its AXI4-Lite master port.
// In a full MicroBlaze V system this master connects to the system AXI
// interconnect, giving RPi (via SPI) read/write access to any peripheral.
//
// Verilog-2001 style.

`timescale 1ns / 1ps

module soc_top (
    input  wire        aclk,
    input  wire        aresetn,

    // SPI slave (from Pmod, via basys3_top)
    input  wire        sck,
    input  wire        mosi,
    output wire        miso,
    input  wire        csn,

    // AXI4-Lite master — connects to system interconnect in full SoC
    output wire [31:0] m_awaddr,
    output wire        m_awvalid,
    input  wire        m_awready,

    output wire [31:0] m_wdata,
    output wire [3:0]  m_wstrb,
    output wire        m_wvalid,
    input  wire        m_wready,

    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output wire        m_bready,

    output wire [31:0] m_araddr,
    output wire        m_arvalid,
    input  wire        m_arready,

    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rvalid,
    output wire        m_rready,

    output wire        busy_led
);

axil_spi_dbg_bridge u_bridge (
    .aclk       (aclk),
    .aresetn    (aresetn),
    // SPI
    .sck        (sck),
    .mosi       (mosi),
    .miso       (miso),
    .csn        (csn),
    // AXI master
    .m_awaddr   (m_awaddr),
    .m_awvalid  (m_awvalid),
    .m_awready  (m_awready),
    .m_wdata    (m_wdata),
    .m_wstrb    (m_wstrb),
    .m_wvalid   (m_wvalid),
    .m_wready   (m_wready),
    .m_bresp    (m_bresp),
    .m_bvalid   (m_bvalid),
    .m_bready   (m_bready),
    .m_araddr   (m_araddr),
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready),
    .busy       (busy_led)
);

endmodule
