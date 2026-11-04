// mmio_bus.v — 32비트 MMIO 주소 디코더 (단일 사이클 버스)
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 세그먼트:
//   0x1000_0000 ~ 0x1000_FFFF → GPIO
//   0x1001_0000 ~ 0x1001_FFFF → UART
//   0x1002_0000 ~ 0x1002_FFFF → Sensor Hub

`timescale 1ns/1ps
module mmio_bus (
    // 마스터 → 버스
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    // 버스 → 마스터
    output reg  [31:0] rdata,
    // 슬레이브 sel / rdata
    output wire        sel_gpio,
    output wire        sel_uart,
    output wire        sel_hub,
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_uart,
    input  wire [31:0] rdata_hub
);

    assign sel_gpio = (addr[31:16] == 16'h1000);
    assign sel_uart = (addr[31:16] == 16'h1001);
    assign sel_hub  = (addr[31:16] == 16'h1002);

    always @(*) begin
        if      (sel_gpio) rdata = rdata_gpio;
        else if (sel_uart) rdata = rdata_uart;
        else if (sel_hub)  rdata = rdata_hub;
        else               rdata = 32'hDEAD_BEEF;
    end

endmodule
