// soc_top.v — SoC 코어 (mmio-pid-step-capture)
// MMIO-lite 버스와 슬레이브 3개(GPIO/UART/PID_CAP) 연결
// 마스터 포트를 밖으로 노출(CPU 교체 지점). 이 패키지는 demo_master 사용.
// Verilog-2001
`default_nettype none

module soc_top (
    input  wire        clk,
    input  wire        rst,
    // 보드 I/O
    input  wire [15:0] sw,
    output wire [15:0] led,
    input  wire [3:0]  btn,
    input  wire        enc_a,
    input  wire        enc_b,
    output wire        pwm_out,
    output wire        uart_txd
);

    // MMIO-lite 마스터 포트
    wire        m_valid;
    wire        m_we;
    wire [31:0] m_addr;
    wire [31:0] m_wdata;
    wire [31:0] m_rdata;
    wire        m_ready;

    // 데모 마스터 (합성용 FSM)
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

    // MMIO 버스 디코더
    mmio_bus u_bus (
        .clk        (clk),
        .rst        (rst),
        // 마스터 사이드
        .m_valid    (m_valid),
        .m_we       (m_we),
        .m_addr     (m_addr),
        .m_wdata    (m_wdata),
        .m_rdata    (m_rdata),
        .m_ready    (m_ready),
        // 주변장치 I/O
        .sw         (sw),
        .led        (led),
        .enc_a      (enc_a),
        .enc_b      (enc_b),
        .pwm_out    (pwm_out),
        .uart_txd   (uart_txd)
    );

endmodule
`default_nettype wire
