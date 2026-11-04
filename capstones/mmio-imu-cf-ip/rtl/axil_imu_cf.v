// axil_imu_cf.v — AXI4-Lite 슬레이브 레지스터 맵 (IMU 상보 필터)
// 기준 주소: 0x4019_0000 (동결 맵 free_slot[19] 제안)
// BREADY / RREADY 항상 1 가정 (슬레이브 간소화)
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
module axil_imu_cf #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8
)(
    input  wire        clk,
    input  wire        rst,
    // AXI4-Lite 슬레이브 포트
    input  wire [ADDR_WIDTH-1:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    input  wire [DATA_WIDTH-1:0] s_axil_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [ADDR_WIDTH-1:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    output reg  [DATA_WIDTH-1:0] s_axil_rdata,
    output reg  [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready
);

// ─── 레지스터 주소 (오프셋) ──────────────────────────────────────────────────
localparam REG_CTRL    = 8'h00; // WO: bit0=start
localparam REG_STATUS  = 8'h04; // RO: bit0=done, bit1=busy
localparam REG_AY      = 8'h08; // WO: 가속도 Y (Q2.14, 16비트 부호)
localparam REG_AZ      = 8'h0C; // WO: 가속도 Z (Q2.14)
localparam REG_AX      = 8'h10; // WO: 가속도 X (Q2.14, 피치용)
localparam REG_GX_DEL  = 8'h14; // WO: 롤 자이로 증분 (Q7.9, 18비트 부호)
localparam REG_ALPHA   = 8'h18; // WO: 상보 필터 계수 (alpha*65536, 16비트)
localparam REG_GY_DEL  = 8'h1C; // WO: 피치 자이로 증분 (Q7.9)
localparam REG_ROLL    = 8'h20; // RO: 롤 각도 출력 (Q7.9, 18비트 부호)
localparam REG_PITCH   = 8'h24; // RO: 피치 각도 출력 (Q7.9, 18비트 부호)

// ─── 레지스터 저장소 ─────────────────────────────────────────────────────────
reg signed [15:0] r_ay, r_az, r_ax;
reg signed [17:0] r_gx_del, r_gy_del;
reg        [15:0] r_alpha;
reg               r_start;

// ─── imu_cf_ip 인스턴스 ──────────────────────────────────────────────────────
wire        ip_done, ip_busy;
wire signed [17:0] ip_roll, ip_pitch;

imu_cf_ip u_imu_cf (
    .clk     (clk),
    .rst     (rst),
    .start   (r_start),
    .done    (ip_done),
    .busy    (ip_busy),
    .ay      (r_ay),
    .az      (r_az),
    .ax      (r_ax),
    .gx_del  (r_gx_del),
    .gy_del  (r_gy_del),
    .alpha   (r_alpha),
    .roll    (ip_roll),
    .pitch   (ip_pitch)
);

// ─── AXI4-Lite 쓰기 채널 ─────────────────────────────────────────────────────
reg [ADDR_WIDTH-1:0] wr_addr;
reg wr_addr_valid;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        s_axil_bresp   <= 2'b00;
        wr_addr        <= {ADDR_WIDTH{1'b0}};
        wr_addr_valid  <= 1'b0;
        r_ay      <= 16'sh0000;
        r_az      <= 16'sh7FFF; // az 기본값=1g (수직 정렬)
        r_ax      <= 16'sh0000;
        r_gx_del  <= 18'sd0;
        r_gy_del  <= 18'sd0;
        r_alpha   <= 16'd64225; // 0.98 * 65536
        r_start   <= 1'b0;
    end else begin
        r_start <= 1'b0; // 자동 클리어

        // AW 핸드셰이크
        if (s_axil_awvalid && !wr_addr_valid) begin
            s_axil_awready <= 1'b1;
            wr_addr        <= s_axil_awaddr;
            wr_addr_valid  <= 1'b1;
        end else begin
            s_axil_awready <= 1'b0;
        end

        // W 핸드셰이크 + 레지스터 쓰기
        if (s_axil_wvalid && wr_addr_valid) begin
            s_axil_wready <= 1'b1;
            wr_addr_valid <= 1'b0;
            case (wr_addr)
            REG_CTRL:   r_start  <= s_axil_wdata[0];
            REG_AY:     r_ay     <= s_axil_wdata[15:0];
            REG_AZ:     r_az     <= s_axil_wdata[15:0];
            REG_AX:     r_ax     <= s_axil_wdata[15:0];
            REG_GX_DEL: r_gx_del <= s_axil_wdata[17:0];
            REG_ALPHA:  r_alpha  <= s_axil_wdata[15:0];
            REG_GY_DEL: r_gy_del <= s_axil_wdata[17:0];
            default: ; // 무시
            endcase
            // B 채널
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= 2'b00; // OKAY
        end else begin
            s_axil_wready <= 1'b0;
        end

        // B 핸드셰이크 클리어
        if (s_axil_bvalid && s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
        end
    end
end

// ─── AXI4-Lite 읽기 채널 ─────────────────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= {DATA_WIDTH{1'b0}};
        s_axil_rresp   <= 2'b00;
    end else begin
        if (s_axil_arvalid && !s_axil_rvalid) begin
            s_axil_arready <= 1'b1;
            s_axil_rvalid  <= 1'b1;
            s_axil_rresp   <= 2'b00;
            case (s_axil_araddr)
            REG_STATUS: s_axil_rdata <= {30'b0, ip_busy, ip_done};
            REG_ROLL:   s_axil_rdata <= {{14{ip_roll[17]}}, ip_roll};
            REG_PITCH:  s_axil_rdata <= {{14{ip_pitch[17]}}, ip_pitch};
            default:    s_axil_rdata <= 32'h0;
            endcase
        end else begin
            s_axil_arready <= 1'b0;
        end

        if (s_axil_rvalid && s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
        end
    end
end

endmodule
`default_nettype wire
