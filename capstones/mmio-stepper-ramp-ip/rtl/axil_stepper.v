// axil_stepper.v — AXI4-Lite 스텝모터 가감속 IP
// IP 표준 Rev.1: ID=0xFFF0, VER=0xFFF4, IRQ_STATUS=0xFFF8(W1C), IRQ_ENABLE=0xFFFC
// 출처: 하네스 직접 작성 Verilog-2001 원본
`default_nettype none
`timescale 1ns/1ps

module axil_stepper (
    input  wire        clk,
    input  wire        rst,          // active-high synchronous
    // ── AXI4-Lite 슬레이브 ────────────────────────────────────────
    input  wire [15:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,
    input  wire [15:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,
    // ── 모터 출력 ────────────────────────────────────────────────
    output wire [3:0]  coil,         // 4선 모드
    output wire        step_out,     // STEP/DIR 모드
    output wire        dir_out,      // STEP/DIR 방향
    // ── 인터럽트 ─────────────────────────────────────────────────
    output wire        irq
);
    // ── 레지스터 주소 ────────────────────────────────────────────
    localparam A_CTRL        = 16'h0000;
    localparam A_TARGET      = 16'h0004;
    localparam A_MIN_PERIOD  = 16'h0008;
    localparam A_MAX_PERIOD  = 16'h000C;
    localparam A_DELTA       = 16'h0010;
    localparam A_MODE        = 16'h0014;
    localparam A_ID          = 16'hFFF0;
    localparam A_VER         = 16'hFFF4;
    localparam A_IRQ_STATUS  = 16'hFFF8;
    localparam A_IRQ_ENABLE  = 16'hFFFC;

    localparam IP_ID  = 32'h53545050; // "STPP"
    localparam IP_VER = 32'h01000100; // std rev1, ip v1.0

    // ── 사용자 레지스터 ──────────────────────────────────────────
    reg [23:0] r_target;      // TARGET_STEPS
    reg [23:0] r_min_period;  // MIN_PERIOD
    reg [23:0] r_max_period;  // MAX_PERIOD
    reg [15:0] r_delta;       // DELTA_PERIOD
    reg [1:0]  r_mode;        // MODE[1:0]
    reg        r_irq_en;      // IRQ_ENABLE[0]
    reg        r_irq_status;  // IRQ_STATUS[0] (W1C)
    reg        core_done_d;   // done 상승 엣지 검출용

    // ── step_ramp_core 연결 ──────────────────────────────────────
    wire       core_step_pulse;
    wire       core_dir;
    wire [1:0] core_state;
    wire       core_busy;
    wire       core_done;
    reg        core_start; // 1펄스
    reg        core_stop;  // 1펄스

    step_ramp_core u_ramp (
        .clk        (clk),
        .rst        (rst),
        .start      (core_start),
        .stop       (core_stop),
        .i_target   (r_target),
        .i_min_period(r_min_period),
        .i_max_period(r_max_period),
        .i_delta    (r_delta),
        .step_pulse (core_step_pulse),
        .dir        (core_dir),
        .state      (core_state),
        .busy       (core_busy),
        .done       (core_done)
    );

    // ── seq_4wire 연결 (4선 모드) ────────────────────────────────
    seq_4wire u_seq (
        .clk       (clk),
        .rst       (rst),
        .step_pulse(core_step_pulse),
        .dir       (core_dir),
        .half_step (r_mode[1]),
        .coil      (coil)
    );

    // ── STEP/DIR 출력 (r_mode[0]=1 시 사용) ─────────────────────
    assign step_out = core_step_pulse;
    assign dir_out  = core_dir;

    // ── IRQ ──────────────────────────────────────────────────────
    assign irq = r_irq_status & r_irq_en;

    // ── 임시 버퍼(write 주소/데이터 비동기 도착 대응) ────────────
    reg [15:0] aw_buf;
    reg        aw_got;
    reg [31:0] w_buf;
    reg [3:0]  wstrb_buf;
    reg        w_got;
    reg        wr_fire;   // 이번 사이클에 쓰기 실행

    // ── AXI4-Lite 쓰기 채널 ─────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            s_awready  <= 1'b1;
            s_wready   <= 1'b1;
            s_bvalid   <= 1'b0;
            s_bresp    <= 2'b00;
            aw_got     <= 1'b0;
            w_got      <= 1'b0;
            wr_fire    <= 1'b0;
            core_start <= 1'b0;
            core_stop  <= 1'b0;
            r_target      <= 24'd1000;
            r_min_period  <= 24'd500;
            r_max_period  <= 24'd50000;
            r_delta       <= 16'd100;
            r_mode        <= 2'b00;
            r_irq_en      <= 1'b0;
            r_irq_status  <= 1'b0;
            core_done_d   <= 1'b0;
        end else begin
            core_start <= 1'b0;
            core_stop  <= 1'b0;
            wr_fire    <= 1'b0;

            // done 상승 엣지 검출
            core_done_d <= core_done;

            // IRQ_STATUS: W1C 우선, 그 다음 done 상승 엣지에서 set
            if (aw_got && w_got && (aw_buf == A_IRQ_STATUS) && w_buf[0])
                r_irq_status <= 1'b0;  // W1C 우선
            else if (core_done && !core_done_d)
                r_irq_status <= 1'b1;  // 상승 엣지에서만 set

            // 주소 수신
            if (s_awvalid && s_awready) begin
                aw_buf    <= s_awaddr;
                aw_got    <= 1'b1;
                s_awready <= 1'b0;
            end
            // 데이터 수신
            if (s_wvalid && s_wready) begin
                w_buf     <= s_wdata;
                wstrb_buf <= s_wstrb;
                w_got     <= 1'b1;
                s_wready  <= 1'b0;
            end

            // 주소+데이터 모두 수신 → 레지스터 쓰기
            if (aw_got && w_got) begin
                aw_got    <= 1'b0;
                w_got     <= 1'b0;
                s_awready <= 1'b1;
                s_wready  <= 1'b1;
                wr_fire   <= 1'b1;
                s_bvalid  <= 1'b1;
                s_bresp   <= 2'b00;

                case (aw_buf)
                A_CTRL: begin
                    if (w_buf[0]) core_start <= 1'b1;
                    if (w_buf[1]) core_stop  <= 1'b1;
                end
                A_TARGET:     r_target     <= w_buf[23:0];
                A_MIN_PERIOD: r_min_period <= w_buf[23:0];
                A_MAX_PERIOD: r_max_period <= w_buf[23:0];
                A_DELTA:      r_delta      <= w_buf[15:0];
                A_MODE:       r_mode       <= w_buf[1:0];
                A_IRQ_ENABLE: r_irq_en <= w_buf[0];
                default: ; // 없는 주소: 무시
                endcase
            end

            // bresp handshake
            if (s_bvalid && s_bready)
                s_bvalid <= 1'b0;
        end
    end

    // ── AXI4-Lite 읽기 채널 ─────────────────────────────────────
    wire [31:0] ctrl_rd = {26'b0, core_state, core_done, core_busy};

    always @(posedge clk) begin
        if (rst) begin
            s_arready <= 1'b1;
            s_rvalid  <= 1'b0;
            s_rdata   <= 32'b0;
            s_rresp   <= 2'b00;
        end else begin
            if (s_arvalid && s_arready) begin
                s_arready <= 1'b0;
                s_rvalid  <= 1'b1;
                s_rresp   <= 2'b00;
                case (s_araddr)
                A_CTRL:        s_rdata <= ctrl_rd;
                A_TARGET:      s_rdata <= {8'b0, r_target};
                A_MIN_PERIOD:  s_rdata <= {8'b0, r_min_period};
                A_MAX_PERIOD:  s_rdata <= {8'b0, r_max_period};
                A_DELTA:       s_rdata <= {16'b0, r_delta};
                A_MODE:        s_rdata <= {30'b0, r_mode};
                A_ID:          s_rdata <= IP_ID;
                A_VER:         s_rdata <= IP_VER;
                A_IRQ_STATUS:  s_rdata <= {31'b0, r_irq_status};
                A_IRQ_ENABLE:  s_rdata <= {31'b0, r_irq_en};
                default:       s_rdata <= 32'b0;
                endcase
            end
            if (s_rvalid && s_rready) begin
                s_rvalid  <= 1'b0;
                s_arready <= 1'b1;
            end
        end
    end

endmodule
`default_nettype wire
