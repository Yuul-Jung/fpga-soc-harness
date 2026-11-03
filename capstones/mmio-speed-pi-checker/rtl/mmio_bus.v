// mmio_bus.v — MMIO-lite 주소 디코더 (3 슬레이브)
// GPIO=0x1000_xxxx, UART=0x1001_xxxx, SPEED_PI=0x1002_xxxx
`timescale 1ns/1ps
module mmio_bus (
    input  wire        clk,
    input  wire        rst,
    // 마스터 포트
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output reg  [31:0] m_rdata,
    output wire        m_ready,
    // GPIO 슬레이브
    output wire        sel_gpio,
    output wire [15:0] gpio_off,
    input  wire [31:0] gpio_rdata,
    // UART 슬레이브
    output wire        sel_uart,
    output wire [15:0] uart_off,
    input  wire [31:0] uart_rdata,
    // SPEED_PI 슬레이브
    output wire        sel_speed_pi,
    output wire [15:0] speed_pi_off,
    input  wire [31:0] speed_pi_rdata
);
    assign sel_gpio     = m_valid && (m_addr[31:16] == 16'h1000);
    assign sel_uart     = m_valid && (m_addr[31:16] == 16'h1001);
    assign sel_speed_pi = m_valid && (m_addr[31:16] == 16'h1002);

    assign gpio_off     = m_addr[15:0];
    assign uart_off     = m_addr[15:0];
    assign speed_pi_off = m_addr[15:0];

    assign m_ready = 1'b1;

    always @(*) begin
        if (sel_gpio)
            m_rdata = gpio_rdata;
        else if (sel_uart)
            m_rdata = uart_rdata;
        else if (sel_speed_pi)
            m_rdata = speed_pi_rdata;
        else
            m_rdata = 32'd0;
    end
endmodule
