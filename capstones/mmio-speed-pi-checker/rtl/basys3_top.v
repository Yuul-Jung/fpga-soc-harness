// basys3_top.v — Basys3 보드 최상위 래퍼
// clk 100 MHz, rst = btnC(active high), demo_master + soc_top
`timescale 1ns/1ps
module basys3_top (
    input  wire        clk,
    input  wire        btnC,     // 리셋 버튼
    // GPIO
    output wire [15:0] led,
    input  wire [15:0] sw,
    // UART
    output wire        uart_tx_pin,
    // 엔코더 (Pmod JA 핀)
    input  wire        enc_a,
    input  wire        enc_b,
    // PWM 출력 (Pmod JB 핀)
    output wire        pwm_out
);
    wire rst = btnC;

    // 마스터 포트 (demo_master → soc_top)
    wire        m_valid, m_we;
    wire [31:0] m_addr, m_wdata, m_rdata;
    wire        m_ready;

    demo_master master_inst (
        .clk   (clk),
        .rst   (rst),
        .valid (m_valid),
        .we    (m_we),
        .addr  (m_addr),
        .wdata (m_wdata),
        .rdata (m_rdata),
        .ready (m_ready)
    );

    soc_top #(
        .WINDOW_CYCLES (1_000_000)   // 10 ms @ 100 MHz (합성용)
    ) soc_inst (
        .clk         (clk),
        .rst         (rst),
        .m_valid     (m_valid),
        .m_we        (m_we),
        .m_addr      (m_addr),
        .m_wdata     (m_wdata),
        .m_rdata     (m_rdata),
        .m_ready     (m_ready),
        .led         (led),
        .sw          (sw),
        .uart_tx_pin (uart_tx_pin),
        .enc_a       (enc_a),
        .enc_b       (enc_b),
        .pwm_out     (pwm_out)
    );
endmodule
