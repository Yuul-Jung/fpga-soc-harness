// basys3_top.v — Basys3 보드 래퍼 (mmio-jstk2-servo-ip)
// 하네스 원본 (외부 코드 포함 없음)
// Basys3 XC7A35T, 100 MHz 온보드 클럭
// Pmod JA: JSTK2 SPI (JA1=CS#, JA2=MOSI, JA3=MISO, JA4=SCLK)
// Pmod JB: 서보 (JB1=SERVO_A, JB2=SERVO_B)
`default_nettype none

module basys3_jstk2_servo_top (
    input  wire        clk100mhz,  // 100 MHz 온보드 클럭
    input  wire        btnC,       // 중앙 버튼: 리셋
    // Pmod JA — JSTK2 SPI
    output wire        ja1,        // SPI CS#
    output wire        ja2,        // SPI MOSI
    input  wire        ja3,        // SPI MISO
    output wire        ja4,        // SPI SCLK
    // Pmod JB — 서보 출력
    output wire        jb1,        // 서보 A PWM
    output wire        jb2,        // 서보 B PWM
    // LED 디버그
    output wire [2:0]  led         // led[0]=IRQ, led[1]=BTN1, led[2]=BTN2
);

wire rst_n = ~btnC; // 액티브-로우 리셋

wire irq;
wire [1:0] jstk_btn_dbg; // 디버그용

// AXI4-Lite 버스 (외부 MicroBlaze V에서 들어올 버스, 여기서는 테스트용 연결 없음)
// 실제 SoC 통합 시 MicroBlaze V의 M_AXI_DP에 연결한다
// 이 래퍼는 합성용 최상위이며 AXI 마스터 연결은 블록 디자인에서 수행
wire [31:0] axi_awaddr  = 32'd0;
wire        axi_awvalid = 1'b0;
wire [31:0] axi_wdata   = 32'd0;
wire [3:0]  axi_wstrb   = 4'd0;
wire        axi_wvalid  = 1'b0;
wire        axi_bready  = 1'b1;
wire [31:0] axi_araddr  = 32'd0;
wire        axi_arvalid = 1'b0;
wire        axi_rready  = 1'b1;

jstk2_servo_ip #(
    .CLK_FREQ_HZ      (100_000_000),
    .SPI_CLK_HZ       (  1_000_000),
    .SAMPLE_PERIOD_MS (100)
) u_ip (
    .s_axi_aclk    (clk100mhz),
    .s_axi_aresetn (rst_n),
    .s_axi_awaddr  (axi_awaddr),
    .s_axi_awvalid (axi_awvalid),
    .s_axi_awready (),
    .s_axi_wdata   (axi_wdata),
    .s_axi_wstrb   (axi_wstrb),
    .s_axi_wvalid  (axi_wvalid),
    .s_axi_wready  (),
    .s_axi_bresp   (),
    .s_axi_bvalid  (),
    .s_axi_bready  (axi_bready),
    .s_axi_araddr  (axi_araddr),
    .s_axi_arvalid (axi_arvalid),
    .s_axi_arready (),
    .s_axi_rdata   (),
    .s_axi_rresp   (),
    .s_axi_rvalid  (),
    .s_axi_rready  (axi_rready),
    .irq           (irq),
    .spi_cs_n      (ja1),
    .spi_sclk      (ja4),
    .spi_mosi      (ja2),
    .spi_miso      (ja3),
    .pwm_a         (jb1),
    .pwm_b         (jb2)
);

// LED 디버그 출력
assign led[0] = irq;
assign led[1] = 1'b0; // 버튼 디버그는 IP 내부에서만 접근 가능; 단순화
assign led[2] = 1'b0;

endmodule
`default_nettype wire
