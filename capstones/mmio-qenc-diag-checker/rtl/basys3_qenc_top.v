// basys3_qenc_top.v — Basys3 보드 최상위 (standalone 시험용)
// I-016 엔코더 난이도 사다리 (mmio-qenc-diag-checker, T2)
// Verilog-2001.
//
// SoC 통합 시: axil_qenc_wrap을 MicroBlaze V의 AXI4-Lite 버스에 연결.
// 여기서는 보드 핀을 연결하고 AXI 마스터는 외부에서 연결한다는 가정으로
// 포트를 열어 둔다.

`default_nettype none

module basys3_qenc_top (
    input  wire        clk,         // 100 MHz Basys3 W5
    input  wire        btnC,        // 리셋 (active-high)

    // 엔코더 입력 (Pmod JA 상단 2핀: JA[0]=A, JA[1]=B)
    input  wire        enc_a,       // JA[0]  — 5V 엔코더는 레벨 변환 필요
    input  wire        enc_b,       // JA[1]

    // AXI4-Lite 슬레이브 포트 (SoC 버스로부터)
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
    input  wire        s_rready
);

    // aresetn = NOT btnC
    wire aresetn = !btnC;

    axil_qenc_wrap #(
        .WINDOW_CYCLES(1_000_000)   // 10 ms @ 100 MHz
    ) u_wrap (
        .aclk      (clk),
        .aresetn   (aresetn),
        .s_awaddr  (s_awaddr),
        .s_awvalid (s_awvalid),
        .s_awready (s_awready),
        .s_wdata   (s_wdata),
        .s_wstrb   (s_wstrb),
        .s_wvalid  (s_wvalid),
        .s_wready  (s_wready),
        .s_bresp   (s_bresp),
        .s_bvalid  (s_bvalid),
        .s_bready  (s_bready),
        .s_araddr  (s_araddr),
        .s_arvalid (s_arvalid),
        .s_arready (s_arready),
        .s_rdata   (s_rdata),
        .s_rresp   (s_rresp),
        .s_rvalid  (s_rvalid),
        .s_rready  (s_rready),
        .enc_a     (enc_a),
        .enc_b     (enc_b)
    );

endmodule

`default_nettype wire
