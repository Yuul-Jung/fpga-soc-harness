// basys3_top_7seg.v
// Basys3 Board Top Wrapper for AXI4-Lite 7-Segment Advanced IP
// HARNESS: mmio-7seg-adv-ip (I-072)
// License: MIT
//
// AXI4-Lite loopback (write then read) for simulation and board smoke test.
// In a real SoC the master connections go to MicroBlaze V's M_AXI bus.
//
// Basys3 pin mapping:
//   clk      : W5  (100 MHz)
//   resetn   : T17 (btnC, active-HIGH → inverted internally)
//   an[3:0]  : U2  W4  V4  U4   (7-seg anodes, active-low)
//   seg[6:0] : W7  W6  U8  V8  U5  V5  U7   (CA..CG, active-low)
//   dp_out   : V7  (DP, active-low)
//
// Verilog-2001 only: compatible with iverilog, verilator, yosys

`timescale 1ns/1ps

module basys3_top_7seg (
    input  wire        clk,       // 100 MHz board clock
    input  wire        btnC,      // Centre button = active-HIGH reset
    // 7-segment outputs (active-low)
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);

    // Active-low reset for AXI
    wire aresetn = ~btnC;

    // ---------------------------------------------------------------
    // AXI4-Lite wires (loopback master stubs for standalone test)
    // All tied to sensible idle values so the IP powers up showing
    // the reset state: en=1, blank=0xF (all off), ready for DATA write.
    // ---------------------------------------------------------------
    wire [7:0]  awaddr  = 8'h00;
    wire        awvalid = 1'b0;
    wire [31:0] wdata   = 32'h0;
    wire [3:0]  wstrb   = 4'h0;
    wire        wvalid  = 1'b0;
    wire        bready  = 1'b1;
    wire [7:0]  araddr  = 8'h00;
    wire        arvalid = 1'b0;
    wire        rready  = 1'b1;

    axil_7seg_ip #(
        .CLK_HZ    (100_000_000),
        .REFRESH_HZ(1000)
    ) u_7seg (
        .aclk    (clk),
        .aresetn (aresetn),
        // Write address
        .awaddr  (awaddr),
        .awvalid (awvalid),
        .awready (),
        // Write data
        .wdata   (wdata),
        .wstrb   (wstrb),
        .wvalid  (wvalid),
        .wready  (),
        // Write response
        .bresp   (),
        .bvalid  (),
        .bready  (bready),
        // Read address
        .araddr  (araddr),
        .arvalid (arvalid),
        .arready (),
        // Read data
        .rdata   (),
        .rresp   (),
        .rvalid  (),
        .rready  (rready),
        // Display
        .an      (an),
        .seg     (seg),
        .dp_out  (dp)
    );

endmodule
