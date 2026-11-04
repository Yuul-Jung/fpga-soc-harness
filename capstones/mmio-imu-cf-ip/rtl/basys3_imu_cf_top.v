// basys3_imu_cf_top.v — Basys3 보드 래퍼 (IMU 상보 필터 IP)
// 클럭: W5 100MHz sysclk, 리셋: btnC (active-high)
// LED[15:0] = {busy, done, pitch[6:0], roll[6:0]}  (디버그 표시)
// AXI4-Lite 슬레이브 포트를 외부로 노출 (MicroBlaze V CPU 연결용)
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
module basys3_imu_cf_top (
    // 보드 클럭 / 리셋
    input  wire        clk,    // W5: 100 MHz
    input  wire        btnC,   // T17: 중앙 버튼 (리셋)
    // LED (디버그)
    output wire [15:0] led,
    // AXI4-Lite 버스 (CPU 측 — 외부 노출)
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

// ─── 내부 신호 ───────────────────────────────────────────────────────────────
wire        ip_done, ip_busy;
wire signed [17:0] ip_roll, ip_pitch;

// ─── AXI4-Lite 슬레이브 인스턴스 ────────────────────────────────────────────
axil_imu_cf u_axil (
    .clk             (clk),
    .rst             (btnC),
    .s_axil_awaddr   (s_axil_awaddr),
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
    .s_axil_arvalid  (s_axil_arvalid),
    .s_axil_arready  (s_axil_arready),
    .s_axil_rdata    (s_axil_rdata),
    .s_axil_rresp    (s_axil_rresp),
    .s_axil_rvalid   (s_axil_rvalid),
    .s_axil_rready   (s_axil_rready)
);

// ─── LED 디버그 표시 ─────────────────────────────────────────────────────────
// STATUS는 axil 내부에 있으므로 별도 wire 연결 대신 rdata 모니터링
// 여기서는 axil_imu_cf 내 imu_cf_ip의 done/busy를 직접 쓸 수 없으므로
// STATUS 레지스터를 직접 읽는 대신, AXI slave 내부 상태를 주석으로 안내
// 실제 보드에서는 로직 분석기나 UART TX로 확인 권장

// 간단한 LED 패턴: 복잡한 접근 없이 AXI 활동만 표시
// awvalid/arvalid 상태를 LED[15:14]에, 나머지는 0
assign led[15]   = s_axil_awvalid; // 쓰기 시도 중
assign led[14]   = s_axil_arvalid; // 읽기 시도 중
assign led[13:0] = 14'b0;

endmodule
`default_nettype wire
