// basys3_top.v
// Basys3 최상위 래퍼
// Pmod JA: PDM 마이크 (JA1=pdm_clk, JA2=pdm_data)
// Pmod JB: MAX7219 (JB1=CLK, JB2=MOSI, JB3=CS_N)
// Pmod JC: ADXL345 SPI (JC1=SCLK, JC2=MOSI, JC3=MISO, JC4=CS_N)
// CPU 없이 테스트 시 m_* 포트를 외부 테스트벤치에 연결
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module basys3_led_matrix_sound_tilt_top (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,   // 액티브 로우 리셋

    // Pmod JA: PDM 마이크
    output wire        JA1,          // pdm_clk → 마이크
    input  wire        JA2,          // pdm_data ← 마이크

    // Pmod JB: MAX7219 체인
    output wire        JB1,          // SPI CLK
    output wire        JB2,          // SPI MOSI (DIN)
    output wire        JB3,          // SPI CS_N (LOAD)

    // Pmod JC: ADXL345
    output wire        JC1,          // SCLK
    output wire        JC2,          // MOSI
    input  wire        JC3,          // MISO
    output wire        JC4,          // CS_N

    // 디버그: 온보드 LED
    output wire [15:0] LED
);
    wire rst_n = CPU_RESETN;

    // CPU 버스 포트 (테스트 시 pull-down)
    wire [11:0] m_awaddr = 12'b0;
    wire        m_awvalid = 1'b0;
    wire [31:0] m_wdata  = 32'b0;
    wire [3:0]  m_wstrb  = 4'b0;
    wire        m_wvalid = 1'b0;
    wire        m_bready = 1'b1;
    wire [11:0] m_araddr = 12'b0;
    wire        m_arvalid = 1'b0;
    wire        m_rready = 1'b1;
    wire        ip_busy;

    led_matrix_sound_tilt_soc u_soc (
        .clk(CLK100MHZ), .rst_n(rst_n),
        // CPU 포트 (더미)
        .m_awaddr(m_awaddr), .m_awvalid(m_awvalid), .m_awready(),
        .m_wdata(m_wdata),   .m_wstrb(m_wstrb),     .m_wvalid(m_wvalid),   .m_wready(),
        .m_bresp(),          .m_bvalid(),             .m_bready(m_bready),
        .m_araddr(m_araddr), .m_arvalid(m_arvalid),  .m_arready(),
        .m_rdata(),          .m_rresp(),              .m_rvalid(),           .m_rready(m_rready),
        // PDM
        .pdm_clk_out(JA1), .pdm_data_in(JA2),
        // ADXL345
        .adxl_sclk(JC1), .adxl_mosi(JC2), .adxl_miso(JC3), .adxl_cs_n(JC4),
        // MAX7219
        .max_sclk(JB1), .max_mosi(JB2), .max_cs_n(JB3),
        // 디버그
        .ip_busy(ip_busy)
    );

    assign LED[0]    = ip_busy;
    assign LED[15:1] = 15'b0;

endmodule
`default_nettype wire
