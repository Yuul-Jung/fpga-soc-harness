// soc_top.v — SoC 코어. MMIO 버스와 슬레이브 3개를 연결
// 마스터 포트를 밖으로 노출(CPU 교체 지점)
`timescale 1ns/1ps
module soc_top #(
    parameter WINDOW_CYCLES = 1_000_000
) (
    input  wire        clk,
    input  wire        rst,
    // 마스터 포트 (CPU 또는 테스트벤치가 연결)
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output wire [31:0] m_rdata,
    output wire        m_ready,
    // 보드 I/O — GPIO
    output wire [15:0] led,
    input  wire [15:0] sw,
    // 보드 I/O — UART
    output wire        uart_tx_pin,
    // 보드 I/O — 엔코더 / PWM
    input  wire        enc_a,
    input  wire        enc_b,
    output wire        pwm_out
);
    // --- 버스 슬레이브 신호 ---
    wire        sel_gpio, sel_uart, sel_speed_pi;
    wire [15:0] gpio_off, uart_off, speed_pi_off;
    wire [31:0] gpio_rdata, uart_rdata, speed_pi_rdata;

    mmio_bus bus_inst (
        .clk            (clk),
        .rst            (rst),
        .m_valid        (m_valid),
        .m_we           (m_we),
        .m_addr         (m_addr),
        .m_wdata        (m_wdata),
        .m_rdata        (m_rdata),
        .m_ready        (m_ready),
        .sel_gpio       (sel_gpio),
        .gpio_off       (gpio_off),
        .gpio_rdata     (gpio_rdata),
        .sel_uart       (sel_uart),
        .uart_off       (uart_off),
        .uart_rdata     (uart_rdata),
        .sel_speed_pi   (sel_speed_pi),
        .speed_pi_off   (speed_pi_off),
        .speed_pi_rdata (speed_pi_rdata)
    );

    gpio gpio_inst (
        .clk   (clk),
        .rst   (rst),
        .valid (sel_gpio),
        .we    (m_we),
        .off   (gpio_off),
        .wdata (m_wdata),
        .rdata (gpio_rdata),
        .led   (led),
        .sw    (sw)
    );

    uart_tx uart_inst (
        .clk   (clk),
        .rst   (rst),
        .valid (sel_uart),
        .we    (m_we),
        .off   (uart_off),
        .wdata (m_wdata),
        .rdata (uart_rdata),
        .tx    (uart_tx_pin)
    );

    speed_pi_ip #(
        .WINDOW_CYCLES (WINDOW_CYCLES)
    ) speed_pi_inst (
        .clk     (clk),
        .rst     (rst),
        .valid   (sel_speed_pi),
        .we      (m_we),
        .off     (speed_pi_off),
        .wdata   (m_wdata),
        .rdata   (speed_pi_rdata),
        .enc_a   (enc_a),
        .enc_b   (enc_b),
        .pwm_out (pwm_out)
    );
endmodule
