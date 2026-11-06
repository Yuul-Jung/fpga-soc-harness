// basys3_i2s_rx_top.v — Basys3 최상위 래퍼
// INMP441 I2S RX AXI4-Lite IP. Pmod JA 핀 매핑.
// AXI4-Lite 마스터 포트는 블록 디자인에서 MicroBlaze V에 연결한다.
// Verilog-2001. iverilog/yosys 호환.

`default_nettype none
`timescale 1ns/1ps

module basys3_i2s_rx_top (
    // Basys3 보드 핀
    input  wire        CLK100MHZ,
    input  wire        btnC,          // 리셋 (하이 활성)

    // Pmod JA — INMP441 I2S 연결
    // JA1=BCLK_OUT, JA2=LRCLK_OUT, JA3=DOUT_IN (마이크 출력)
    output wire        JA1,           // BCLK → 마이크 SCK
    output wire        JA2,           // LRCLK → 마이크 WS
    input  wire        JA3,           // DOUT ← 마이크 SD

    // LED[9:0] 볼륨 미터 (MicroBlaze V SW가 AXI4-Lite로 제어)
    // 여기서는 직결하지 않고 AXI4-Lite 마스터가 처리한다.

    // AXI4-Lite 슬레이브 포트 (블록 디자인에서 연결)
    input  wire [15:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [15:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // 인터럽트 (INTC 13번으로 연결)
    output wire        irq
);

    // 동기 리셋 (btnC)
    reg rst_q;
    always @(posedge CLK100MHZ) rst_q <= btnC;

    i2s_rx_axil #(
        .CLK_DIV(48)
    ) u_i2s_rx (
        .clk            (CLK100MHZ),
        .rst            (rst_q),

        .s_axil_awaddr  (s_axil_awaddr),
        .s_axil_awvalid (s_axil_awvalid),
        .s_axil_awready (s_axil_awready),
        .s_axil_wdata   (s_axil_wdata),
        .s_axil_wstrb   (s_axil_wstrb),
        .s_axil_wvalid  (s_axil_wvalid),
        .s_axil_wready  (s_axil_wready),
        .s_axil_bresp   (s_axil_bresp),
        .s_axil_bvalid  (s_axil_bvalid),
        .s_axil_bready  (s_axil_bready),
        .s_axil_araddr  (s_axil_araddr),
        .s_axil_arvalid (s_axil_arvalid),
        .s_axil_arready (s_axil_arready),
        .s_axil_rdata   (s_axil_rdata),
        .s_axil_rresp   (s_axil_rresp),
        .s_axil_rvalid  (s_axil_rvalid),
        .s_axil_rready  (s_axil_rready),

        .bclk_out       (JA1),
        .lrclk_out      (JA2),
        .dout_in        (JA3),
        .irq            (irq)
    );

endmodule
`default_nettype wire
