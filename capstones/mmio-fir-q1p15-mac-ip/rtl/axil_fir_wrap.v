// axil_fir_wrap.v — AXI4-Lite 슬레이브 래퍼 + Basys3 최상위
// capstone: mmio-fir-q1p15-mac-ip (stage T4)
// 형식: Verilog-2001, iverilog/verilator/yosys 호환
//
// 레지스터 맵 (AXI4-Lite 베이스: 0x4029_0000):
//   0x00  CTRL        [0]=enable [1]=bypass_mode
//   0x04  STATUS      [0]=busy (RO)
//   0x08  COEFF_ADDR  [3:0]=탭 인덱스 (0~15)
//   0x0C  COEFF_DATA  [15:0]=Q1.15 계수; 쓰기 시 COEFF_ADDR 인덱스에 저장
//
// 최상위 모듈: basys3_top
// 주변장치 모듈: axil_fir_wrap (fir_core 포함)

`default_nettype none
`timescale 1ns/1ps

// ═══════════════════════════════════════════════════════════
// axil_fir_wrap: AXI4-Lite 슬레이브 + fir_core 인스턴스
// ═══════════════════════════════════════════════════════════
module axil_fir_wrap (
    input  wire         clk,
    input  wire         rst_n,

    // AXI4-Lite 슬레이브 포트
    input  wire [15:0]  s_axil_awaddr,
    input  wire         s_axil_awvalid,
    output reg          s_axil_awready,

    input  wire [31:0]  s_axil_wdata,
    input  wire [3:0]   s_axil_wstrb,
    input  wire         s_axil_wvalid,
    output reg          s_axil_wready,

    output reg  [1:0]   s_axil_bresp,
    output reg          s_axil_bvalid,
    input  wire         s_axil_bready,

    input  wire [15:0]  s_axil_araddr,
    input  wire         s_axil_arvalid,
    output reg          s_axil_arready,

    output reg  [31:0]  s_axil_rdata,
    output reg  [1:0]   s_axil_rresp,
    output reg          s_axil_rvalid,
    input  wire         s_axil_rready,

    // AXI4-Stream 샘플 입력 (Q1.15)
    input  wire [15:0]  s_axis_data,
    input  wire         s_axis_valid,
    output wire         s_axis_ready,

    // AXI4-Stream 필터 출력 (Q1.15)
    output wire [15:0]  m_axis_data,
    output wire         m_axis_valid,
    input  wire         m_axis_ready
);

// ── 레지스터 ──────────────────────────────────
reg  [1:0]   reg_ctrl;      // [0]=enable [1]=bypass
wire         fir_busy;
reg  [3:0]   reg_coeff_addr;
reg  [15:0]  reg_coeff_data;

// 계수 쓰기 스트로브 (1사이클 펄스)
reg          coeff_we_r;

// ── AXI4-Lite 쓰기 채널 ──────────────────────
reg  [15:0]  aw_addr_latch;
reg          aw_pending;

always @(posedge clk) begin
    if (!rst_n) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        s_axil_bresp   <= 2'b00;
        aw_addr_latch  <= 0;
        aw_pending     <= 1'b0;
        reg_ctrl       <= 2'b00;
        reg_coeff_addr <= 4'h0;
        reg_coeff_data <= 16'h0;
        coeff_we_r     <= 1'b0;
    end else begin
        coeff_we_r    <= 1'b0;  // 기본 비활성
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;

        // AW 래치
        if (s_axil_awvalid && !aw_pending) begin
            aw_addr_latch  <= s_axil_awaddr;
            aw_pending     <= 1'b1;
            s_axil_awready <= 1'b1;
        end

        // W 처리
        if (s_axil_wvalid && aw_pending) begin
            s_axil_wready <= 1'b1;
            aw_pending    <= 1'b0;
            case (aw_addr_latch[3:0])
                4'h0: reg_ctrl <= s_axil_wdata[1:0];
                4'h8: reg_coeff_addr <= s_axil_wdata[3:0];
                4'hC: begin
                    reg_coeff_data <= s_axil_wdata[15:0];
                    coeff_we_r     <= 1'b1;
                end
                default: ;
            endcase
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= 2'b00;
        end

        if (s_axil_bvalid && s_axil_bready)
            s_axil_bvalid <= 1'b0;
    end
end

