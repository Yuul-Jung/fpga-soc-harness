`timescale 1ns/1ps
// basys3_top.v — Basys3 보드 래퍼
// clk 100 MHz, rst_n = !btnC (외부 리셋 반전)
// Pmod JA[0] = ESP32 TX → ble_uart_rx
// LED[0] = ble_irq 표시
`default_nettype none
module basys3_top (
    input  wire        clk,         // W5 100 MHz
    input  wire        btnC,        // T17 btnC(리셋, active-high)
    input  wire        ja1,         // Pmod JA pin1 = ESP32 TX
    output wire [15:0] led
);
    wire rst_n = !btnC;

    // ── demo_master: 시뮬 전용 AXI4-Lite 마스터 (합성 시 비활성화) ─
    // 보드에서는 직접 연결이므로 demo_master는 연결 없음.
    // 실제 SoC는 MicroBlaze 등 마스터를 m_ 포트에 붙인다.
    // 이 래퍼는 보드 핀 → soc_top 연결만 담당한다.

    wire [31:0] m_awaddr = 32'd0;
    wire        m_awvalid= 1'b0;
    wire [31:0] m_wdata  = 32'd0;
    wire [3:0]  m_wstrb  = 4'd0;
    wire        m_wvalid = 1'b0;
    wire        m_bready = 1'b1;
    wire [31:0] m_araddr = 32'd0;
    wire        m_arvalid= 1'b0;
    wire        m_rready = 1'b1;

    wire ble_irq_w;
    assign led = {15'd0, ble_irq_w};

    soc_top u_soc (
        .clk         (clk),
        .rst_n       (rst_n),
        .m_awaddr    (m_awaddr),  .m_awvalid(m_awvalid), .m_awready(),
        .m_wdata     (m_wdata),   .m_wstrb  (m_wstrb),   .m_wvalid (m_wvalid),
        .m_wready    (),          .m_bresp  (),           .m_bvalid (),
        .m_bready    (m_bready),
        .m_araddr    (m_araddr),  .m_arvalid(m_arvalid), .m_arready(),
        .m_rdata     (),          .m_rresp  (),           .m_rvalid (),
        .m_rready    (m_rready),
        .ble_uart_rx (ja1),
        .ble_irq     (ble_irq_w)
    );

endmodule
`default_nettype wire
