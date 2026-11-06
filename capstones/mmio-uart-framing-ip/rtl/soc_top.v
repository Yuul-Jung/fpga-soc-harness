// soc_top.v — SoC 코어 플레이스홀더 (CPU 연결 지점)
// 이 파일은 AXI4-Lite 버스 패브릭을 플레이스홀더로 구현한다.
// 실제 MicroBlaze V CPU가 연결되면 이 파일을 Vivado IP 인스턴스로 교체한다.
// 현재는 AXI4-Lite 마스터 포트를 외부로 노출해 테스트벤치가 직접 구동한다.

`timescale 1ns/1ps
module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    // 외부 UART RX
    input  wire        uart_rx,
    // IRQ 출력 (MicroBlaze V INTC 연결 지점)
    output wire        irq_out,
    // AXI4-Lite 마스터 포트 (CPU 교체 지점)
    input  wire [7:0]  m_awaddr,
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,
    input  wire        m_wvalid,
    output wire        m_wready,
    output wire [1:0]  m_bresp,
    output wire        m_bvalid,
    input  wire        m_bready,
    input  wire [7:0]  m_araddr,
    input  wire        m_arvalid,
    output wire        m_arready,
    output wire [31:0] m_rdata,
    output wire [1:0]  m_rresp,
    output wire        m_rvalid,
    input  wire        m_rready
);

axil_uart_framing u_framer (
    .ACLK     (clk),
    .ARESETn  (rst_n),
    .AWADDR   (m_awaddr),
    .AWVALID  (m_awvalid),
    .AWREADY  (m_awready),
    .WDATA    (m_wdata),
    .WSTRB    (m_wstrb),
    .WVALID   (m_wvalid),
    .WREADY   (m_wready),
    .BRESP    (m_bresp),
    .BVALID   (m_bvalid),
    .BREADY   (m_bready),
    .ARADDR   (m_araddr),
    .ARVALID  (m_arvalid),
    .ARREADY  (m_arready),
    .RDATA    (m_rdata),
    .RRESP    (m_rresp),
    .RVALID   (m_rvalid),
    .RREADY   (m_rready),
    .uart_rx  (uart_rx),
    .irq      (irq_out)
);

endmodule
