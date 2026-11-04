// soc_top.v — SoC 코어. MMIO 버스와 슬레이브 3개를 연결
// 마스터 포트를 밖으로 노출해 CPU 교체 지점으로 둔다.

`default_nettype none

module soc_top (
    input  wire        clk,
    input  wire        rst,

    // 마스터 버스 포트 (CPU 또는 demo_master 연결)
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output wire [31:0] m_rdata,
    output wire        m_ready,

    // 외부 I/O — GPIO
    output wire [15:0] led,
    input  wire [15:0] sw,

    // 외부 I/O — UART
    output wire        uart_tx_pin,

    // 외부 I/O — Motor Safety IP
    input  wire        oc_fault_i,
    output wire        pwm_ah_o,
    output wire        pwm_al_o,
    output wire        pwm_bh_o,
    output wire        pwm_bl_o,
    output wire        irq_oc_o
);

    // 버스 신호
    wire [31:0] gpio_rdata, uart_rdata, safety_rdata;

    wire s0_valid, s1_valid, s2_valid;
    wire s0_we,    s1_we,    s2_we;
    wire [31:0] s0_addr,  s1_addr,  s2_addr;
    wire [31:0] s0_wdata, s1_wdata, s2_wdata;

    // ---- MMIO 버스 디코더 -----------------------------------------------
    mmio_bus bus_i (
        .m_valid  (m_valid),  .m_we    (m_we),
        .m_addr   (m_addr),   .m_wdata (m_wdata),
        .m_rdata  (m_rdata),  .m_ready (m_ready),

        .s0_valid (s0_valid), .s0_we   (s0_we),
        .s0_addr  (s0_addr),  .s0_wdata(s0_wdata), .s0_rdata(gpio_rdata),

        .s1_valid (s1_valid), .s1_we   (s1_we),
        .s1_addr  (s1_addr),  .s1_wdata(s1_wdata), .s1_rdata(uart_rdata),

        .s2_valid (s2_valid), .s2_we   (s2_we),
        .s2_addr  (s2_addr),  .s2_wdata(s2_wdata), .s2_rdata(safety_rdata)
    );

    // ---- GPIO -----------------------------------------------------------
    gpio gpio_i (
        .clk   (clk),   .rst   (rst),
        .valid (s0_valid), .we  (s0_we),
        .addr  (s0_addr),  .wdata(s0_wdata), .rdata(gpio_rdata),
        .led   (led),   .sw    (sw)
    );

    // ---- UART TX --------------------------------------------------------
    uart_tx uart_i (
        .clk   (clk),   .rst   (rst),
        .valid (s1_valid), .we  (s1_we),
        .addr  (s1_addr),  .wdata(s1_wdata), .rdata(uart_rdata),
        .tx    (uart_tx_pin)
    );

    // ---- Motor Safety IP ------------------------------------------------
    motor_safety_ip safety_i (
        .clk       (clk),     .rst      (rst),
        .valid     (s2_valid), .we      (s2_we),
        .addr      (s2_addr),  .wdata   (s2_wdata), .rdata(safety_rdata),
        .oc_fault_i(oc_fault_i),
        .pwm_ah_o  (pwm_ah_o), .pwm_al_o(pwm_al_o),
        .pwm_bh_o  (pwm_bh_o), .pwm_bl_o(pwm_bl_o),
        .irq_o     (irq_oc_o)
    );

endmodule

`default_nettype wire
