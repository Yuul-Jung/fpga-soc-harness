// basys3_lqr_top.v — Basys3 보드 래퍼 (LQR 제어기 IP)
// 클럭: W5 100MHz sysclk, 리셋: btnC (active-high)
// AXI4-Lite 슬레이브 포트를 외부로 노출 (MicroBlaze V CPU 연결용)
// LED[15]=done(irq_stat), LED[14]=busy, LED[13:0]=u_out[14:1] 디버그
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)
`default_nettype none

module basys3_lqr_top (
    // 보드 클럭 / 리셋
    input  wire        clk,    // W5: 100 MHz
    input  wire        btnC,   // T17: 중앙 버튼 (동기 리셋)
    // LED[15:0] (디버그)
    output wire [15:0] led,
    // AXI4-Lite 슬레이브 버스 (CPU 측 — 외부 노출)
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [7:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready
);

    // ─── 동기 리셋 (2단) ─────────────────────────────────────────────────────
    reg rst_r1, rst_r2;
    always @(posedge clk) begin
        rst_r1 <= btnC;
        rst_r2 <= rst_r1;
    end
    wire rst = rst_r2;

    // ─── IRQ 내부 연결 ────────────────────────────────────────────────────────
    wire irq_out;

    // ─── AXI4-Lite 슬레이브 인스턴스 ────────────────────────────────────────
    axil_lqr u_axil (
        .clk              (clk),
        .rst              (rst),
        .s_axil_awaddr    (s_axil_awaddr),
        .s_axil_awvalid   (s_axil_awvalid),
        .s_axil_awready   (s_axil_awready),
        .s_axil_wdata     (s_axil_wdata),
        .s_axil_wstrb     (s_axil_wstrb),
        .s_axil_wvalid    (s_axil_wvalid),
        .s_axil_wready    (s_axil_wready),
        .s_axil_bresp     (s_axil_bresp),
        .s_axil_bvalid    (s_axil_bvalid),
        .s_axil_bready    (s_axil_bready),
        .s_axil_araddr    (s_axil_araddr),
        .s_axil_arvalid   (s_axil_arvalid),
        .s_axil_arready   (s_axil_arready),
        .s_axil_rdata     (s_axil_rdata),
        .s_axil_rresp     (s_axil_rresp),
        .s_axil_rvalid    (s_axil_rvalid),
        .s_axil_rready    (s_axil_rready),
        .irq              (irq_out)
    );

    // ─── LED 디버그 ───────────────────────────────────────────────────────────
    // LED[15]: IRQ 상태 (done_irq), LED[14]: AXI 활동 (awvalid)
    // LED[13:0]: 쓰기/읽기 활동 패턴
    assign led[15]   = irq_out;
    assign led[14]   = s_axil_awvalid | s_axil_arvalid;
    assign led[13:0] = {s_axil_wvalid, s_axil_wdata[12:0]};

endmodule
`default_nettype wire
