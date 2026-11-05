// axil_rc_arb.v — RC카 중재 IP AXI4-Lite 슬레이브 최상위
// 레지스터 (8 × 32-bit):
//   0x00 CTRL      RW  [0]=EN [2:1]=DIR [11:4]=SPEED [12]=SCAN_START(strobe)
//   0x04 DIST_L    RO  [9:0]  왼쪽 거리 cm
//   0x08 DIST_C    RO  [9:0]  정면 거리 cm
//   0x0C DIST_R    RO  [9:0]  오른쪽 거리 cm
//   0x10 THRESHOLD RW  [7:0]  안전 정지 임계 cm (기본 20)
//   0x14 STATUS    RO  [3:0]=fsm_state [4]=arb_stop [6:5]=best_dir [7]=scan_busy
//   0x18 IRQ_EN    RW  [0]=scan_done_irq_en
//   0x1C IRQ_STAT  RW1C[0]=scan_done_irq (W1C)
`default_nettype none
module axil_rc_arb #(
    parameter SETTLE_CYC = 30_000_000   // scan_fsm 서보 정착 시간
) (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // 외부 핀
    output wire        trig,        // → HC-SR04 TRIG
    input  wire        echo,        // ← HC-SR04 ECHO (레벨 변환 후)
    output wire        pwm_servo,   // → 서보 PWM
    output wire        ain1,        // TB6612FNG 채널 A
    output wire        ain2,
    output wire        pwm_a,
    output wire        bin1,        // TB6612FNG 채널 B
    output wire        bin2,
    output wire        pwm_b,
    // 인터럽트
    output wire        irq
);
    wire clk   = s_axi_aclk;
    wire rst_n = s_axi_aresetn;

    // ── 레지스터 ─────────────────────────────────────────────────
    reg [31:0] reg_ctrl;      // 0x00
    reg [31:0] reg_threshold; // 0x10  초깃값 20
    reg [31:0] reg_irq_en;    // 0x18
    reg [31:0] reg_irq_stat;  // 0x1C (W1C)

    wire ctrl_en    = reg_ctrl[0];
    wire [1:0] c_dir = reg_ctrl[2:1];
    wire [7:0] c_spd = reg_ctrl[11:4];
    wire [7:0] c_thr = reg_threshold[7:0];

    // ── 하위 모듈 ─────────────────────────────────────────────────
    wire [9:0] dist_L, dist_C, dist_R;
    wire       scan_done_pulse, scan_busy;
    wire [7:0] scan_angle;
    wire       meas_start, meas_done;
    wire [9:0] dist_cm;
    wire       arb_stop;
    wire [1:0] best_dir;
    wire [3:0] fsm_state;
    reg        scan_start_pulse; // scan_start 1-클럭 펄스 (CTRL[12] 쓰기 시)

    hcsr04_drv u_hcsr (
        .clk(clk), .rst_n(rst_n),
        .start(meas_start), .trig(trig), .echo(echo),
        .dist_cm(dist_cm), .done(meas_done)
    );

    servo_pwm u_servo (
        .clk(clk), .rst_n(rst_n),
        .angle(scan_angle), .pwm_out(pwm_servo)
    );

    scan_fsm #(.SETTLE_CYC(SETTLE_CYC)) u_scan (
        .clk(clk), .rst_n(rst_n),
        .scan_start(scan_start_pulse),
        .scan_angle(scan_angle), .meas_start(meas_start),
        .dist_in(dist_cm), .meas_done(meas_done),
        .dist_L(dist_L), .dist_C(dist_C), .dist_R(dist_R),
        .scan_done(scan_done_pulse), .scan_busy(scan_busy)
    );

    arb_fsm u_arb (
        .clk(clk), .rst_n(rst_n),
        .dist_L(dist_L), .dist_C(dist_C), .dist_R(dist_R),
        .threshold(c_thr), .ctrl_en(ctrl_en),
        .arb_stop(arb_stop), .best_dir(best_dir), .fsm_state(fsm_state)
    );

    motor_ctrl u_motor (
        .clk(clk), .rst_n(rst_n),
        .dir(c_dir), .speed(c_spd), .arb_stop(arb_stop),
        .ain1(ain1), .ain2(ain2), .pwm_a(pwm_a),
        .bin1(bin1), .bin2(bin2), .pwm_b(pwm_b)
    );

    // ── IRQ ───────────────────────────────────────────────────────
    assign irq = |(reg_irq_stat & reg_irq_en);

    // IRQ_STAT[0]: scan_done (세트: scan_done_pulse, 클리어: W1C)
    // (W1C 처리는 AXI 쓰기 핸들러에서 수행)

    // ── AXI4-Lite 쓰기 ───────────────────────────────────────────
    reg [4:0] waddr_lat;
    reg       waddr_v;
    reg [31:0] wdata_lat;
    reg        wdata_v;

    wire do_write = waddr_v && wdata_v;
    wire [2:0] widx = waddr_lat[4:2]; // 레지스터 인덱스

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_ctrl      <= 32'd0;
            reg_threshold <= 32'd20;    // 기본 임계 20 cm
            reg_irq_en    <= 32'd0;
            reg_irq_stat  <= 32'd0;
            scan_start_pulse <= 1'b0;
            waddr_lat <= 5'd0; waddr_v <= 1'b0;
            wdata_lat <= 32'd0; wdata_v <= 1'b0;
            s_axi_awready <= 1'b0; s_axi_wready <= 1'b0;
            s_axi_bvalid  <= 1'b0; s_axi_bresp  <= 2'd0;
        end else begin
            scan_start_pulse <= 1'b0;

            // scan_done_pulse → IRQ_STAT 세트
            if (scan_done_pulse) reg_irq_stat[0] <= 1'b1;

            // AW 채널
            s_axi_awready <= 1'b0;
            if (s_axi_awvalid && !waddr_v) begin
                waddr_lat     <= s_axi_awaddr[4:0];
                waddr_v       <= 1'b1;
                s_axi_awready <= 1'b1;
            end

            // W 채널
            s_axi_wready <= 1'b0;
            if (s_axi_wvalid && !wdata_v) begin
                wdata_lat    <= s_axi_wdata;
                wdata_v      <= 1'b1;
                s_axi_wready <= 1'b1;
            end

            // 쓰기 실행 (AW+W 모두 준비됐을 때)
            if (do_write && !s_axi_bvalid) begin
                waddr_v <= 1'b0; wdata_v <= 1'b0;
                case (widx)
                    3'd0: begin // CTRL
                        reg_ctrl <= wdata_lat & 32'hFFFF_EFFF; // bit12 클리어(strobe)
                        if (wdata_lat[12]) scan_start_pulse <= 1'b1;
                    end
                    3'd4: reg_threshold <= {24'd0, wdata_lat[7:0]};  // 0x10
                    3'd6: reg_irq_en    <= {31'd0, wdata_lat[0]};    // 0x18
                    3'd7: begin // 0x1C IRQ_STAT W1C
                        reg_irq_stat <= reg_irq_stat & ~wdata_lat;
                    end
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            // B 채널 핸드셰이크
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // ── AXI4-Lite 읽기 ───────────────────────────────────────────
    wire [31:0] status_rd = {24'd0,
        scan_busy,              // [7]
        best_dir,               // [6:5]
        arb_stop,               // [4]
        fsm_state               // [3:0]
    };

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'd0;
            s_axi_rresp   <= 2'd0;
        end else begin
            s_axi_arready <= 1'b0;
            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[4:2])
                    3'd0: s_axi_rdata <= reg_ctrl;
                    3'd1: s_axi_rdata <= {22'd0, dist_L};  // DIST_L
                    3'd2: s_axi_rdata <= {22'd0, dist_C};  // DIST_C
                    3'd3: s_axi_rdata <= {22'd0, dist_R};  // DIST_R
                    3'd4: s_axi_rdata <= reg_threshold;
                    3'd5: s_axi_rdata <= status_rd;
                    3'd6: s_axi_rdata <= reg_irq_en;
                    3'd7: s_axi_rdata <= reg_irq_stat;
                    default: s_axi_rdata <= 32'hDEAD_BEEF;
                endcase
            end
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
        end
    end
endmodule
`default_nettype wire
