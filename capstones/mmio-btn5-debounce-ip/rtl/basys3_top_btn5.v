// basys3_top_btn5.v — Basys3 보드 최상위 래퍼 for axil_btn5
// Verilog-2001. No external IP.
// Copyright (c) 2026 jungbw92@gmail.com — original source for mmio-btn5-debounce-ip

`default_nettype none
`timescale 1ns/1ps

module basys3_top_btn5 (
    input  wire        clk,       // 100 MHz Basys3 W5
    input  wire        btnC,      // active-high 리셋 (및 btn[4] 모니터)
    input  wire        btnU,      // btn[3]
    input  wire        btnD,      // btn[2]
    input  wire        btnL,      // btn[1]
    input  wire        btnR,      // btn[0]
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
    // IRQ 출력 (MicroBlaze V 인터럽트 컨트롤러로)
    output wire        irq,
    // 상태 LED
    output wire [3:0]  led
);

// 버튼 묶음: [4]=BTNC, [3]=BTNU, [2]=BTND, [1]=BTNL, [0]=BTNR
wire [4:0] btn_in = {btnC, btnU, btnD, btnL, btnR};

// 리셋: btnC (active-high)
wire rst = btnC;

// IRQ 디버그 LED
assign led[0] = irq;         // IRQ 발생 중
assign led[3:1] = 3'b000;    // 미사용

axil_btn5 #(
    .CLK_MHZ    (100),
    .DEB_MS_DEF (5),
    .LP_MS_DEF  (1000)
) u_btn5 (
    .clk              (clk),
    .rst              (rst),
    .btn_in           (btn_in),
    .irq              (irq),
    .s_axil_awvalid   (s_axil_awvalid),
    .s_axil_awready   (s_axil_awready),
    .s_axil_awaddr    (s_axil_awaddr),
    .s_axil_wvalid    (s_axil_wvalid),
    .s_axil_wready    (s_axil_wready),
    .s_axil_wdata     (s_axil_wdata),
    .s_axil_wstrb     (s_axil_wstrb),
    .s_axil_bvalid    (s_axil_bvalid),
    .s_axil_bready    (s_axil_bready),
    .s_axil_bresp     (s_axil_bresp),
    .s_axil_arvalid   (s_axil_arvalid),
    .s_axil_arready   (s_axil_arready),
    .s_axil_araddr    (s_axil_araddr),
    .s_axil_rvalid    (s_axil_rvalid),
    .s_axil_rready    (s_axil_rready),
    .s_axil_rdata     (s_axil_rdata),
    .s_axil_rresp     (s_axil_rresp)
);

endmodule
`default_nettype wire
