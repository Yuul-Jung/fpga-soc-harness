// basys3_top.v — Basys3 (XC7A35T) board wrapper for mmio-spi-dbg-axil-bridge
//
// Pmod JA pin assignments (3.3 V, no level shift needed for RPi GPIO):
//   JA1  → sck   (RPi GPIO 11 / SCLK)
//   JA2  → mosi  (RPi GPIO 10 / MOSI)
//   JA3  → miso  (RPi GPIO 9  / MISO)
//   JA4  → csn   (RPi GPIO 8  / CE0)
//
// For standalone test (without MicroBlaze V), AXI master ports are
// left unconnected; a testbench provides the AXI slave.
//
// Clock: 100 MHz from Basys3 W5 oscillator.
// Reset: btnC (active-high, inverted internally to active-low aresetn).
// Status LED: LD0 = bridge busy.
//
// Verilog-2001 style.

`timescale 1ns / 1ps

module basys3_top (
    input  wire        clk,      // W5  100 MHz
    input  wire        btnC,     // T17 centre button = reset

    // Pmod JA
    input  wire        ja1,      // SCK
    input  wire        ja2,      // MOSI
    output wire        ja3,      // MISO
    input  wire        ja4,      // CSN

    // Status LEDs
    output wire        ld0,      // busy

    // AXI4-Lite master — connects to system in full integration
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
    output wire        m_rready
);

wire aresetn = ~btnC;

soc_top u_soc (
    .aclk       (clk),
    .aresetn    (aresetn),
    // SPI (Pmod JA)
    .sck        (ja1),
    .mosi       (ja2),
    .miso       (ja3),
    .csn        (ja4),
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
    .busy_led   (ld0)
);

endmodule
