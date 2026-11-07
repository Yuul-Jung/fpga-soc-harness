// basys3_top_irq_timer.v
// Basys3 최상위 래퍼 — axil_irq_timer IP
//
// 연결:
//   - 100 MHz 클럭 (W5) → s_axil_aclk
//   - btnC (T18, active-high) → 비동기 리셋 (aresetn = ~btnC)
//   - LED[0] = irq_out (인터럽트 가시화)
//   - LED[1] = running 상태는 IRQ_STATUS 읽기로 확인 (보드 테스트용)
//   - AXI4-Lite 버스: MicroBlaze V AXI 인터커넥트에서 연결
//     (이 래퍼는 루프백 없음; Vivado IP 통합 대상)
//
// 주의: 보드 단독 테스트가 아닌 MicroBlaze V SoC 통합 용도.
//       시뮬레이션은 tb_axil_irq_timer.v 사용.
//
// 준수: Verilog-2001

`default_nettype none
`timescale 1ns/1ps

module basys3_top_irq_timer (
    // 보드 클럭·리셋
    input  wire        clk,       // W5: 100 MHz 오실레이터
    input  wire        btnC,      // T18: Center 버튼 (리셋 전용)
    // LED 출력 (상태 가시화)
    output wire [15:0] led,
    // AXI4-Lite 슬레이브 포트 (인터커넥트 연결)
    input  wire [4:0]  s_axil_awaddr,
    input  wire [2:0]  s_axil_awprot,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [4:0]  s_axil_araddr,
    input  wire [2:0]  s_axil_arprot,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,
    // 인터럽트 (INTC 채널 14 연결)
    output wire        ip2intc_irpt
);

wire aresetn = ~btnC;   // btnC → active-low AXI reset

// IRQ 출력 → LED[0]
assign led[0]    = ip2intc_irpt;
assign led[15:1] = 15'd0;

axil_irq_timer #(
    .DATA_WIDTH(32),
    .ADDR_WIDTH(5)
) u_timer (
    .s_axil_aclk     (clk),
    .s_axil_aresetn  (aresetn),
    .s_axil_awaddr   (s_axil_awaddr),
    .s_axil_awprot   (s_axil_awprot),
    .s_axil_awvalid  (s_axil_awvalid),
    .s_axil_awready  (s_axil_awready),
    .s_axil_wdata    (s_axil_wdata),
    .s_axil_wstrb    (s_axil_wstrb),
    .s_axil_wvalid   (s_axil_wvalid),
    .s_axil_wready   (s_axil_wready),
    .s_axil_bresp    (s_axil_bresp),
    .s_axil_bvalid   (s_axil_bvalid),
    .s_axil_bready   (s_axil_bready),
    .s_axil_araddr   (s_axil_araddr),
    .s_axil_arprot   (s_axil_arprot),
    .s_axil_arvalid  (s_axil_arvalid),
    .s_axil_arready  (s_axil_arready),
    .s_axil_rdata    (s_axil_rdata),
    .s_axil_rresp    (s_axil_rresp),
    .s_axil_rvalid   (s_axil_rvalid),
    .s_axil_rready   (s_axil_rready),
    .irq_out         (ip2intc_irpt)
);

endmodule
`default_nettype wire
