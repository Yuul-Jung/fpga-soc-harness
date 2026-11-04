// basys3_top.v — Basys3 보드 최상위 래퍼
// clk: 100 MHz 보드 클럭, btnC: 리셋(active high)
// demo_master가 PWM을 초기화하고, pwm0 → LED[0]으로 가시화
`timescale 1ns/1ps
module basys3_top (
    input  wire        clk,
    input  wire        btnC,     // 리셋 (active high)
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire        uart_txd,
    // PWM 출력 (Pmod JA 핀 등으로 연결 가능)
    output wire        pwm0_out,
    output wire        pwm1_out,
    // 직교 엔코더 (Pmod JB)
    input  wire        enc_a,
    input  wire        enc_b
);
    wire rst = btnC;

    // 데모 마스터 버스 신호
    wire        m_valid, m_we;
    wire [31:0] m_addr, m_wdata, m_rdata;
    wire        m_ready;

    // PWM IRQ, QDEC IRQ (보드에서는 미연결)
    wire        pwm_irq, qdec_irq;

    // 데모 마스터
    demo_master u_master (
        .clk   (clk),
        .rst   (rst),
        .valid (m_valid),
        .we    (m_we),
        .addr  (m_addr),
        .wdata (m_wdata),
        .rdata (m_rdata),
        .ready (m_ready)
    );

    // SoC 코어
    soc_top u_soc (
        .clk      (clk),
        .rst      (rst),
        .m_valid  (m_valid),
        .m_we     (m_we),
        .m_addr   (m_addr),
        .m_wdata  (m_wdata),
        .m_rdata  (m_rdata),
        .m_ready  (m_ready),
        .sw       (sw),
        .led      (led),
        .txd      (uart_txd),
        .pwm0     (pwm0_out),
        .pwm1     (pwm1_out),
        .pwm_irq  (pwm_irq),
        .enc_a    (enc_a),
        .enc_b    (enc_b),
        .qdec_irq (qdec_irq)
    );
endmodule
