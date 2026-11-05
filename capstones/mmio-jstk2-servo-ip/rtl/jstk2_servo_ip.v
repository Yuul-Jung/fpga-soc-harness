// jstk2_servo_ip.v — AXI4-Lite 슬레이브: JSTK2 SPI + 2채널 서보 PWM
// 하네스 원본 (외부 코드 포함 없음)
// IP 표준 rev1 준수: 관리 오프셋 FFF0~FFFC, ID=0x4A535356, VER=0x01010000
// BASE = 0x401F_0000, 창 크기 0x10000
`default_nettype none

module jstk2_servo_ip #(
    parameter CLK_FREQ_HZ    = 100_000_000,
    parameter SPI_CLK_HZ     =   1_000_000,
    parameter SAMPLE_PERIOD_MS = 100
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // AXI4-Lite 슬레이브 채널
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // IRQ
    output wire        irq,
    // SPI 포트 (JSTK2)
    output wire        spi_cs_n,
    output wire        spi_sclk,
    output wire        spi_mosi,
    input  wire        spi_miso,
    // 서보 PWM 출력
    output wire        pwm_a,
    output wire        pwm_b
);

// ─── 레지스터 맵 오프셋 ───────────────────────────────────────────
localparam ADDR_JSTK_X     = 16'h0000;
localparam ADDR_JSTK_Y     = 16'h0004;
localparam ADDR_JSTK_BTN   = 16'h0008;
localparam ADDR_SERVO_A    = 16'h000C;
localparam ADDR_SERVO_B    = 16'h0010;
localparam ADDR_CTRL       = 16'h0014;
localparam ADDR_SLEW       = 16'h0018;
localparam ADDR_ID         = 16'hFFF0;
localparam ADDR_VER        = 16'hFFF4;
localparam ADDR_IRQ_STATUS = 16'hFFF8;
localparam ADDR_IRQ_ENABLE = 16'hFFFC;

// IP 고정 상수
localparam IP_ID  = 32'h4A535356; // 'JSSV'
localparam IP_VER = 32'h01010000; // std_rev=1, major=1, minor=0

// ─── 내부 레지스터 ────────────────────────────────────────────────
reg [31:0] reg_servo_a;   // 서보 A 위치
reg [31:0] reg_servo_b;   // 서보 B 위치
reg [31:0] reg_ctrl;      // [0]=JSTK en, [1]=PWM en
reg [31:0] reg_slew;      // 기울기 제한
reg        reg_irq_status; // W1C
reg        reg_irq_enable;

// JSTK2 SPI 서브모듈 출력
wire [9:0]  jstk_x;
wire [9:0]  jstk_y;
wire [1:0]  jstk_btn;
wire        sample_done;

// ─── 서브모듈 인스턴스 ────────────────────────────────────────────
jstk2_spi #(
    .CLK_FREQ_HZ    (CLK_FREQ_HZ),
    .SPI_CLK_HZ     (SPI_CLK_HZ),
    .SAMPLE_PERIOD_MS(SAMPLE_PERIOD_MS)
) u_jstk2_spi (
    .clk        (s_axi_aclk),
    .rst_n      (s_axi_aresetn),
    .en         (reg_ctrl[0]),
    .jstk_x     (jstk_x),
    .jstk_y     (jstk_y),
    .jstk_btn   (jstk_btn),
    .sample_done(sample_done),
    .spi_cs_n   (spi_cs_n),
    .spi_sclk   (spi_sclk),
    .spi_mosi   (spi_mosi),
    .spi_miso   (spi_miso)
);

servo_pwm #(
    .CLK_FREQ_HZ (CLK_FREQ_HZ),
    .SERVO_PERIOD(2_000_000),
    .PULSE_MIN   (1_000_000),
    .PULSE_MAX   (2_000_000)
) u_servo_pwm (
    .clk   (s_axi_aclk),
    .rst_n (s_axi_aresetn),
    .en    (reg_ctrl[1]),
    .pos_a (reg_servo_a),
    .pos_b (reg_servo_b),
    .slew  (reg_slew),
    .pwm_a (pwm_a),
    .pwm_b (pwm_b)
);

// ─── IRQ ──────────────────────────────────────────────────────────
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn)
        reg_irq_status <= 1'b0;
    else begin
        if (sample_done)
            reg_irq_status <= 1'b1;
        // W1C: AXI 쓰기에서 소거 (아래 쓰기 블록에서 처리)
    end
end

assign irq = reg_irq_status & reg_irq_enable;

// ─── AXI4-Lite 쓰기 채널 ─────────────────────────────────────────
reg [15:0] aw_addr_lat;

always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bresp   <= 2'b00;
        aw_addr_lat   <= 16'd0;
        reg_servo_a   <= 32'd1_500_000; // 중앙 1.5 ms
        reg_servo_b   <= 32'd1_500_000;
        reg_ctrl      <= 32'd0;
        reg_slew      <= 32'd0;
        reg_irq_enable<= 1'b0;
    end else begin
        // AW 핸드셰이크
        if (s_axi_awvalid && !s_axi_awready) begin
            s_axi_awready <= 1'b1;
            aw_addr_lat   <= s_axi_awaddr[15:0];
        end else begin
            s_axi_awready <= 1'b0;
        end

        // W 핸드셰이크 + 레지스터 쓰기
        if (s_axi_wvalid && !s_axi_wready) begin
            s_axi_wready <= 1'b1;
            case (aw_addr_lat)
                ADDR_SERVO_A: reg_servo_a   <= s_axi_wdata;
                ADDR_SERVO_B: reg_servo_b   <= s_axi_wdata;
                ADDR_CTRL:    reg_ctrl      <= s_axi_wdata;
                ADDR_SLEW:    reg_slew      <= s_axi_wdata;
                ADDR_IRQ_STATUS: begin
                    // W1C: 1이 쓰인 비트를 소거
                    if (s_axi_wdata[0]) reg_irq_status <= 1'b0;
                end
                ADDR_IRQ_ENABLE: reg_irq_enable <= s_axi_wdata[0];
                default: ; // 없는 주소: 무시
            endcase
        end else begin
            s_axi_wready <= 1'b0;
        end

        // B 채널
        if (s_axi_wready && s_axi_wvalid) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;
        end else if (s_axi_bready && s_axi_bvalid) begin
            s_axi_bvalid <= 1'b0;
        end
    end
end

// ─── AXI4-Lite 읽기 채널 ─────────────────────────────────────────
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rdata   <= 32'd0;
        s_axi_rresp   <= 2'b00;
    end else begin
        if (s_axi_arvalid && !s_axi_arready) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b1;
            s_axi_rresp   <= 2'b00;
            case (s_axi_araddr[15:0])
                ADDR_JSTK_X:     s_axi_rdata <= {22'd0, jstk_x};
                ADDR_JSTK_Y:     s_axi_rdata <= {22'd0, jstk_y};
                ADDR_JSTK_BTN:   s_axi_rdata <= {30'd0, jstk_btn};
                ADDR_SERVO_A:    s_axi_rdata <= reg_servo_a;
                ADDR_SERVO_B:    s_axi_rdata <= reg_servo_b;
                ADDR_CTRL:       s_axi_rdata <= reg_ctrl;
                ADDR_SLEW:       s_axi_rdata <= reg_slew;
                ADDR_ID:         s_axi_rdata <= IP_ID;
                ADDR_VER:        s_axi_rdata <= IP_VER;
                ADDR_IRQ_STATUS: s_axi_rdata <= {31'd0, reg_irq_status};
                ADDR_IRQ_ENABLE: s_axi_rdata <= {31'd0, reg_irq_enable};
                default:         s_axi_rdata <= 32'd0;
            endcase
        end else begin
            s_axi_arready <= 1'b0;
        end

        if (s_axi_rready && s_axi_rvalid)
            s_axi_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire
