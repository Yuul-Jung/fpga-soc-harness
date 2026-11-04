// basys3_top.v — Basys3 보드 최상위 래퍼 (mmio-pid-step-capture)
// 클럭 버퍼, 리셋 버튼(btnC=active-high), LED/SW/BTN, 엔코더 핀, PWM 출력
// Verilog-2001
`default_nettype none

module basys3_top (
    input  wire        clk,       // 100 MHz 온보드 클럭
    input  wire        btnC,      // 리셋 버튼 (active high)
    input  wire [15:0] sw,        // 슬라이드 스위치
    output wire [15:0] led,       // LED
    input  wire [3:0]  btn,       // 푸시 버튼 U/D/L/R (btnC 제외)
    input  wire        enc_a,     // 엔코더 A 채널
    input  wire        enc_b,     // 엔코더 B 채널
    output wire        pwm_out,   // PWM 모터 드라이브 출력
    output wire        uart_txd   // UART TX
);

    wire clk_buf;

    // 클럭 버퍼 (IBUFG 대신 단순 연결: 합성 도구가 자동 삽입)
    assign clk_buf = clk;

    soc_top u_soc (
        .clk      (clk_buf),
        .rst      (btnC),
        .sw       (sw),
        .led      (led),
        .btn      (btn),
        .enc_a    (enc_a),
        .enc_b    (enc_b),
        .pwm_out  (pwm_out),
        .uart_txd (uart_txd)
    );

endmodule
`default_nettype wire
