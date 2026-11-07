// basys3_top_mlp.v — Basys3 최상위 래퍼
// capstone: mmio-mlp-axil-ip
// 2026-11-08
//
// AXI4-Lite 마스터 포트는 외부(MicroBlaze V)에 연결.
// 이 래퍼는 클럭·리셋·LED를 연결한다.
// 시뮬레이션에서는 직접 axil_mlp_infer를 인스턴스화하여 사용한다.
`default_nettype none

module basys3_top_mlp (
    input  wire        clk,         // 100 MHz Basys3 시스템 클럭
    input  wire        btnC,        // 리셋 (active high)

    // AXI4-Lite 슬레이브 포트 (MicroBlaze V에서 연결)
    input  wire [7:0]  s_awaddr,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output wire        s_wready,
    output wire [1:0]  s_bresp,
    output wire        s_bvalid,
    input  wire        s_bready,
    input  wire [7:0]  s_araddr,
    input  wire        s_arvalid,
    output wire        s_arready,
    output wire [31:0] s_rdata,
    output wire [1:0]  s_rresp,
    output wire        s_rvalid,
    input  wire        s_rready,

    // 출력 (디버그용 LED)
    output wire [3:0]  led          // 예측 클래스 [3:0]
);
    wire rst = btnC;

    axil_mlp_infer #(
        .BASE_ADDR(32'h402F_0000),
        .N_IN(784), .N_H(128), .N_OUT(10),
        .IN_W(8), .W_W(8), .B_W(32), .ACC_W(32)
    ) u_ip (
        .clk        (clk),
        .rst        (rst),
        .s_awaddr   (s_awaddr),  .s_awvalid (s_awvalid), .s_awready (s_awready),
        .s_wdata    (s_wdata),   .s_wstrb   (s_wstrb),   .s_wvalid  (s_wvalid),  .s_wready (s_wready),
        .s_bresp    (s_bresp),   .s_bvalid  (s_bvalid),  .s_bready  (s_bready),
        .s_araddr   (s_araddr),  .s_arvalid (s_arvalid), .s_arready (s_arready),
        .s_rdata    (s_rdata),   .s_rresp   (s_rresp),   .s_rvalid  (s_rvalid),  .s_rready (s_rready),
        .result_out (led),
        .done_out   ()
    );
endmodule
`default_nettype wire
