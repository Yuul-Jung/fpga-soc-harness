// soc_top.v
// SoC 코어 최상위: AXI4-Lite 버스 슬레이브 + 데이터 경로
// CPU 마스터 포트를 외부로 노출해 CPU 교체 지점으로 사용.
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module led_matrix_sound_tilt_soc (
    input  wire clk,
    input  wire rst_n,

    // AXI4-Lite 마스터 포트 (CPU 연결)
    input  wire [11:0] m_awaddr,
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    input  wire        m_wvalid,
    output wire        m_wready,
    output wire [1:0]  m_bresp,
    output wire        m_bvalid,
    input  wire        m_bready,
    input  wire [11:0] m_araddr,
    input  wire        m_arvalid,
    output wire        m_arready,
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,
    output wire        m_rvalid,
    input  wire        m_rready,

    // PDM 마이크 포트
    output wire pdm_clk_out,
    input  wire pdm_data_in,

    // ADXL345 SPI
    output wire adxl_sclk,
    output wire adxl_mosi,
    input  wire adxl_miso,
    output wire adxl_cs_n,

    // MAX7219 SPI
    output wire max_sclk,
    output wire max_mosi,
    output wire max_cs_n,

    // 디버그 상태
    output wire ip_busy
);
    // 내부 제어 신호
    wire [1:0]  mode;
    wire [3:0]  bright;
    wire        ctrl_en, soft_rst, pdm_clk_en, adxl_en;

    // 에너지 (8대역)
    wire [8*32-1:0] energy_flat;
    wire            energy_update;
    wire [31:0] e0,e1,e2,e3,e4,e5,e6,e7;

    // PDM/PCM
    wire [15:0] pcm_data;
    wire        pcm_valid;

    // ADXL 기울기
    wire signed [9:0] x_tilt, y_tilt;
    wire              adxl_valid;

    // 프레임 버퍼
    wire [8*16-1:0] bitmap;
    wire             bitmap_refresh;

    // MAX7219 busy
    wire max_busy;

    // 복합 리셋 신호 — synth -flatten 후 yosys proc_dff가 복합 negedge를
    // 단일 신호의 negedge로 인식할 수 있도록 명시적 wire로 분리한다.
    wire pdm_rst_n  = rst_n & pdm_clk_en;
    wire iir_rst_n  = rst_n & ctrl_en;
    wire adxl_rst_n = rst_n & adxl_en;

    // 에너지 언팩
    assign e0 = energy_flat[0*32+:32];
    assign e1 = energy_flat[1*32+:32];
    assign e2 = energy_flat[2*32+:32];
    assign e3 = energy_flat[3*32+:32];
    assign e4 = energy_flat[4*32+:32];
    assign e5 = energy_flat[5*32+:32];
    assign e6 = energy_flat[6*32+:32];
    assign e7 = energy_flat[7*32+:32];

    assign ip_busy = max_busy;

    // AXI4-Lite 슬레이브
    axil_led_matrix_slave #(.ADDR_W(12), .DATA_W(32)) u_axil (
        .clk(clk), .rst_n(rst_n),
        .s_awaddr(m_awaddr), .s_awvalid(m_awvalid), .s_awready(m_awready),
        .s_wdata(m_wdata),   .s_wstrb(m_wstrb),     .s_wvalid(m_wvalid),   .s_wready(m_wready),
        .s_bresp(m_bresp),   .s_bvalid(m_bvalid),   .s_bready(m_bready),
        .s_araddr(m_araddr), .s_arvalid(m_arvalid), .s_arready(m_arready),
        .s_rdata(m_rdata),   .s_rresp(m_rresp),     .s_rvalid(m_rvalid),   .s_rready(m_rready),
        .ctrl_mode(mode),   .ctrl_bright(bright),
        .ctrl_en(ctrl_en),  .ctrl_soft_rst(soft_rst),
        .ctrl_pdm_clk_en(pdm_clk_en), .ctrl_adxl_en(adxl_en),
        .pdm_valid(pcm_valid), .adxl_valid_in(adxl_valid), .iir_busy(1'b0),
        .energy0(e0), .energy1(e1), .energy2(e2), .energy3(e3),
        .energy4(e4), .energy5(e5), .energy6(e6), .energy7(e7),
        .x_tilt_in(x_tilt), .y_tilt_in(y_tilt)
    );

    // PDM CIC 데시메이터
    pdm_cic_decimator #(.R(41), .STAGES(3), .OUT_W(16)) u_pdm (
        .clk(clk), .rst_n(pdm_rst_n),
        .pdm_clk(pdm_clk_out),
        .pdm_data(pdm_data_in),
        .pcm_out(pcm_data), .pcm_valid(pcm_valid)
    );

    // IIR 대역 에너지
    iir_band_energy #(.N_BANDS(8), .PCM_W(16), .ENERGY_W(32), .WINDOW(128)) u_iir (
        .clk(clk), .rst_n(iir_rst_n),
        .pcm_in(pcm_data), .pcm_valid(pcm_valid),
        .energy_flat(energy_flat), .energy_update(energy_update)
    );

    // ADXL345 SPI 판독기
    adxl345_spi_reader #(.CLK_DIV(50)) u_adxl (
        .clk(clk), .rst_n(adxl_rst_n),
        .spi_sclk(adxl_sclk), .spi_mosi(adxl_mosi),
        .spi_miso(adxl_miso), .spi_cs_n(adxl_cs_n),
        .x_tilt(x_tilt), .y_tilt(y_tilt), .data_valid(adxl_valid)
    );

    // 프레임 버퍼
    frame_buf #(.N_BANDS(8), .ENERGY_W(32), .COLS(16), .ROWS(8)) u_frame (
        .clk(clk), .rst_n(rst_n),
        .energy_flat(energy_flat), .energy_update(energy_update),
        .x_tilt(x_tilt), .y_tilt(y_tilt), .adxl_valid(adxl_valid),
        .mode(mode), .bright(bright), .soft_rst(soft_rst),
        .bitmap(bitmap), .refresh(bitmap_refresh)
    );

    // MAX7219 체인 드라이버
    max7219_chain_driver #(.CLK_DIV(16), .N_CHIPS(2), .ROWS(8)) u_max (
        .clk(clk), .rst_n(rst_n),
        .bitmap(bitmap), .refresh(bitmap_refresh), .bright(bright),
        .spi_clk(max_sclk), .spi_mosi(max_mosi), .spi_cs_n(max_cs_n),
        .busy(max_busy)
    );

endmodule
`default_nettype wire
