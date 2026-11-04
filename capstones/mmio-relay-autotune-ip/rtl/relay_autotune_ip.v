// relay_autotune_ip.v — 릴레이 자동 튜닝 IP
// 릴레이 피드백 FSM으로 한계 사이클 주기·진폭을 측정한다.
// AXI4-Lite 슬레이브. BASE_ADDR 파라미터로 설정.
// IRQ [0]: 한계 사이클 완료 (setpoint 교차 2회). W1C.
// Verilog-2001. iverilog/verilator/yosys 호환.
`timescale 1ns/1ps

module relay_autotune_ip #(
    parameter BASE_ADDR = 32'h401E_0000
) (
    // AXI4-Lite 슬레이브
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

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

    // 측정 대상 속도 입력 (엔코더 등에서 오는 16비트 부호 없음 값)
    input  wire [15:0] speed_in,

    // 릴레이 출력: 1=정방향, 0=역방향 (H-브리지 방향 비트)
    output reg         relay_out,

    // 인터럽트
    output wire        irq
);

    // -----------------------------------------------------------------------
    // 레지스터 오프셋 (BASE 기준)
    // -----------------------------------------------------------------------
    localparam [15:0]
        REG_CTRL        = 16'h0000,
        REG_SETPOINT    = 16'h0004,
        REG_RELAY_AMP   = 16'h0008,
        REG_PERIOD_CNT  = 16'h000C,
        REG_AMP_MEAS    = 16'h0010,
        REG_CROSS_CNT   = 16'h0014,
        REG_IRQ_STATUS  = 16'hFFFC,
        REG_IRQ_ENABLE  = 16'hFFF8,
        REG_IP_ID       = 16'hFFF0,
        REG_IP_VER      = 16'hFFF4;

    localparam [31:0] IP_ID  = 32'h5245_4C59;  // "RELY"
    localparam [31:0] IP_VER = 32'h0000_0100;

    // -----------------------------------------------------------------------
    // 릴레이 FSM 상태
    // -----------------------------------------------------------------------
    localparam FSM_IDLE = 2'd0,
               FSM_RUN  = 2'd1,
               FSM_DONE = 2'd2;

    // -----------------------------------------------------------------------
    // 제어 레지스터
    // -----------------------------------------------------------------------
    reg        ctrl_en;
    reg [15:0] setpoint;
    reg [15:0] relay_amp;

    // 측정 결과 레지스터
    reg [31:0] period_cnt;   // 가장 최근 반주기 클럭 수
    reg [15:0] amp_meas;     // 측정 진폭
    reg [15:0] cross_cnt;    // setpoint 교차 횟수

    // IRQ
    reg  [0:0] irq_status;
    reg  [0:0] irq_enable;
    assign irq = |(irq_status & irq_enable);

    // -----------------------------------------------------------------------
    // 릴레이 FSM 내부 신호
    // -----------------------------------------------------------------------
    reg [1:0]  fsm;
    reg        prev_en;        // ctrl_en 상승에지 감지
    reg        prev_cross_dir; // 이전 교차 방향 (0=아래, 1=위)
    reg [31:0] clk_cnt;        // 교차 간격 측정 카운터
    reg [15:0] spd_max;        // 측정 구간 최대 속도
    reg [15:0] spd_min;        // 측정 구간 최소 속도

    // 현재 setpoint 위·아래 판단
    wire above_setpoint = (speed_in >= setpoint);

    // -----------------------------------------------------------------------
    // 릴레이 FSM
    // -----------------------------------------------------------------------
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            fsm           <= FSM_IDLE;
            prev_en       <= 1'b0;
            relay_out     <= 1'b1;
            clk_cnt       <= 32'd0;
            cross_cnt     <= 16'd0;
            period_cnt    <= 32'd0;
            amp_meas      <= 16'd0;
            spd_max       <= 16'd0;
            spd_min       <= 16'hFFFF;
            prev_cross_dir<= 1'b0;
            irq_status    <= 1'b0;
        end else begin
            prev_en <= ctrl_en;

            case (fsm)
                // --------------------------------------------------------
                FSM_IDLE: begin
                    // ctrl_en 상승에지에서 1회 시작
                    if (ctrl_en && !prev_en) begin
                        fsm            <= FSM_RUN;
                        relay_out      <= 1'b1;   // 정방향으로 시작
                        clk_cnt        <= 32'd0;
                        cross_cnt      <= 16'd0;
                        spd_max        <= speed_in;
                        spd_min        <= speed_in;
                        prev_cross_dir <= 1'b0;  // 항상 아래 상태로 시작 (relay=1이 위로 밀어 첫 교차 보장)
                    end
                end

                // --------------------------------------------------------
                FSM_RUN: begin
                    clk_cnt <= clk_cnt + 32'd1;

                    // 최대·최소 속도 추적
                    if (speed_in > spd_max) spd_max <= speed_in;
                    if (speed_in < spd_min) spd_min <= speed_in;

                    // setpoint 교차 감지
                    if (above_setpoint != prev_cross_dir) begin
                        prev_cross_dir <= above_setpoint;

                        // 릴레이 부호 뒤집기
                        relay_out  <= above_setpoint ? 1'b0 : 1'b1;

                        // 첫 교차 이후부터 반주기 측정
                        if (cross_cnt >= 16'd1) begin
                            period_cnt <= clk_cnt;
                            amp_meas   <= (spd_max - spd_min) >> 1;
                        end

                        // 카운터 리셋
                        clk_cnt   <= 32'd0;
                        spd_max   <= speed_in;
                        spd_min   <= speed_in;

                        cross_cnt <= cross_cnt + 16'd1;

                        // 교차 2회 완료 → 한계 사이클 주기 유효
                        if (cross_cnt >= 16'd1) begin
                            irq_status <= 1'b1;  // IRQ OR-업데이트
                            fsm        <= FSM_DONE;
                        end
                    end

                    // en이 내려가면 중단
                    if (!ctrl_en) begin
                        fsm       <= FSM_IDLE;
                        relay_out <= 1'b0;
                    end
                end

                // --------------------------------------------------------
                FSM_DONE: begin
                    // IRQ가 W1C로 소거되거나 ctrl_en이 내려가면 복귀
                    if (!ctrl_en) begin
                        fsm       <= FSM_IDLE;
                        relay_out <= 1'b0;
                    end
                end

                default: fsm <= FSM_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite 쓰기 — 래치 방식 (aw+w 동시 또는 순차)
    // -----------------------------------------------------------------------
    reg        aw_ok;
    reg [15:0] aw_a;
    reg        wd_ok;
    reg [31:0] wd_d;
    reg        do_wr;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0; s_axi_wready <= 1'b0;
            s_axi_bvalid  <= 1'b0; s_axi_bresp  <= 2'b00;
            aw_ok <= 1'b0; wd_ok <= 1'b0; do_wr <= 1'b0;
            aw_a  <= 16'h0; wd_d  <= 32'h0;
            ctrl_en    <= 1'b0;
            setpoint   <= 16'd0;
            relay_amp  <= 16'd32;  // 기본 진폭 32 (엔코더 단위)
            irq_enable <= 1'b0;
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            do_wr         <= 1'b0;

            // AW 래치
            if (s_axi_awvalid && !aw_ok) begin
                aw_a  <= s_axi_awaddr[15:0];
                aw_ok <= 1'b1;
                s_axi_awready <= 1'b1;
            end
            // W 래치
            if (s_axi_wvalid && !wd_ok) begin
                wd_d  <= s_axi_wdata;
                wd_ok <= 1'b1;
                s_axi_wready <= 1'b1;
            end
            // 두 래치가 모두 찼을 때 처리
            if (aw_ok && wd_ok && !do_wr) begin
                do_wr <= 1'b1;
                aw_ok <= 1'b0;
                wd_ok <= 1'b0;
            end

            // 쓰기 실행
            if (do_wr) begin
                case (aw_a)
                    REG_CTRL:       ctrl_en    <= wd_d[0];
                    REG_SETPOINT:   setpoint   <= wd_d[15:0];
                    REG_RELAY_AMP:  relay_amp  <= wd_d[15:0];
                    REG_IRQ_STATUS: irq_status <= irq_status & ~wd_d[0:0]; // W1C
                    REG_IRQ_ENABLE: irq_enable <= wd_d[0:0];
                    default: ;
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end

            // B 핸드셰이크
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // -----------------------------------------------------------------------
    // AXI4-Lite 읽기
    // -----------------------------------------------------------------------
    reg [15:0] ar_a;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'h0;
            s_axi_rresp   <= 2'b00;
            ar_a          <= 16'h0;
        end else begin
            s_axi_arready <= 1'b0;

            if (s_axi_arvalid && !s_axi_rvalid) begin
                ar_a          <= s_axi_araddr[15:0];
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[15:0])
                    REG_CTRL:       s_axi_rdata <= {31'h0, ctrl_en};
                    REG_SETPOINT:   s_axi_rdata <= {16'h0, setpoint};
                    REG_RELAY_AMP:  s_axi_rdata <= {16'h0, relay_amp};
                    REG_PERIOD_CNT: s_axi_rdata <= period_cnt;
                    REG_AMP_MEAS:   s_axi_rdata <= {16'h0, amp_meas};
                    REG_CROSS_CNT:  s_axi_rdata <= {16'h0, cross_cnt};
                    REG_IRQ_STATUS: s_axi_rdata <= {31'h0, irq_status};
                    REG_IRQ_ENABLE: s_axi_rdata <= {31'h0, irq_enable};
                    REG_IP_ID:      s_axi_rdata <= IP_ID;
                    REG_IP_VER:     s_axi_rdata <= IP_VER;
                    default:        s_axi_rdata <= 32'h0;
                endcase
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