// ── AXI4-Lite 읽기 채널 ──────────────────────
always @(posedge clk) begin
    if (!rst_n) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= 32'h0;
        s_axil_rresp   <= 2'b00;
    end else begin
        s_axil_arready <= 1'b0;
        if (s_axil_arvalid && !s_axil_rvalid) begin
            s_axil_arready <= 1'b1;
            s_axil_rvalid  <= 1'b1;
            s_axil_rresp   <= 2'b00;
            case (s_axil_araddr[3:0])
                4'h0: s_axil_rdata <= {30'h0, reg_ctrl};
                4'h4: s_axil_rdata <= {31'h0, fir_busy};
                4'h8: s_axil_rdata <= {28'h0, reg_coeff_addr};
                4'hC: s_axil_rdata <= {16'h0, reg_coeff_data};
                default: s_axil_rdata <= 32'hDEAD_BEEF;
            endcase
        end
        if (s_axil_rvalid && s_axil_rready)
            s_axil_rvalid <= 1'b0;
    end
end

// ── fir_core 인스턴스 ──────────────────────────
fir_core #(
    .NUM_TAPS(16),
    .DATA_W(16),
    .COEF_W(16),
    .ADDR_W(4)
) u_fir (
    .clk          (clk),
    .rst_n        (rst_n),
    .s_axis_data  (s_axis_data),
    .s_axis_valid (s_axis_valid),
    .s_axis_ready (s_axis_ready),
    .m_axis_data  (m_axis_data),
    .m_axis_valid (m_axis_valid),
    .m_axis_ready (m_axis_ready),
    .coeff_we     (coeff_we_r),
    .coeff_addr   (reg_coeff_addr),
    .coeff_wdat   (reg_coeff_data),
    .enable       (reg_ctrl[0]),
    .bypass       (reg_ctrl[1]),
    .busy         (fir_busy)
);

endmodule

// ═══════════════════════════════════════════════════════════
// basys3_top: 보드 최상위 (합성 진입점)
// ═══════════════════════════════════════════════════════════
module basys3_top (
    input  wire        clk_in,    // 100 MHz 클럭 (W5)
    input  wire        btnC,      // 리셋 (T17, active-high)

    // 간단한 AXI-S 테스트용 스위치/LED
    input  wire [15:0] sw,        // SW[15:0] (Q포맷 샘플 직접 입력)
    output wire [15:0] led        // LED[15:0] (필터 출력 MSB)
);

wire sys_clk;
wire rst_n;

// ── 클럭: 클럭 버퍼로 직접 사용 (합성 단순화)
// 실제 Vivado 프로젝트에서는 MMCM으로 교체 권장
assign sys_clk = clk_in;
assign rst_n   = ~btnC;

// ── AXI4-Lite: 테스트용 최소 스텁 (합성 가능성 확인용)
// 실제 사용에서는 MicroBlaze M_AXI_DP 버스와 연결
wire [15:0] axil_awaddr  = 16'h0;
wire        axil_awvalid = 1'b0;
wire        axil_awready;
wire [31:0] axil_wdata   = 32'h0;
wire [3:0]  axil_wstrb   = 4'h0;
wire        axil_wvalid  = 1'b0;
wire        axil_wready;
wire [1:0]  axil_bresp;
wire        axil_bvalid;
wire        axil_bready  = 1'b1;
wire [15:0] axil_araddr  = 16'h0;
wire        axil_arvalid = 1'b0;
wire        axil_arready;
wire [31:0] axil_rdata;
wire [1:0]  axil_rresp;
wire        axil_rvalid;
wire        axil_rready  = 1'b1;

// ── AXI4-Stream: 스위치를 샘플로 사용 (테스트)
wire [15:0] s_axis_data  = sw;
wire        s_axis_valid = 1'b1;
wire        s_axis_ready;
wire [15:0] m_axis_data;
wire        m_axis_valid;

axil_fir_wrap u_wrap (
    .clk            (sys_clk),
    .rst_n          (rst_n),
    .s_axil_awaddr  (axil_awaddr),
    .s_axil_awvalid (axil_awvalid),
    .s_axil_awready (axil_awready),
    .s_axil_wdata   (axil_wdata),
    .s_axil_wstrb   (axil_wstrb),
    .s_axil_wvalid  (axil_wvalid),
    .s_axil_wready  (axil_wready),
    .s_axil_bresp   (axil_bresp),
    .s_axil_bvalid  (axil_bvalid),
    .s_axil_bready  (axil_bready),
    .s_axil_araddr  (axil_araddr),
    .s_axil_arvalid (axil_arvalid),
    .s_axil_arready (axil_arready),
    .s_axil_rdata   (axil_rdata),
    .s_axil_rresp   (axil_rresp),
    .s_axil_rvalid  (axil_rvalid),
    .s_axil_rready  (axil_rready),
    .s_axis_data    (s_axis_data),
    .s_axis_valid   (s_axis_valid),
    .s_axis_ready   (s_axis_ready),
    .m_axis_data    (m_axis_data),
    .m_axis_valid   (m_axis_valid),
    .m_axis_ready   (1'b1)
);

assign led = m_axis_data;

endmodule

`default_nettype wire
