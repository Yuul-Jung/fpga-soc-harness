// basys3_top.v — Basys3 보드 최상위 래퍼
// 클럭 버퍼, 리셋(btnC active-high), LED/SW, JA Pmod PWM 출력,
// JB[0] 과전류 입력, UART TX

`default_nettype none

module basys3_top (
    input  wire        clk,         // 100 MHz 보드 클럭
    input  wire        btnC,        // 리셋 (active-high)

    // LED / SW
    output wire [15:0] led,
    input  wire [15:0] sw,

    // UART
    output wire        uart_txd_in, // USB-UART TX 핀

    // JA Pmod — PWM 출력
    output wire        ja0,         // AH
    output wire        ja1,         // AL
    output wire        ja2,         // BH
    output wire        ja3,         // BL

    // JB Pmod — 과전류 입력 (외부 전류 센서 비교기 출력)
    input  wire        jb0          // oc_fault (active-high)
);

    wire clk_buf;

    // 클럭 버퍼 (IBUF)
    IBUF clk_ibuf (
        .I (clk),
        .O (clk_buf)
    );

    wire [31:0] m_rdata;
    wire        m_ready;

    // demo_master → SoC 버스 연결
    wire        m_valid, m_we;
    wire [31:0] m_addr, m_wdata;

    demo_master dm_i (
        .clk     (clk_buf),
        .rst     (btnC),
        .m_valid (m_valid),
        .m_we    (m_we),
        .m_addr  (m_addr),
        .m_wdata (m_wdata),
        .m_rdata (m_rdata),
        .m_ready (m_ready)
    );

    soc_top soc_i (
        .clk         (clk_buf),
        .rst         (btnC),
        .m_valid     (m_valid),
        .m_we        (m_we),
        .m_addr      (m_addr),
        .m_wdata     (m_wdata),
        .m_rdata     (m_rdata),
        .m_ready     (m_ready),
        .led         (led),
        .sw          (sw),
        .uart_tx_pin (uart_txd_in),
        .oc_fault_i  (jb0),
        .pwm_ah_o    (ja0),
        .pwm_al_o    (ja1),
        .pwm_bh_o    (ja2),
        .pwm_bl_o    (ja3),
        .irq_oc_o    ()
    );

endmodule

`default_nettype wire
