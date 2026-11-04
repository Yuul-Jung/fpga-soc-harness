// basys3_top.v — Basys3 보드 래퍼: OV7670 SCCB 캡처 SoC 코어
// IOBUF로 SIO_D 오픈 드레인 구현, Pmod JA 핀 배정
// 시뮬레이션용 mmio-lite 슬레이브 직결 버전 (MicroBlaze 없이)
// Verilog-2001, 외부 IP 없음.
//
// Pmod JA 배선 (Basys3 JA 헤더):
//   JA1=sio_c, JA2=sio_d(IO), JA7=cam_pclk, JA8=cam_vsync
//   JA9=cam_href, JA10=cam_d7 ... 카메라 D[7:4]
// Pmod JB 배선 (D[3:0] 연장):
//   JB1=cam_d3, JB2=cam_d2, JB3=cam_d1, JB4=cam_d0

`default_nettype none
module basys3_top (
    input  wire        clk_100mhz,   // Basys3 온보드 100 MHz
    input  wire        cpu_resetn,   // 리셋 (active low)
    // --- MMIO 테스트용 스위치/버튼 (실제 보드에서 수동 테스트용) ---
    input  wire [1:0]  sw,           // sw[0]=START_CFG, sw[1]=CAP_EN
    input  wire        btnc,         // 가운데 버튼: 1클럭 START 펄스
    output wire [3:0]  led,          // led[0]=CFG_DONE, led[1]=FRAME_DONE, led[2]=SCCB_BUSY, led[3]=NA_ERR
    // --- Pmod JA: SCCB + PCLK/VSYNC/HREF + D[7:4] ---
    output wire        ja1,          // SIO_C (SCCB 클럭)
    inout  wire        ja2,          // SIO_D (SCCB 데이터, 오픈 드레인)
    input  wire        ja7,          // cam_pclk
    input  wire        ja8,          // cam_vsync
    input  wire        ja9,          // cam_href
    input  wire        ja10,         // cam_d[7]
    // --- Pmod JB: cam_d[6:3] ---
    input  wire        jb1,          // cam_d[6]
    input  wire        jb2,          // cam_d[5]
    input  wire        jb3,          // cam_d[4]
    input  wire        jb4,          // cam_d[3]
    // --- Pmod JC: cam_d[2:0] + 추가 ---
    input  wire        jc1,          // cam_d[2]
    input  wire        jc2,          // cam_d[1]
    input  wire        jc3           // cam_d[0]
);
    // --- 리셋 동기화 (active-high 2단 FF) ---
    reg [1:0] rst_sync;
    always @(posedge clk_100mhz or negedge cpu_resetn) begin
        if (!cpu_resetn) rst_sync <= 2'b11;
        else             rst_sync <= {rst_sync[0], 1'b0};
    end
    wire rst = rst_sync[1];

    // --- btnc 에지 검출 (3단 debounce + 1클럭 펄스) ---
    reg [2:0] btn_sync;
    always @(posedge clk_100mhz) begin
        if (rst) btn_sync <= 3'b0;
        else     btn_sync <= {btn_sync[1:0], btnc};
    end
    wire btn_pulse = btn_sync[1] & ~btn_sync[2];

    // --- MMIO 테스트 버스 (스위치/버튼으로 간이 조작) ---
    wire [31:0] mmio_addr  = 32'h1004_0000; // CTRL 레지스터
    wire [31:0] mmio_wdata = {16'd0, sw[1], sw[0]};
    wire        mmio_wen   = btn_pulse;
    wire        mmio_ren   = 1'b0;
    wire [31:0] mmio_rdata;

    // --- SCCB SIO_D 오픈 드레인: IOBUF ---
    wire sio_d_out_w;
    wire sio_d_oe_w;
    wire sio_d_in_w;
    // Basys3는 IOBUF 프리미티브 사용
    // 시뮬레이션에서는 assign으로 대체 (ifdef)
`ifdef SYNTHESIS
    IOBUF u_iobuf_siod (
        .O  (sio_d_in_w),
        .IO (ja2),
        .I  (sio_d_out_w),
        .T  (~sio_d_oe_w)   // T=1 → 하이임피던스
    );
`else
    // 시뮬레이션 모델: 출력 활성이면 out, 아니면 Z
    assign ja2       = sio_d_oe_w ? sio_d_out_w : 1'bz;
    assign sio_d_in_w = ja2;
`endif

    // --- 카메라 데이터 버스 ---
    wire [7:0] cam_d = {ja10, jb1, jb2, jb3, jb4, jc1, jc2, jc3};

    // --- SoC 코어 인스턴스 ---
    wire [4:0] status_bits;

    ov7670_sccb_top #(
        .CLK_HZ  (100_000_000),
        .SCCB_KHZ(100),
        .BASE_ADDR(32'h1004_0000)
    ) u_core (
        .clk      (clk_100mhz),
        .rst      (rst),
        .addr     (mmio_addr),
        .wdata    (mmio_wdata),
        .wen      (mmio_wen),
        .ren      (mmio_ren),
        .rdata    (mmio_rdata),
        .sio_c    (ja1),
        .sio_d_out(sio_d_out_w),
        .sio_d_oe (sio_d_oe_w),
        .sio_d_in (sio_d_in_w),
        .cam_pclk (ja7),
        .cam_vsync(ja8),
        .cam_href (ja9),
        .cam_d    (cam_d),
        .dbg_cfg_done  (led[0]),
        .dbg_frame_done(led[1])
    );

    // STATUS 비트 → LED (STATUS 레지스터를 수동 읽기 대신 내부 신호 사용)
    // led[0]=dbg_cfg_done, led[1]=dbg_frame_done은 위에서 연결
    // led[2], led[3]은 사용 불가 (rdata 버스 접근 없이)
    assign led[2] = 1'b0;
    assign led[3] = 1'b0;
endmodule
`default_nettype wire
