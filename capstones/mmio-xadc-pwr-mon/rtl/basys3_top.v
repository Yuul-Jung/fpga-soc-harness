// basys3_top.v — mmio-xadc-pwr-mon 최상위 래퍼
// Basys3(XC7A35T) XADC 전원 감시 IP 보드 래퍼.
// SIMULATION 플래그 시 XADC 프리미티브를 모의 모델로 대체한다.
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none
`timescale 1ns/1ps

module basys3_top (
    input  wire        clk,       // W5, 100 MHz
    input  wire        btnC,      // T18, 리셋 (active high)
    output wire [15:0] led        // 상태 표시: [2:0]=viol, [3]=irq, [4]=busy
);

    wire s_axi_aclk    = clk;
    wire s_axi_aresetn = ~btnC;

    // IRQ LED 연결
    wire irq;
    wire [31:0] status_rd;  // STATUS 레지스터 직접 연결은 간략화용

    // AXI4-Lite 버스 (CPU 없는 데모: 모든 쓰기 포트를 0으로 묶음)
    // 이 래퍼는 IP 단독 동작을 보여주며 AXI4-Lite 마스터(MicroBlaze V)는 미포함.
    wire [31:0] s_axi_awaddr  = 32'h0;
    wire        s_axi_awvalid = 1'b0;
    wire [31:0] s_axi_wdata   = 32'h0;
    wire [3:0]  s_axi_wstrb   = 4'h0;
    wire        s_axi_wvalid  = 1'b0;
    wire        s_axi_bready  = 1'b1;
    wire [31:0] s_axi_araddr  = 32'h0;
    wire        s_axi_arvalid = 1'b0;
    wire        s_axi_rready  = 1'b1;

    // DRP 연결
    wire        drp_den;
    wire        drp_dwe;
    wire [6:0]  drp_daddr;
    wire [15:0] drp_di;
    wire [15:0] drp_do;
    wire        drp_drdy;

    // XADC 전원 감시 IP
    xadc_pwr_mon_ip #(
        .BASE_ADDR(32'h4016_0000)
    ) u_pwr_mon (
        .s_axi_aclk    (s_axi_aclk),
        .s_axi_aresetn (s_axi_aresetn),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (),
        .s_axi_bresp   (),
        .s_axi_bvalid  (),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (),
        .s_axi_rdata   (),
        .s_axi_rresp   (),
        .s_axi_rvalid  (),
        .s_axi_rready  (s_axi_rready),
        .drp_den       (drp_den),
        .drp_dwe       (drp_dwe),
        .drp_daddr     (drp_daddr),
        .drp_di        (drp_di),
        .drp_do        (drp_do),
        .drp_drdy      (drp_drdy),
        .irq           (irq)
    );

`ifdef SIMULATION
    // 시뮬레이션 모의 DRP 모델
    xadc_drp_model u_xadc (
        .dclk  (s_axi_aclk),
        .den   (drp_den),
        .dwe   (drp_dwe),
        .daddr (drp_daddr),
        .di    (drp_di),
        .do    (drp_do),
        .drdy  (drp_drdy)
    );
`else
    // 합성 시 Xilinx XADC Wizard IP 또는 XADC 프리미티브 연결
    // 이 래퍼는 보드 테스트 전용 스텁이며 MicroBlaze V 프로젝트에서는
    // u_pwr_mon을 AXI4-Lite 버스에 직접 연결한다.
    XADC #(
        .INIT_40(16'h0000),  // config0: CH=0 (온도), CAVG=0
        .INIT_41(16'h2000),  // config1: 연속 모드, 시퀀서 단일
        .INIT_42(16'h0400),  // config2: 클럭 분주 4(100MHz→25MHz DRP)
        .INIT_48(16'h0001),  // 시퀀서 CH0 (온도; 공급전압은 항상 샘플링)
        .INIT_49(16'h0000),
        .SIM_MONITOR_FILE("xadc_supply.txt")
    ) u_xadc_prim (
        .DCLK     (s_axi_aclk),
        .DEN      (drp_den),
        .DWE      (drp_dwe),
        .DADDR    (drp_daddr),
        .DI       (drp_di),
        .DO       (drp_do),
        .DRDY     (drp_drdy),
        .RESET    (~s_axi_aresetn),
        .CONVST   (1'b0),
        .CONVSTCLK(1'b0),
        .VP       (1'b0),
        .VN       (1'b0),
        .VAUXP    (16'h0),
        .VAUXN    (16'h0),
        .EOC      (),
        .EOS      (),
        .ALM      (),
        .OT       (),
        .CHANNEL  (),
        .BUSY     (),
        .JTAGMODIFIED(),
        .JTAGLOCKED(),
        .JTAGBUSY()
    );
`endif

    // LED 상태 표시 (합성용; 시뮬에서는 무시)
    assign led[15:5] = 11'h0;
    assign led[4]    = irq;
    assign led[3:1]  = 3'b0;      // 간략화: STATUS 레지스터 연결 생략
    assign led[0]    = irq;

endmodule
`default_nettype wire
