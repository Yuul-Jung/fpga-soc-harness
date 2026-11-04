// basys3_top.v — Basys3 보드 래퍼 (Verilog-2001)
// 하네스 직접 작성 원본.
//
// Basys3 (XC7A35T-1CPG236C) 핀 매핑:
//   CLK_100   : W5  (100MHz 온보드 클럭)
//   BTNC      : U18 (리셋, 액티브 하이)
//   PS2_CLK   : C17 (USB HID PS/2 에뮬레이션)
//   PS2_DATA  : B17
//   SW[15:0]  : V17,V16,W16,W17,W15,V15,W14,W13,V2,T3,T2,R3,W2,U1,T1,R2
//   LED[15:0] : U16,E19,U19,V19,W18,U15,U14,V14,V13,V3,W3,U3,P3,N3,P1,L1
//   UART_TXD  : A18 (USB UART TX)
`timescale 1ns/1ps
module basys3_top (
    input  wire        CLK_100,
    input  wire        BTNC,
    // PS/2
    input  wire        PS2_CLK,
    input  wire        PS2_DATA,
    // GPIO
    input  wire [15:0] SW,
    output wire [15:0] LED,
    // UART
    output wire        UART_TXD
);
    soc_top #(
        .CLK_HZ (100_000_000)
    ) u_soc (
        .clk         (CLK_100),
        .rst         (BTNC),
        .ps2_clk_in  (PS2_CLK),
        .ps2_data_in (PS2_DATA),
        .sw          (SW),
        .led         (LED),
        .txd         (UART_TXD)
    );
endmodule
