// basys3_top_attn1h.v — Basys3 board top wrapper for axil_attn1h
// Verilog-2001. No external IP.
// Copyright (c) 2026 jungbw92@gmail.com — original source for mmio-attn1h-axil-ip

`default_nettype none
`timescale 1ns/1ps

module basys3_top_attn1h (
    input  wire        clk,      // 100 MHz Basys3 oscillator
    input  wire        btnC,     // active-high reset
    // AXI4-Lite (from MicroBlaze V)
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    output wire [1:0]  s_axil_bresp,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    input  wire [7:0]  s_axil_araddr,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    // Status LEDs
    output wire [3:0]  led
);

wire busy_led, done_led;
assign led[0] = busy_led;
assign led[1] = done_led;
assign led[3:2] = 2'b00;

axil_attn1h #(
    .D(8),
    .S(4)
) u_attn1h (
    .clk             (clk),
    .rst             (btnC),
    .s_axil_awvalid  (s_axil_awvalid),
    .s_axil_awready  (s_axil_awready),
    .s_axil_awaddr   (s_axil_awaddr),
    .s_axil_wvalid   (s_axil_wvalid),
    .s_axil_wready   (s_axil_wready),
    .s_axil_wdata    (s_axil_wdata),
    .s_axil_wstrb    (s_axil_wstrb),
    .s_axil_bvalid   (s_axil_bvalid),
    .s_axil_bready   (s_axil_bready),
    .s_axil_bresp    (s_axil_bresp),
    .s_axil_arvalid  (s_axil_arvalid),
    .s_axil_arready  (s_axil_arready),
    .s_axil_araddr   (s_axil_araddr),
    .s_axil_rvalid   (s_axil_rvalid),
    .s_axil_rready   (s_axil_rready),
    .s_axil_rdata    (s_axil_rdata),
    .s_axil_rresp    (s_axil_rresp),
    .busy_led        (busy_led),
    .done_led        (done_led)
);

endmodule
`default_nettype wire
