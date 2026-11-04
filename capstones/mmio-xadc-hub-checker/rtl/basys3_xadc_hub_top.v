// basys3_xadc_hub_top.v
// Basys3 최상위 래퍼: JXADC 핀 연결, 클럭·리셋, LED 상태 표시
// JXADC 핀: VAUXP/N[4]=JA1/2, [5]=JA3/4, [12]=JB1/2, [13]=JB3/4 (xdc 기준)

module basys3_xadc_hub_top (
    input  wire        clk,        // 100 MHz 온보드 클럭 (W5)
    input  wire        btnC,       // 중앙 버튼 = 리셋 (T17)

    // JXADC 아날로그 입력 (Pmod JA/JB 헤더 아날로그 쌍)
    input  wire        vauxp4,     // JA1 - VAUXP[4]
    input  wire        vauxn4,     // JA2 - VAUXN[4]
    input  wire        vauxp5,     // JA3 - VAUXP[5]
    input  wire        vauxn5,     // JA4 - VAUXN[5]
    input  wire        vauxp12,    // JB1 - VAUXP[12]
    input  wire        vauxn12,    // JB2 - VAUXN[12]
    input  wire        vauxp13,    // JB3 - VAUXP[13]
    input  wire        vauxn13,    // JB4 - VAUXN[13]

    // LED (LD0~LD15)
    output wire [15:0] led
);

    // 리셋: btnC 액티브 하이
    wire rst = btnC;

    // SoC 출력
    wire [3:0] led_pass;
    wire       led_busy;
    wire       led_irq;

    // ============================================================
    // SoC 코어
    // ============================================================
    xadc_hub_soc u_soc (
        .clk     (clk),
        .rst     (rst),
        .vauxp4  (vauxp4),  .vauxn4  (vauxn4),
        .vauxp5  (vauxp5),  .vauxn5  (vauxn5),
        .vauxp12 (vauxp12), .vauxn12 (vauxn12),
        .vauxp13 (vauxp13), .vauxn13 (vauxn13),
        .led_pass(led_pass),
        .led_busy(led_busy),
        .led_irq (led_irq)
    );

    // LED 배치:
    //  LD[3:0]  = 채널별 통과 (led_pass)
    //  LD4      = 버스 busy
    //  LD5      = IRQ
    //  LD[15:6] = 0
    assign led = {10'd0, led_irq, led_busy, led_pass};

endmodule
