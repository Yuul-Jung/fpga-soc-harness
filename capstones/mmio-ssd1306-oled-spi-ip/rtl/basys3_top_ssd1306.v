// basys3_top_ssd1306.v
// Basys3 보드 래퍼: axil_ssd1306_spi IP 단독 테스트 (CPU 없이 직접 연결)
// 실제 SoC에서는 이 파일 대신 AXI 인터커넥트를 통해 연결한다.
//
// Pmod JA 핀 배치 (Digilent Pmod OLED 기준):
//   JA[0] = CS_N   JA[1] = MOSI  JA[2] = D/C   JA[3] = RES_N
//   JA[4] = VDD_EN JA[5] = VBAT_EN
//   JA[6] = SCK
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module basys3_top_ssd1306 (
    input  wire        clk_100mhz,  // Basys3 100MHz 클럭
    input  wire        reset_btn,   // BTNC (액티브 하이)

    // Pmod JA
    output wire        ja_cs_n,
    output wire        ja_mosi,
    output wire        ja_dc,
    output wire        ja_res_n,
    output wire        ja_vdd_en,
    output wire        ja_vbat_en,
    output wire        ja_sck,

    // 상태 LED (옵션)
    output wire [3:0]  led_debug    // [0]=busy, [1]=init_done, [2]=irq, [3]=미사용
);

    wire rst_n = ~reset_btn;

    // AXI4-Lite 버스 (더미 — CPU 없이 개방)
    wire [31:0] s_awaddr  = 32'h0;
    wire        s_awvalid = 1'b0;
    wire [31:0] s_wdata   = 32'h0;
    wire [3:0]  s_wstrb   = 4'h0;
    wire        s_wvalid  = 1'b0;
    wire        s_bready  = 1'b1;
    wire [31:0] s_araddr  = 32'h0;
    wire        s_arvalid = 1'b0;
    wire        s_rready  = 1'b1;

    wire        spi_sck, spi_mosi, spi_cs_n, spi_dc, spi_res_n;
    wire        spi_vdd_en, spi_vbat_en;
    wire        irq_frame_done;
    wire [1:0]  s_bresp, s_rresp;
    wire        s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
    wire [31:0] s_rdata;

    axil_ssd1306_spi #(
        .SPI_DIV   (10),
        .PWRUP_CNT (100_000),
        .RST_CNT   (300)
    ) u_oled (
        .clk        (clk_100mhz),
        .rst_n      (rst_n),

        .s_awaddr   (s_awaddr),  .s_awvalid (s_awvalid), .s_awready (s_awready),
        .s_wdata    (s_wdata),   .s_wstrb   (s_wstrb),   .s_wvalid  (s_wvalid),
        .s_wready   (s_wready),  .s_bresp   (s_bresp),   .s_bvalid  (s_bvalid),
        .s_bready   (s_bready),

        .s_araddr   (s_araddr),  .s_arvalid (s_arvalid), .s_arready (s_arready),
        .s_rdata    (s_rdata),   .s_rresp   (s_rresp),   .s_rvalid  (s_rvalid),
        .s_rready   (s_rready),

        .spi_sck    (spi_sck),
        .spi_mosi   (spi_mosi),
        .spi_cs_n   (spi_cs_n),
        .spi_dc     (spi_dc),
        .spi_res_n  (spi_res_n),
        .spi_vdd_en (spi_vdd_en),
        .spi_vbat_en(spi_vbat_en),
        .irq        (irq_frame_done)
    );

    // Pmod JA 출력 연결
    assign ja_cs_n    = spi_cs_n;
    assign ja_mosi    = spi_mosi;
    assign ja_dc      = spi_dc;
    assign ja_res_n   = spi_res_n;
    assign ja_vdd_en  = spi_vdd_en;
    assign ja_vbat_en = spi_vbat_en;
    assign ja_sck     = spi_sck;

    // 디버그 LED
    assign led_debug[0] = 1'b0; // busy: STATUS 레지스터에서 읽어야 하나, 여기선 더미
    assign led_debug[1] = 1'b0;
    assign led_debug[2] = irq_frame_done;
    assign led_debug[3] = 1'b0;

endmodule
`default_nettype wire
