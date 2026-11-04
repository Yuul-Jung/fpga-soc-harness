// xadc_hub_soc.v
// SoC 코어: mmio-lite 버스 + demo_master + xadc_hub
// demo_master가 버스 마스터, xadc_hub가 슬레이브

module xadc_hub_soc (
    input  wire        clk,
    input  wire        rst,

    // 보드 아날로그 입력
    input  wire        vauxp4,  vauxn4,
    input  wire        vauxp5,  vauxn5,
    input  wire        vauxp12, vauxn12,
    input  wire        vauxp13, vauxn13,

    // 자체 점검 결과 LED
    output wire [3:0]  led_pass,  // 채널별 통과
    output wire        led_busy,
    output wire        led_irq
);

    // --- mmio-lite 버스 신호 ---
    wire [15:0] bus_addr;
    wire [31:0] bus_wdata;
    wire [31:0] bus_rdata;
    wire        bus_we;
    wire        bus_req;
    wire        bus_ack;

    // --- IRQ ---
    wire        irq;

    // ============================================================
    // 버스 마스터: 자체 점검 FSM
    // ============================================================
    demo_master u_demo (
        .clk      (clk),
        .rst      (rst),
        .addr     (bus_addr),
        .wdata    (bus_wdata),
        .rdata    (bus_rdata),
        .we       (bus_we),
        .req      (bus_req),
        .ack      (bus_ack),
        .irq      (irq),
        .led_pass (led_pass),
        .led_busy (led_busy),
        .led_irq  (led_irq)
    );

    // ============================================================
    // XADC Hub IP (슬레이브)
    // ============================================================
    xadc_hub u_hub (
        .clk     (clk),
        .rst     (rst),
        .addr    (bus_addr),
        .wdata   (bus_wdata),
        .rdata   (bus_rdata),
        .we      (bus_we),
        .req     (bus_req),
        .ack     (bus_ack),
        .vauxp4  (vauxp4),  .vauxn4  (vauxn4),
        .vauxp5  (vauxp5),  .vauxn5  (vauxn5),
        .vauxp12 (vauxp12), .vauxn12 (vauxn12),
        .vauxp13 (vauxp13), .vauxn13 (vauxn13),
        .irq     (irq)
    );

endmodule
