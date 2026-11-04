// axil_lqr.v — AXI4-Lite 슬레이브 레지스터 맵 (LQR 제어기 IP)
// 기준 주소: 0x401C_0000 (동결 맵 free_slot[1C] 제안)
// BREADY / RREADY 항상 1 가정 (슬레이브 간소화)
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)
`default_nettype none

module axil_lqr #(
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
    input  wire        s_axil_rready,
    // IRQ 출력
    output wire        irq
);

    // ─── 레지스터 주소 (오프셋 바이트) ──────────────────────────────────────
    localparam REG_CTRL      = 8'h00; // WO: bit0=start
    localparam REG_STATUS    = 8'h04; // RO: bit0=done, bit1=busy
    localparam REG_K0        = 8'h08; // RW: 이득 K[0] (Q8.8 부호)
    localparam REG_K1        = 8'h0C; // RW: 이득 K[1]
    localparam REG_K2        = 8'h10; // RW: 이득 K[2]
    localparam REG_K3        = 8'h14; // RW: 이득 K[3]
    localparam REG_X_STATE   = 8'h18; // WO: 상태 x
    localparam REG_DX_STATE  = 8'h1C; // WO: 상태 dx
    localparam REG_THETA     = 8'h20; // WO: 상태 θ
    localparam REG_DTHETA    = 8'h24; // WO: 상태 dθ
    localparam REG_U_OUT     = 8'h28; // RO: 제어 출력 u
    localparam REG_IRQ_STAT  = 8'h2C; // RW1C: bit0=done_irq
    localparam REG_IRQ_EN    = 8'h30; // RW: bit0=done_irq_en

    // ─── 레지스터 저장소 ─────────────────────────────────────────────────────
    reg signed [15:0] r_k0, r_k1, r_k2, r_k3;
    reg signed [15:0] r_x, r_dx, r_theta, r_dtheta;
    reg               r_start;
    reg               r_irq_en;
    reg               r_irq_stat;

    // ─── lqr_ip 출력 ─────────────────────────────────────────────────────────
    wire        ip_done, ip_busy;
    wire signed [15:0] ip_u_out;

    lqr_ip u_lqr (
        .clk      (clk),
        .rst      (rst),
        .start    (r_start),
        .done     (ip_done),
        .busy     (ip_busy),
        .k0       (r_k0),
        .k1       (r_k1),
        .k2       (r_k2),
        .k3       (r_k3),
        .x_state  (r_x),
        .dx_state (r_dx),
        .theta    (r_theta),
        .dtheta   (r_dtheta),
        .u_out    (ip_u_out)
    );

    // ─── IRQ 래치 ────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst)
            r_irq_stat <= 1'b0;
        else if (ip_done)
            r_irq_stat <= 1'b1;
        // 소프트웨어 클리어는 아래 쓰기 경로에서 처리
    end

    assign irq = r_irq_stat & r_irq_en;

    // ─── AXI4-Lite 쓰기 채널 ─────────────────────────────────────────────────
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg wr_addr_valid;

    always @(posedge clk) begin
        if (rst) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_bresp   <= 2'b00;
            wr_addr        <= {ADDR_WIDTH{1'b0}};
            wr_addr_valid  <= 1'b0;
            r_k0     <= 16'sd0; r_k1  <= 16'sd0;
            r_k2     <= 16'sd0; r_k3  <= 16'sd0;
            r_x      <= 16'sd0; r_dx  <= 16'sd0;
            r_theta  <= 16'sd0; r_dtheta <= 16'sd0;
            r_start  <= 1'b0;
            r_irq_en <= 1'b0;
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
                REG_CTRL:     r_start  <= s_axil_wdata[0];
                REG_K0:       r_k0     <= s_axil_wdata[15:0];
                REG_K1:       r_k1     <= s_axil_wdata[15:0];
                REG_K2:       r_k2     <= s_axil_wdata[15:0];
                REG_K3:       r_k3     <= s_axil_wdata[15:0];
                REG_X_STATE:  r_x      <= s_axil_wdata[15:0];
                REG_DX_STATE: r_dx     <= s_axil_wdata[15:0];
                REG_THETA:    r_theta  <= s_axil_wdata[15:0];
                REG_DTHETA:   r_dtheta <= s_axil_wdata[15:0];
                REG_IRQ_STAT: if (s_axil_wdata[0]) r_irq_stat <= 1'b0; // RW1C
                REG_IRQ_EN:   r_irq_en <= s_axil_wdata[0];
                default: ; // RO 주소 무시
                endcase
                s_axil_bvalid <= 1'b1;
                s_axil_bresp  <= 2'b00;
            end else begin
                s_axil_wready <= 1'b0;
            end

            if (s_axil_bvalid && s_axil_bready)
                s_axil_bvalid <= 1'b0;
        end
    end

    // ─── AXI4-Lite 읽기 채널 ─────────────────────────────────────────────────
    always @(posedge clk) begin
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
                REG_STATUS:  s_axil_rdata <= {30'd0, ip_busy, ip_done};
                REG_K0:      s_axil_rdata <= {{16{r_k0[15]}}, r_k0};
                REG_K1:      s_axil_rdata <= {{16{r_k1[15]}}, r_k1};
                REG_K2:      s_axil_rdata <= {{16{r_k2[15]}}, r_k2};
                REG_K3:      s_axil_rdata <= {{16{r_k3[15]}}, r_k3};
                REG_U_OUT:   s_axil_rdata <= {{16{ip_u_out[15]}}, ip_u_out};
                REG_IRQ_STAT:s_axil_rdata <= {31'd0, r_irq_stat};
                REG_IRQ_EN:  s_axil_rdata <= {31'd0, r_irq_en};
                default:     s_axil_rdata <= 32'd0;
                endcase
            end else begin
                s_axil_arready <= 1'b0;
            end

            if (s_axil_rvalid && s_axil_rready)
                s_axil_rvalid <= 1'b0;
        end
    end

endmodule
`default_nettype wire
