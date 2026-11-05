// Basys3 top-level wrapper for axilite_regfile IP
// slug: mmio-axilite-regfile-ip
// Harness original.
//
// Provides:
//   - 100 MHz system clock (W5)
//   - btnC active-high -> aresetn active-low reset
//   - AXI4-Lite master loopback (tied idle, no transactions)
//   - LED[0] = ip2intc_irpt (IRQ indicator)
//
// In a full MicroBlaze V system, replace the loopback master wires
// with the actual AXI4-Lite master connections from the interconnect.
//
// Verilog-2001. iverilog/verilator/yosys compatible.

`default_nettype none
`timescale 1ns/1ps

module basys3_top_regfile (
    input  wire        clk,    // W5, 100 MHz oscillator
    input  wire        btnC,   // U18, centre push-button: active-high reset
    output wire [15:0] led
);

    wire aclk    = clk;
    wire aresetn = !btnC;      // active-low, released when button not pressed

    // AXI4-Lite loopback wires
    wire [3:0]  awaddr;
    wire [2:0]  awprot;
    wire        awvalid;
    wire        awready;
    wire [31:0] wdata;
    wire [3:0]  wstrb;
    wire        wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    wire        bready;
    wire [3:0]  araddr;
    wire [2:0]  arprot;
    wire        arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    wire        rready;
    wire        irpt;

    // Tie-off: AXI4-Lite master idle (no transactions in loopback mode)
    assign awaddr  = 4'h0;
    assign awprot  = 3'b000;
    assign awvalid = 1'b0;
    assign wdata   = 32'h0000_0000;
    assign wstrb   = 4'hF;
    assign wvalid  = 1'b0;
    assign bready  = 1'b1;
    assign araddr  = 4'h0;
    assign arprot  = 3'b000;
    assign arvalid = 1'b0;
    assign rready  = 1'b1;

    axilite_regfile #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(4)
    ) u_regfile (
        .s_axi_aclk    (aclk),
        .s_axi_aresetn (aresetn),
        .s_axi_awaddr  (awaddr),
        .s_axi_awprot  (awprot),
        .s_axi_awvalid (awvalid),
        .s_axi_awready (awready),
        .s_axi_wdata   (wdata),
        .s_axi_wstrb   (wstrb),
        .s_axi_wvalid  (wvalid),
        .s_axi_wready  (wready),
        .s_axi_bresp   (bresp),
        .s_axi_bvalid  (bvalid),
        .s_axi_bready  (bready),
        .s_axi_araddr  (araddr),
        .s_axi_arprot  (arprot),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),
        .s_axi_rdata   (rdata),
        .s_axi_rresp   (rresp),
        .s_axi_rvalid  (rvalid),
        .s_axi_rready  (rready),
        .ip2intc_irpt  (irpt)
    );

    // LED[0]: IRQ status indicator
    // LED[15:1]: unused (held low)
    assign led[0]    = irpt;
    assign led[15:1] = 15'h0000;

    // Suppress unused output warnings from loopback wires
    // verilator lint_off UNUSED
    wire _unused = &{awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid};
    // verilator lint_on UNUSED

endmodule
`default_nettype wire
