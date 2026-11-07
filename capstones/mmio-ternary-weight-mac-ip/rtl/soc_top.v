// soc_top.v — 최상위 SoC 래퍼 (axil_ternary_mac 인스턴스)
// CPU 없이 AXI4-Lite 마스터 포트를 밖으로 노출해 테스트벤치가 직접 구동
// Verilog-2001 — iverilog / verilator / yosys 호환

`timescale 1ns/1ps

module soc_top (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite 마스터 포트 (테스트벤치 / CPU가 구동)
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

    axil_ternary_mac u_slave (
        .clk       (clk),
        .rst_n     (rst_n),
        // 쓰기
        .s_awaddr  (m_awaddr),  .s_awvalid (m_awvalid), .s_awready (m_awready),
        .s_wdata   (m_wdata),   .s_wstrb   (m_wstrb),   .s_wvalid  (m_wvalid),
        .s_wready  (m_wready),  .s_bresp   (m_bresp),   .s_bvalid  (m_bvalid),
        .s_bready  (m_bready),
        // 읽기
        .s_araddr  (m_araddr),  .s_arvalid (m_arvalid), .s_arready (m_arready),
        .s_rdata   (m_rdata),   .s_rresp   (m_rresp),   .s_rvalid  (m_rvalid),
        .s_rready  (m_rready)
    );

endmodule
