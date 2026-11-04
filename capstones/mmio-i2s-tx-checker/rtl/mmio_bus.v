// mmio_bus.v — MMIO 주소 디코더 (64KB 창, addr[31:16] 기준)
// 창 크기를 64KB로 키워 i2s_tx의 0xFFF0~FFFC(mgmt 레지스터)에 접근 가능하게 한다.
// sel_X: addr[31:16]으로 슬레이브 선택
// addr[15:0]: 슬레이브 내 오프셋으로 그대로 전달
`timescale 1ns/1ps
module mmio_bus (
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    // 슬레이브 선택
    output wire        sel_gpio,
    output wire        sel_uart,
    output wire        sel_i2s,
    // 슬레이브 읽기 데이터
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_uart,
    input  wire [31:0] rdata_i2s,
    // 마스터 읽기 데이터
    output reg  [31:0] rdata,
    output wire        ready
);
    assign sel_gpio = valid && (addr[31:16] == 16'h1000);
    assign sel_uart = valid && (addr[31:16] == 16'h1001);
    assign sel_i2s  = valid && (addr[31:16] == 16'h1002);
    assign ready    = 1'b1; // 모든 접근은 1사이클

    always @* begin
        if      (sel_gpio) rdata = rdata_gpio;
        else if (sel_uart) rdata = rdata_uart;
        else if (sel_i2s)  rdata = rdata_i2s;
        else               rdata = 32'h0000_0000;
    end
endmodule
