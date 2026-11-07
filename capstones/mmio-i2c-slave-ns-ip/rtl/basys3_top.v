// basys3_top.v — Basys3 최상위 래퍼 (I2C 슬레이브 무클럭스트레칭 AXI4-Lite IP)
// 클럭(W5, 100 MHz) + 리셋(btnC) + Pmod JA I2C 핀 연결.
// AXI4-Lite 마스터 포트를 외부로 노출해 MicroBlaze V 인터커넥트에 연결.
// Verilog-2001 / iverilog / verilator / yosys 호환.
// SPDX-License-Identifier: MIT
// 하네스 원본 (capstones/mmio-i2c-slave-ns-ip)

`timescale 1ns/1ps

module basys3_top (
    // Board clock & reset
    input  wire        clk_100mhz,   // W5: 100 MHz 오실레이터
    input  wire        btnC,         // U18: 중앙 버튼 (active-high 리셋)

    // Pmod JA — I2C (100 kHz)
    input  wire        ja1_scl,      // JA1: SCL (RPi GPIO SCL)
    inout  wire        ja2_sda,      // JA2: SDA (RPi GPIO SDA, 오픈 드레인)

    // AXI4-Lite 마스터 포트 (MicroBlaze V 인터커넥트 연결용)
    // Write Address
    input  wire [7:0]  M_AXI_AWADDR,
    input  wire        M_AXI_AWVALID,
    output wire        M_AXI_AWREADY,
    // Write Data
    input  wire [31:0] M_AXI_WDATA,
    input  wire [3:0]  M_AXI_WSTRB,
    input  wire        M_AXI_WVALID,
    output wire        M_AXI_WREADY,
    // Write Response
    output wire [1:0]  M_AXI_BRESP,
    output wire        M_AXI_BVALID,
    input  wire        M_AXI_BREADY,
    // Read Address
    input  wire [7:0]  M_AXI_ARADDR,
    input  wire        M_AXI_ARVALID,
    output wire        M_AXI_ARREADY,
    // Read Data
    output wire [31:0] M_AXI_RDATA,
    output wire [1:0]  M_AXI_RRESP,
    output wire        M_AXI_RVALID,
    input  wire        M_AXI_RREADY
);

wire rst = btnC;  // active-high 동기 리셋

// ─── axil_i2c_slave_ns 인스턴스 ───
axil_i2c_slave_ns #(.DEFAULT_ADDR(7'h20)) u_axil_i2c (
    .S_AXI_ACLK    (clk_100mhz),
    .S_AXI_ARESETN (~rst),

    .S_AXI_AWADDR  (M_AXI_AWADDR),
    .S_AXI_AWVALID (M_AXI_AWVALID),
    .S_AXI_AWREADY (M_AXI_AWREADY),

    .S_AXI_WDATA   (M_AXI_WDATA),
    .S_AXI_WSTRB   (M_AXI_WSTRB),
    .S_AXI_WVALID  (M_AXI_WVALID),
    .S_AXI_WREADY  (M_AXI_WREADY),

    .S_AXI_BRESP   (M_AXI_BRESP),
    .S_AXI_BVALID  (M_AXI_BVALID),
    .S_AXI_BREADY  (M_AXI_BREADY),

    .S_AXI_ARADDR  (M_AXI_ARADDR),
    .S_AXI_ARVALID (M_AXI_ARVALID),
    .S_AXI_ARREADY (M_AXI_ARREADY),

    .S_AXI_RDATA   (M_AXI_RDATA),
    .S_AXI_RRESP   (M_AXI_RRESP),
    .S_AXI_RVALID  (M_AXI_RVALID),
    .S_AXI_RREADY  (M_AXI_RREADY),

    .SCL           (ja1_scl),
    .SDA           (ja2_sda)
);

endmodule
