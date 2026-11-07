// basys3_top_ds3231.v
// Basys3 board wrapper for mmio-ds3231-rtc-eeprom-ip capstone.
// Exposes AXI4-Lite master ports so a CPU (MicroBlaze V or similar)
// can be instantiated at the top of the design hierarchy.
// Verilog-2001. No IP cores.

`default_nettype none
`timescale 1ns/1ps

module basys3_top_ds3231 (
    input  wire clk_100mhz,   // W5 — Basys3 100 MHz oscillator
    input  wire cpu_resetn,   // U18 — active-low reset button

    // I2C Pmod JA (top row): pin1=SCL, pin2=SDA
    inout  wire pmod_ja1_scl, // J1 Pmod JA pin 1
    inout  wire pmod_ja2_sda, // J2 Pmod JA pin 2

    // Status LEDs (LSB = busy, bit1 = ack_err, bit2 = done)
    output wire [2:0] led,

    // -----------------------------------------------------------------
    // AXI4-Lite master port — connect to CPU / AXI interconnect
    // -----------------------------------------------------------------
    // Write address
    output wire [31:0] m_awaddr,
    output wire        m_awvalid,
    input  wire        m_awready,
    // Write data
    output wire [31:0] m_wdata,
    output wire [3:0]  m_wstrb,
    output wire        m_wvalid,
    input  wire        m_wready,
    // Write response
    input  wire [1:0]  m_bresp,
    input  wire        m_bvalid,
    output wire        m_bready,
    // Read address
    output wire [31:0] m_araddr,
    output wire        m_arvalid,
    input  wire        m_arready,
    // Read data
    input  wire [31:0] m_rdata,
    input  wire [1:0]  m_rresp,
    input  wire        m_rvalid,
    output wire        m_rready
);

    wire clk;
    wire resetn;

    // 100 MHz clock buffer (IBUFG equivalent in pure RTL inference)
    // In Vivado synthesis this net is inferred as IBUFG automatically
    assign clk    = clk_100mhz;
    assign resetn = cpu_resetn;

    // -----------------------------------------------------------------
    // I2C open-drain tristate
    // -----------------------------------------------------------------
    wire scl_o, scl_oe, scl_i;
    wire sda_o, sda_oe, sda_i;

    // Pull line low when oe=1, else tristate (external pull-up asserts high)
    assign pmod_ja1_scl = scl_oe ? 1'b0 : 1'bz;
    assign pmod_ja2_sda = sda_oe ? 1'b0 : 1'bz;
    assign scl_i = pmod_ja1_scl;
    assign sda_i = pmod_ja2_sda;

    // -----------------------------------------------------------------
    // I2C IP instance (AXI4-Lite slave)
    // Slave ports connect to the master port outputs of this module
    // so the CPU on the other side drives the AXI bus.
    // -----------------------------------------------------------------
    wire        s_awready_w;
    wire        s_wready_w;
    wire [1:0]  s_bresp_w;
    wire        s_bvalid_w;
    wire        s_ararready_w;
    wire [31:0] s_rdata_w;
    wire [1:0]  s_rresp_w;
    wire        s_rvalid_w;

    axil_i2c_rtc_log #(
        .CLK_HZ      (100_000_000),
        .HALF_PERIOD (250)
    ) u_i2c_ip (
        .s_aclk      (clk),
        .s_aresetn   (resetn),
        // Write addr
        .s_awaddr    (m_awaddr),
        .s_awvalid   (m_awvalid),
        .s_awready   (s_awready_w),
        // Write data
        .s_wdata     (m_wdata),
        .s_wstrb     (m_wstrb),
        .s_wvalid    (m_wvalid),
        .s_wready    (s_wready_w),
        // Write resp
        .s_bresp     (s_bresp_w),
        .s_bvalid    (s_bvalid_w),
        .s_bready    (m_bready),
        // Read addr
        .s_araddr    (m_araddr),
        .s_arvalid   (m_arvalid),
        .s_ararready (s_ararready_w),
        // Read data
        .s_rdata     (s_rdata_w),
        .s_rresp     (s_rresp_w),
        .s_rvalid    (s_rvalid_w),
        .s_rready    (m_rready),
        // I2C
        .scl_o  (scl_o),  .scl_oe (scl_oe),  .scl_i (scl_i),
        .sda_o  (sda_o),  .sda_oe (sda_oe),  .sda_i (sda_i)
    );

    // Connect slave ready/valid back to CPU master
    assign m_awready = s_awready_w;
    assign m_wready  = s_wready_w;
    assign m_bresp   = s_bresp_w;
    assign m_bvalid  = s_bvalid_w;
    assign m_arready = s_ararready_w;
    assign m_rdata   = s_rdata_w;
    assign m_rresp   = s_rresp_w;
    assign m_rvalid  = s_rvalid_w;

    // Status LEDs
    wire busy_r, ack_err_r, done_r;
    assign led[0] = s_bvalid_w;   // proxy: busy approximated by outstanding write resp
    assign led[1] = 1'b0;         // ack_err not exposed externally in this wrapper
    assign led[2] = 1'b0;

endmodule
`default_nettype wire
