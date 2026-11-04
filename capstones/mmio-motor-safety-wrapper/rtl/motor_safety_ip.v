// motor_safety_ip.v — H-브리지 모터 안전 래퍼 IP
// IP 표준 Rev.1 관리 레지스터(0xFFF0~0xFFFC) 포함
// MMIO-lite 버스 슬레이브 (1사이클 응답)
//
// 레지스터 맵 (바이트 주소, base+offset):
//   0x00  CTRL       RW  bit0=enable, bit1=oc_clear(자동소거), bit2=dt_bypass
//   0x04  DT_CYCLES  RW  [15:0] 데드타임 클럭 사이클 (기본 10)
//   0x08  STATUS     RO  bit0=oc_latched, bit1=active
//   0x0C  PWM_IN     RW  [3:0]={BL_in,BH_in,AL_in,AH_in}
//   0x10  PWM_OUT    RO  [3:0]={BL_out,BH_out,AL_out,AH_out} (보호 적용 후)
//   0xFFF0 ID        RO  0x4D535731 ("MSW1")
//   0xFFF4 VER       RO  0x01000001
//   0xFFF8 IRQ_STATUS RW1C bit0=oc_event
//   0xFFFC IRQ_ENABLE RW  bit0=oc_irq_en
//
// 보호 기능:
//   1. 슛스루 차단: AH&AL 동시=1 → 둘 다 0
//   2. 데드타임: 한 쪽이 하강한 후 dt_cycles 사이클 동안 반대 쪽 상승 차단
//   3. OC 래치: oc_fault_i(2단 동기화 후) → 모든 출력 0, oc_latched 셋
//   4. dt_bypass=1: 데드타임/슛스루 차단 없음(디버그 전용)

