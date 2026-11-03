// soc_top.v — SoC 코어 최상위
// 마스터 포트(CPU 교체 지점)를 밖으로 노출하고, MMIO 버스로 슬레이브 4개를 연결한다.
// enc_a, enc_b: 직교 엔코더 입력 (보드 Pmod 또는 시뮬레이션 주입)
`timescale 1ns/1ps
module soc_top (
    input  wire        clk,
    input  wire        rst,
    // 마스터 포트 (CPU 또는 테스트벤치가 연결)
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output wire [31:0] m_rdata,
    output wire        m_ready,
    // GPIO
    input  wire [15:0] sw,
    output wire [15:0] led,
    // UART TX
    output wire        txd,
    // PWM 출력
    output wire        pwm0,
    output wire        pwm1,
    output wire        pwm_irq,
    // 직교 엔코더 입력
    input  wire        enc_a,
    input  wire        enc_b,
    output wire        qdec_irq
);
    // 슬레이브 선택 신호
    wire        sel_gpio, sel_uart, sel_pwm, sel_qdec;

    // 슬레이브 읽기 데이터
    wire [31:0] rdata_gpio, rdata_uart, rdata_pwm, rdata_qdec;

    // 오프셋 (addr[15:0])
    wire [15:0] off = m_addr[15:0];

    // MMIO 버스 디코더
    mmio_bus u_bus (
        .valid      (m_valid),
        .we         (m_we),
        .addr       (m_addr),
        .wdata      (m_wdata),
        .sel_gpio   (sel_gpio),
        .sel_uart   (sel_uart),
        .sel_pwm    (sel_pwm),
        .sel_qdec   (sel_qdec),
        .rdata_gpio (rdata_gpio),
        .rdata_uart (rdata_uart),
        .rdata_pwm  (rdata_pwm),
        .rdata_qdec (rdata_qdec),
        .rdata      (m_rdata),
        .ready      (m_ready)
    );

    // GPIO
    gpio u_gpio (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_gpio),
        .we    (m_we),
        .off   (off),
        .wdata (m_wdata),
        .rdata (rdata_gpio),
        .sw    (sw),
        .led   (led)
    );

    // UART TX
    uart_tx #(
        .CLK_HZ (100_000_000),
        .BAUD   (115200)
    ) u_uart (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_uart),
        .we    (m_we),
        .off   (off),
        .wdata (m_wdata),
        .rdata (rdata_uart),
        .txd   (txd)
    );

    // PWM IP
    pwm_ip u_pwm (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_pwm),
        .we    (m_we),
        .off   (off),
        .wdata (m_wdata),
        .rdata (rdata_pwm),
        .pwm0  (pwm0),
        .pwm1  (pwm1),
        .irq   (pwm_irq)
    );

    // QDEC IP
    qenc_ip u_qdec (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_qdec),
        .we    (m_we),
        .off   (off),
        .wdata (m_wdata),
        .rdata (rdata_qdec),
        .a_in  (enc_a),
        .b_in  (enc_b),
        .irq   (qdec_irq)
    );
endmodule
