// mmio_bus.v — MMIO 주소 디코더 (4개 슬레이브: GPIO/UART/PWM/QDEC)
// addr[31:16] 기준으로 슬레이브 선택
// off = addr[15:0] 그대로 슬레이브에 전달
// ready = 1 사이클 고정 (back-pressure 없음)
`timescale 1ns/1ps
module mmio_bus (
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    // 슬레이브 선택
    output wire        sel_gpio,
    output wire        sel_uart,
    output wire        sel_pwm,
    output wire        sel_qdec,
    // 슬레이브 읽기 데이터
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_uart,
    input  wire [31:0] rdata_pwm,
    input  wire [31:0] rdata_qdec,
    // 마스터 읽기 데이터
    output reg  [31:0] rdata,
    output wire        ready
);
    assign sel_gpio = valid && (addr[31:16] == 16'h1000);
    assign sel_uart = valid && (addr[31:16] == 16'h1001);
    assign sel_pwm  = valid && (addr[31:16] == 16'h1003);
    assign sel_qdec = valid && (addr[31:16] == 16'h1004);
    assign ready    = 1'b1;

    always @* begin
        if      (sel_gpio) rdata = rdata_gpio;
        else if (sel_uart) rdata = rdata_uart;
        else if (sel_pwm)  rdata = rdata_pwm;
        else if (sel_qdec) rdata = rdata_qdec;
        else               rdata = 32'h0000_0000;
    end
endmodule
