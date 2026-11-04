// mmio_bus.v — MMIO 주소 디코더 (64KB 창, addr[31:16] 기준)
// 하네스 직접 작성 원본.
// addr[31:16] 기준으로 슬레이브를 선택하고, addr[15:0]을 오프셋으로 전달한다.
//
// 슬롯 (mmio-lite 버스, 동결 맵과 별도):
//   0x1000_xxxx : GPIO  (LED, SW)
//   0x1001_xxxx : UART TX
//   0x1002_xxxx : PS2_KBD  (동결 맵: 0x400B_0000)
`timescale 1ns/1ps
module mmio_bus (
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    // 슬레이브 선택
    output wire        sel_gpio,
    output wire        sel_uart,
    output wire        sel_kbd,
    // 슬레이브 읽기 데이터
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_uart,
    input  wire [31:0] rdata_kbd,
    // 마스터 읽기 데이터
    output reg  [31:0] rdata,
    output wire        ready
);
    assign sel_gpio = valid && (addr[31:16] == 16'h1000);
    assign sel_uart = valid && (addr[31:16] == 16'h1001);
    assign sel_kbd  = valid && (addr[31:16] == 16'h1002);
    assign ready    = 1'b1; // 모든 접근 1사이클

    always @* begin
        if      (sel_gpio) rdata = rdata_gpio;
        else if (sel_uart) rdata = rdata_uart;
        else if (sel_kbd)  rdata = rdata_kbd;
        else               rdata = 32'h0000_0000;
    end

    // verilator lint_off UNUSED
    wire [31:0] _unused_wdata = wdata;
    // verilator lint_on UNUSED
endmodule
