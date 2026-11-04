// basys3_xadc_top.v
// Basys3 최상위: axil_xadc_hub + Xilinx XADC 프리미티브 래퍼
// Vivado 전용. iverilog/verilator/yosys lint/sim/synth 대상에서 제외.
// XADC 프리미티브는 Sequential 채널 시퀀서 모드 사용.
`default_nettype none
`timescale 1ns/1ps

module basys3_xadc_top (
    input  wire        aclk,       // 100 MHz (W5)
    input  wire        aresetn,    // 액티브 로우 리셋 (btnC = U18, 반전 사용)
    // AXI4-Lite (MicroBlaze V 연결)
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    // JXADC 차동 아날로그 입력 (전압 분배기 필수: 최대 0.77 V)
    input  wire        JXADC_P0,   // VAUX0P (JXADC 핀 1)
    input  wire        JXADC_N0,   // VAUX0N (JXADC 핀 7)
    input  wire        JXADC_P1,   // VAUX1P (JXADC 핀 2)
    input  wire        JXADC_N1,   // VAUX1N (JXADC 핀 8)
    input  wire        JXADC_P4,   // VAUX8P (JXADC 핀 3)
    input  wire        JXADC_N4,   // VAUX8N (JXADC 핀 9)
    input  wire        JXADC_P5,   // VAUX9P (JXADC 핀 4)
    input  wire        JXADC_N5,   // VAUX9N (JXADC 핀 10)
    // 인터럽트
    output wire        irq
);

    // DRP 내부 연결선
    wire        drp_den, drp_dwe, drp_drdy;
    wire  [6:0] drp_daddr;
    wire [15:0] drp_di, drp_do;

    // -----------------------------------------------------------------------
    // axil_xadc_hub 인스턴스
    // -----------------------------------------------------------------------
    axil_xadc_hub #(
        .BASE_ADDR(32'h4009_0000)
    ) u_hub (
        .s_axi_aclk    (aclk),
        .s_axi_aresetn (aresetn),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .drp_den       (drp_den),
        .drp_dwe       (drp_dwe),
        .drp_daddr     (drp_daddr),
        .drp_di        (drp_di),
        .drp_do        (drp_do),
        .drp_drdy      (drp_drdy),
        .irq           (irq)
    );

    // -----------------------------------------------------------------------
    // Xilinx XADC 프리미티브 (Sequential 채널 시퀀서)
    // 참고: UG480 "7 Series FPGAs and Zynq-7000 SoC XADC Dual 12-Bit 1 MSPS ADC"
    // -----------------------------------------------------------------------
    wire [15:0] vauxp = {6'h0, JXADC_P5, JXADC_P4, 6'h0, JXADC_P1, JXADC_P0};
    wire [15:0] vauxn = {6'h0, JXADC_N5, JXADC_N4, 6'h0, JXADC_N1, JXADC_N0};

    XADC #(
        .INIT_40 (16'h9000),  // 채널 시퀀서 모드 (Sequential)
        .INIT_41 (16'h2ef0),  // 온도·전압 연속 모드 비활성화
        .INIT_42 (16'h0400),  // ADC A 사용, 클럭 분주 4 (100 MHz / 4 = 25 MHz)
        .INIT_48 (16'h0303),  // 시퀀서: VAUX0·1·8·9 활성화
        .INIT_49 (16'h0303),  // 시퀀서 평균 비활성화 (DRP FSM이 담당)
        .INIT_4A (16'h0000),
        .INIT_4B (16'h0000),
        .INIT_4C (16'h0000),
        .INIT_4D (16'h0000),
        .INIT_4E (16'h0000),
        .INIT_4F (16'h0000),
        .INIT_50 (16'hb5ed),  // 온도 경보 임계값 (기본)
        .INIT_51 (16'h57e4),
        .INIT_52 (16'ha147),
        .INIT_53 (16'hca33),
        .INIT_54 (16'ha93a),
        .INIT_55 (16'h52c6),
        .INIT_56 (16'h9555),
        .INIT_57 (16'hae4e),
        .INIT_58 (16'h5999),
        .INIT_5C (16'h5111),
        .SIM_DEVICE       ("7SERIES"),
        .SIM_MONITOR_FILE ("design.txt")
    ) u_xadc (
        .DCLK    (aclk),
        .RESET   (~aresetn),
        .DEN     (drp_den),
        .DWE     (drp_dwe),
        .DADDR   (drp_daddr),
        .DI      (drp_di),
        .DO      (drp_do),
        .DRDY    (drp_drdy),
        .VAUXP   (vauxp),
        .VAUXN   (vauxn),
        .VP      (1'b0),
        .VN      (1'b0),
        .BUSY    (),
        .CHANNEL (),
        .EOC     (),
        .EOS     (),
        .JTAGBUSY(),
        .JTAGLOCKED(),
        .JTAGMODIFIED(),
        .OT      (),
        .ALM     ()
    );

endmodule
`default_nettype wire