`default_nettype none

module motor_safety_ip (
    input  wire        clk,
    input  wire        rst,

    // MMIO-lite 버스 슬레이브
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    // 외부 과전류 입력 (비동기, 2단 동기화 내부 처리)
    input  wire        oc_fault_i,

    // PWM 보드 출력
    output wire        pwm_ah_o,
    output wire        pwm_al_o,
    output wire        pwm_bh_o,
    output wire        pwm_bl_o,

    // IRQ 출력
    output wire        irq_o
);

    // ---- 레지스터 -------------------------------------------------------
    reg         enable_r;
    reg         dt_bypass_r;
    reg  [15:0] dt_cycles_r;
    reg  [3:0]  pwm_in_r;
    reg         oc_latched_r;
    reg         irq_status_r;
    reg         irq_enable_r;

    // ---- OC 2단 동기화 --------------------------------------------------
    reg oc_s1, oc_s2, oc_s2_prev;

    always @(posedge clk) begin
        if (rst) begin
            oc_s1 <= 1'b0;
            oc_s2 <= 1'b0;
            oc_s2_prev <= 1'b0;
        end else begin
            oc_s1 <= oc_fault_i;
            oc_s2 <= oc_s1;
            oc_s2_prev <= oc_s2;
        end
    end

    wire oc_rise = oc_s2 & ~oc_s2_prev;  // 과전류 상승 엣지

    // ---- OC 래치 --------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            oc_latched_r <= 1'b0;
            irq_status_r <= 1'b0;
        end else begin
            if (oc_rise) begin
                oc_latched_r <= 1'b1;
                irq_status_r <= 1'b1;
            end
            // oc_clear (bit1 of CTRL): 래치 해제 (유효 쓰기 시 1사이클 후 소거)
            if (valid && we && addr[15:0] == 16'h0000 && wdata[1]) begin
                oc_latched_r <= 1'b0;
            end
            // IRQ_STATUS RW1C
            if (valid && we && addr[15:0] == 16'hFFF8) begin
                irq_status_r <= irq_status_r & ~wdata[0];
            end
        end
    end

    // ---- 쓰기 레지스터 --------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            enable_r    <= 1'b0;
            dt_bypass_r <= 1'b0;
            dt_cycles_r <= 16'd10;
            pwm_in_r    <= 4'b0000;
            irq_enable_r <= 1'b0;
        end else if (valid && we) begin
            case (addr[15:0])
                16'h0000: begin
                    enable_r    <= wdata[0];
                    // wdata[1] = oc_clear, 래치에서 처리
                    dt_bypass_r <= wdata[2];
                end
                16'h0004: dt_cycles_r  <= wdata[15:0];
                16'h000C: pwm_in_r     <= wdata[3:0];
                16'hFFFC: irq_enable_r <= wdata[0];
                default: ;
            endcase
        end
    end

    // ---- 데드타임 삽입 (채널 A) -----------------------------------------
    wire req_ah = pwm_in_r[0];
    wire req_al = pwm_in_r[1];
    wire req_bh = pwm_in_r[2];
    wire req_bl = pwm_in_r[3];

    wire safe_ah_a, safe_al_a;
    wire safe_bh_b, safe_bl_b;

    deadtime_ch dt_a (
        .clk       (clk),
        .rst       (rst),
        .bypass    (dt_bypass_r),
        .dt_cycles (dt_cycles_r),
        .req_h     (req_ah),
        .req_l     (req_al),
        .out_h     (safe_ah_a),
        .out_l     (safe_al_a)
    );

    deadtime_ch dt_b (
        .clk       (clk),
        .rst       (rst),
        .bypass    (dt_bypass_r),
        .dt_cycles (dt_cycles_r),
        .req_h     (req_bh),
        .req_l     (req_bl),
        .out_h     (safe_bh_b),
        .out_l     (safe_bl_b)
    );

    // ---- 최종 출력 게이트 (enable & !oc_latched) -----------------------
    wire active = enable_r & ~oc_latched_r;

    assign pwm_ah_o = safe_ah_a & active;
    assign pwm_al_o = safe_al_a & active;
    assign pwm_bh_o = safe_bh_b & active;
    assign pwm_bl_o = safe_bl_b & active;

    // ---- PWM_OUT 레지스터 (읽기용 스냅샷) ------------------------------
    wire [3:0] pwm_out_r = {pwm_bl_o, pwm_bh_o, pwm_al_o, pwm_ah_o};

    // ---- 읽기 ----------------------------------------------------------
    always @(*) begin
        case (addr[15:0])
            16'h0000: rdata = {29'd0, dt_bypass_r, 1'b0, enable_r};
            16'h0004: rdata = {16'd0, dt_cycles_r};
            16'h0008: rdata = {30'd0, active, oc_latched_r};
            16'h000C: rdata = {28'd0, pwm_in_r};
            16'h0010: rdata = {28'd0, pwm_out_r};
            16'hFFF0: rdata = 32'h4D535731;  // "MSW1"
            16'hFFF4: rdata = 32'h01000001;
            16'hFFF8: rdata = {31'd0, irq_status_r};
            16'hFFFC: rdata = {31'd0, irq_enable_r};
            default:  rdata = 32'd0;
        endcase
    end

    // ---- IRQ -----------------------------------------------------------
    assign irq_o = irq_status_r & irq_enable_r;

endmodule


// ============================================================
// deadtime_ch: 한 채널(H+L 상보 쌍)의 데드타임 삽입
// bypass=1 이면 슛스루 차단 없이 req를 그대로 출력(디버그)
// ============================================================
module deadtime_ch (
    input  wire        clk,
    input  wire        rst,
    input  wire        bypass,
    input  wire [15:0] dt_cycles,
    input  wire        req_h,
    input  wire        req_l,
    output reg         out_h,
    output reg         out_l
);

    // 상태: 0=IDLE, 1=DT_AFTER_H_FALL, 2=DT_AFTER_L_FALL
    localparam S_IDLE   = 2'd0;
    localparam S_DT_H   = 2'd1;
    localparam S_DT_L   = 2'd2;

    reg [1:0]  state;
    reg [15:0] cnt;
    reg req_h_prev, req_l_prev;

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            cnt        <= 16'd0;
            out_h      <= 1'b0;
            out_l      <= 1'b0;
            req_h_prev <= 1'b0;
            req_l_prev <= 1'b0;
        end else if (bypass) begin
            // 디버그 모드: 그대로 통과
            out_h      <= req_h;
            out_l      <= req_l;
            req_h_prev <= req_h;
            req_l_prev <= req_l;
            state      <= S_IDLE;
            cnt        <= 16'd0;
        end else begin
            req_h_prev <= req_h;
            req_l_prev <= req_l;

            case (state)
                S_IDLE: begin
                    // 슛스루 차단: 둘 다 high 요청 → 둘 다 0
                    if (req_h && req_l) begin
                        out_h <= 1'b0;
                        out_l <= 1'b0;
                    end
                    // H 하강 엣지 감지
                    else if (req_h_prev && !req_h) begin
                        out_h <= 1'b0;
                        out_l <= 1'b0;
                        cnt   <= dt_cycles;
                        state <= S_DT_H;
                    end
                    // L 하강 엣지 감지
                    else if (req_l_prev && !req_l) begin
                        out_h <= 1'b0;
                        out_l <= 1'b0;
                        cnt   <= dt_cycles;
                        state <= S_DT_L;
                    end
                    else begin
                        out_h <= req_h;
                        out_l <= req_l;
                    end
                end

                S_DT_H: begin
                    // H 측이 떨어진 후 대기: 아직 L 올리지 않음
                    out_h <= 1'b0;
                    out_l <= 1'b0;
                    if (cnt == 16'd0) begin
                        state <= S_IDLE;
                        // 다음 사이클 IDLE에서 req 반영
                    end else begin
                        cnt <= cnt - 16'd1;
                    end
                end

                S_DT_L: begin
                    // L 측이 떨어진 후 대기: 아직 H 올리지 않음
                    out_h <= 1'b0;
                    out_l <= 1'b0;
                    if (cnt == 16'd0) begin
                        state <= S_IDLE;
                    end else begin
                        cnt <= cnt - 16'd1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
