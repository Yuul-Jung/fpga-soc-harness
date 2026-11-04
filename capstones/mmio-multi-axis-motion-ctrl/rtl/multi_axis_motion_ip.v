// multi_axis_motion_ip.v — 2채널 속도 PID 모션 제어 IP
// IP 표준 Rev.1 관리 레지스터(0xFFF0~0xFFFC) 포함
// MMIO-lite 버스 슬레이브 (1사이클 응답)
//
// 레지스터 맵 (바이트 주소, base+offset):
//   0x0000  CTRL       RW  [0]=enable, [1]=emstop
//   0x0004  PERIOD     RW  [19:0] 주기 클럭 수 (기본 100000 = 1kHz@100MHz)
//   0x0008  STATUS     RO  [0]=period_tick(셀프클리어) [1]=ch_a_sat [2]=ch_b_sat
//   0x0010  CA_SETPT   RW  [15:0] 채널A 목표 속도 (부호있는 카운트/주기)
//   0x0014  CA_KP      RW  [15:0] Kp Q4.12
//   0x0018  CA_KI      RW  [15:0] Ki Q4.12
//   0x001C  CA_CNT     RO  [15:0] 최근 주기 엔코더 카운트
//   0x0020  CA_PWM     RO  [9:0]  현재 PWM 듀티
//   0x0024  CA_ITERM   RW  [31:0] 적분항 (윈드업 클리어용)
//   0x0030-0x0044 채널B (CB_*), 동일 구조
//   0xFFF0  ID         RO  0x4D435431 ("MCT1")
//   0xFFF4  VER        RO  0x01000001
//   0xFFF8  IRQ_STATUS RW1C [0]=period_tick_event
//   0xFFFC  IRQ_ENABLE RW   [0]=period_tick_irq_en

`default_nettype none

// ============================================================
// qenc_4x: 4체배 직교 엔코더 디코더
//   - 2단 동기화 후 A·B 각 에지에서 +1/-1 계수
//   - cnt는 누적 (외부에서 필요 시 래치·클리어)
// ============================================================
module qenc_4x (
    input  wire       clk,
    input  wire       rst,
    input  wire       enc_a,       // 엔코더 채널 A (비동기)
    input  wire       enc_b,       // 엔코더 채널 B (비동기)
    output reg  [15:0] cnt,        // 누적 카운트 (부호있는, 2의 보수)
    input  wire        cnt_latch,  // 1클럭 펄스: cnt를 cnt_lat에 래치하고 cnt를 0으로
    output reg  [15:0] cnt_lat     // 래치된 직전 주기 카운트
);
    // 2단 동기화
    reg a1, a2, a3;
    reg b1, b2, b3;

    always @(posedge clk) begin
        if (rst) begin
            a1 <= 0; a2 <= 0; a3 <= 0;
            b1 <= 0; b2 <= 0; b3 <= 0;
        end else begin
            a1 <= enc_a; a2 <= a1; a3 <= a2;
            b1 <= enc_b; b2 <= b1; b3 <= b2;
        end
    end

    // 4체배 계수: A 에지와 B 에지 각각에서 방향 판정
    // 방향: (A XOR A_prev) XOR (B XOR B_prev) 패턴에서 결정
    // 간단 구현: 에지 감지 후 XOR(a2, b2)로 방향
    wire a_edge = a2 ^ a3;
    wire b_edge = b2 ^ b3;

    always @(posedge clk) begin
        if (rst) begin
            cnt     <= 16'd0;
            cnt_lat <= 16'd0;
        end else if (cnt_latch) begin
            cnt_lat <= cnt;
            cnt     <= 16'd0;
        end else begin
            // A 에지: B의 현재 값과 에지 방향으로 계수 방향 결정
            if (a_edge) begin
                if (a2 ^ b2)
                    cnt <= cnt + 16'd1;
                else
                    cnt <= cnt - 16'd1;
            end
            // B 에지: A의 현재 값과 에지 방향으로 계수 방향 결정
            if (b_edge) begin
                if (a2 ^ b2)
                    cnt <= cnt - 16'd1;
                else
                    cnt <= cnt + 16'd1;
            end
        end
    end
endmodule


// ============================================================
// pwm10: 10비트 PWM 생성기
//   - freq = clk / 1024 ≈ 97.6kHz @100MHz
//   - duty = 0 → 항상 0, duty = 1023 → 항상 1
// ============================================================
module pwm10 (
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] duty,   // 0~1023
    output reg        pwm_o
);
    reg [9:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt   <= 10'd0;
            pwm_o <= 1'b0;
        end else begin
            cnt   <= cnt + 10'd1;
            pwm_o <= (cnt < duty) ? 1'b1 : 1'b0;
        end
    end
endmodule


// ============================================================
// multi_axis_motion_ip: 메인 IP
// ============================================================
module multi_axis_motion_ip (
    input  wire        clk,
    input  wire        rst,

    // MMIO-lite 버스
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    // 채널 A 엔코더 (비동기 입력)
    input  wire        enc_a_a,
    input  wire        enc_a_b,

    // 채널 B 엔코더 (비동기 입력)
    input  wire        enc_b_a,
    input  wire        enc_b_b,

    // PWM 출력 (방향+듀티 쌍)
    output wire        pwm_a_o,    // 채널 A PWM
    output wire        pwm_a_dir,  // 채널 A 방향 (0=정방향)
    output wire        pwm_b_o,    // 채널 B PWM
    output wire        pwm_b_dir,  // 채널 B 방향

    // IRQ
    output wire        irq_o
);

    // ---- 레지스터 -------------------------------------------------------
    reg         enable_r, emstop_r;
    reg  [19:0] period_r;        // 1kHz 주기 클럭 수
    reg  [15:0] ca_setpt_r, cb_setpt_r;
    reg  [15:0] ca_kp_r, ca_ki_r;
    reg  [15:0] cb_kp_r, cb_ki_r;
    reg  [31:0] ca_iterm_r, cb_iterm_r;
    reg         irq_status_r, irq_enable_r;

    // ---- 주기 타이머 (공통) --------------------------------------------
    reg  [19:0] period_cnt;
    reg         tick;           // 1클럭 펄스 (매 주기 시작)
    reg         tick_ev_r;     // IRQ용 이벤트 래치

    // PERIOD 레지스터 쓰기 감지 (조합 신호 — 타이머 즉시 리로드용)
    wire period_wr = valid && we && (addr[15:0] == 16'h0004);

    always @(posedge clk) begin
        if (rst) begin
            period_cnt <= 20'd1;   // 리셋 직후 첫 tick을 2클럭 뒤로 미룸
            tick       <= 1'b0;
        end else if (period_wr) begin
            // 새 주기값으로 즉시 리로드 (tick 없음)
            // wdata 는 combinational 이므로 다음 사이클부터 새 주기 적용
            period_cnt <= wdata[19:0] - 20'd1;
            tick       <= 1'b0;
        end else if (period_cnt == 20'd0) begin
            period_cnt <= period_r - 20'd1;
            tick       <= 1'b1;
        end else begin
            period_cnt <= period_cnt - 20'd1;
            tick       <= 1'b0;
        end
    end

    // ---- 엔코더 인스턴스 -----------------------------------------------
    wire [15:0] ca_cnt_raw, ca_cnt_lat;
    wire [15:0] cb_cnt_raw, cb_cnt_lat;

    qenc_4x enc_a (
        .clk       (clk),
        .rst       (rst),
        .enc_a     (enc_a_a),
        .enc_b     (enc_a_b),
        .cnt       (ca_cnt_raw),
        .cnt_latch (tick),
        .cnt_lat   (ca_cnt_lat)
    );

    qenc_4x enc_b (
        .clk       (clk),
        .rst       (rst),
        .enc_a     (enc_b_a),
        .enc_b     (enc_b_b),
        .cnt       (cb_cnt_raw),
        .cnt_latch (tick),
        .cnt_lat   (cb_cnt_lat)
    );

    // ---- PI 제어기 (tick마다 갱신) ------------------------------------
    // Q4.12 고정소수점: Kp·Ki의 상위 4비트=정수, 하위 12비트=소수
    // 연산: out = (err*Kp + iterm) >> 12, 클램프 [0, 1023]

    reg  [9:0] ca_duty_r, cb_duty_r;
    reg        ca_sat_r,  cb_sat_r;   // 포화 플래그

    // PI 갱신은 tick 다음 사이클 (엔코더 래치 직후)
    reg tick_d1;
    always @(posedge clk) tick_d1 <= rst ? 1'b0 : tick;

    // 중간 계산 신호 (combinational)
    wire signed [15:0] ca_err   = $signed(ca_setpt_r) - $signed(ca_cnt_lat);
    wire signed [15:0] cb_err   = $signed(cb_setpt_r) - $signed(cb_cnt_lat);

    // 32비트 고정소수점 적분항 갱신 + P항 계산
    wire signed [31:0] ca_p_raw = $signed({{16{ca_err[15]}}, ca_err}) * $signed({16'b0, ca_kp_r});
    wire signed [31:0] cb_p_raw = $signed({{16{cb_err[15]}}, cb_err}) * $signed({16'b0, cb_kp_r});

    // ki 곱 (적분 증가분)
    wire signed [31:0] ca_ki_inc = $signed({{16{ca_err[15]}}, ca_err}) * $signed({16'b0, ca_ki_r});
    wire signed [31:0] cb_ki_inc = $signed({{16{cb_err[15]}}, cb_err}) * $signed({16'b0, cb_ki_r});

    // 출력 계산 (>>12 → 10비트 클램프)
    wire signed [31:0] ca_out_raw = ($signed(ca_iterm_r) + ca_p_raw) >>> 12;
    wire signed [31:0] cb_out_raw = ($signed(cb_iterm_r) + cb_p_raw) >>> 12;

    always @(posedge clk) begin
        if (rst) begin
            ca_duty_r  <= 10'd0; ca_sat_r <= 1'b0;
            cb_duty_r  <= 10'd0; cb_sat_r <= 1'b0;
            ca_iterm_r <= 32'd0; cb_iterm_r <= 32'd0;
            irq_status_r <= 1'b0;
            tick_ev_r    <= 1'b0;
        end else begin
            // IRQ 이벤트 래치
            if (tick) begin
                tick_ev_r    <= 1'b1;
                irq_status_r <= 1'b1;
            end
            // IRQ_STATUS RW1C
            if (valid && we && addr[15:0] == 16'hFFF8)
                irq_status_r <= irq_status_r & ~wdata[0];

            // ITERM MMIO 쓰기 (윈드업 클리어용; PI 갱신보다 낮은 우선순위 — 같은 클럭이면 덮어씀)
            if (valid && we) begin
                if (addr[15:0] == 16'h0024) ca_iterm_r <= wdata;
                if (addr[15:0] == 16'h0044) cb_iterm_r <= wdata;
            end

            // PI 갱신 (tick 다음 클럭: 엔코더 래치 완료 후, MMIO 쓰기보다 높은 우선순위)
            if (tick_d1 && enable_r && !emstop_r) begin
                // 채널 A
                ca_iterm_r <= $signed(ca_iterm_r) + ca_ki_inc;
                if (ca_out_raw < 0) begin
                    ca_duty_r <= 10'd0;
                    ca_sat_r  <= 1'b1;
                end else if (ca_out_raw > 1023) begin
                    ca_duty_r <= 10'd1023;
                    ca_sat_r  <= 1'b1;
                end else begin
                    ca_duty_r <= ca_out_raw[9:0];
                    ca_sat_r  <= 1'b0;
                end
                // 채널 B
                cb_iterm_r <= $signed(cb_iterm_r) + cb_ki_inc;
                if (cb_out_raw < 0) begin
                    cb_duty_r <= 10'd0;
                    cb_sat_r  <= 1'b1;
                end else if (cb_out_raw > 1023) begin
                    cb_duty_r <= 10'd1023;
                    cb_sat_r  <= 1'b1;
                end else begin
                    cb_duty_r <= cb_out_raw[9:0];
                    cb_sat_r  <= 1'b0;
                end
            end
        end
    end

    // ---- 쓰기 레지스터 --------------------------------------------------
    // 주의: ca_iterm_r / cb_iterm_r 은 위의 PI 갱신 블록에서 관리 (다중 드라이버 방지)
    always @(posedge clk) begin
        if (rst) begin
            enable_r      <= 1'b0;
            emstop_r      <= 1'b0;
            period_r      <= 20'd100000;   // 1kHz
            ca_setpt_r    <= 16'd0; cb_setpt_r <= 16'd0;
            ca_kp_r       <= 16'd0; ca_ki_r    <= 16'd0;
            cb_kp_r       <= 16'd0; cb_ki_r    <= 16'd0;
            irq_enable_r  <= 1'b0;
        end else begin
            if (valid && we) begin
                case (addr[15:0])
                    16'h0000: begin enable_r <= wdata[0]; emstop_r <= wdata[1]; end
                    16'h0004: period_r <= wdata[19:0];
                    16'h0010: ca_setpt_r <= wdata[15:0];
                    16'h0014: ca_kp_r    <= wdata[15:0];
                    16'h0018: ca_ki_r    <= wdata[15:0];
                    16'h0030: cb_setpt_r <= wdata[15:0];
                    16'h0034: cb_kp_r    <= wdata[15:0];
                    16'h0038: cb_ki_r    <= wdata[15:0];
                    16'hFFFC: irq_enable_r <= wdata[0];
                    default: ;
                endcase
            end
        end
    end

    // ---- PWM 인스턴스 ---------------------------------------------------
    wire [9:0] ca_duty_gated = (enable_r && !emstop_r) ? ca_duty_r : 10'd0;
    wire [9:0] cb_duty_gated = (enable_r && !emstop_r) ? cb_duty_r : 10'd0;

    pwm10 pwm_a (
        .clk   (clk),
        .rst   (rst),
        .duty  (ca_duty_gated),
        .pwm_o (pwm_a_o)
    );

    pwm10 pwm_b (
        .clk   (clk),
        .rst   (rst),
        .duty  (cb_duty_gated),
        .pwm_o (pwm_b_o)
    );

    // 방향: setpoint 부호에서 결정 (음수=역방향)
    assign pwm_a_dir = ca_setpt_r[15];  // 1=음수=역방향
    assign pwm_b_dir = cb_setpt_r[15];

    // ---- 읽기 ----------------------------------------------------------
    always @(*) begin
        case (addr[15:0])
            16'h0000: rdata = {30'd0, emstop_r, enable_r};
            16'h0004: rdata = {12'd0, period_r};
            16'h0008: rdata = {29'd0, cb_sat_r, ca_sat_r, tick_ev_r};
            16'h0010: rdata = {16'd0, ca_setpt_r};
            16'h0014: rdata = {16'd0, ca_kp_r};
            16'h0018: rdata = {16'd0, ca_ki_r};
            16'h001C: rdata = {16'd0, ca_cnt_lat};
            16'h0020: rdata = {22'd0, ca_duty_r};
            16'h0024: rdata = ca_iterm_r;
            16'h0030: rdata = {16'd0, cb_setpt_r};
            16'h0034: rdata = {16'd0, cb_kp_r};
            16'h0038: rdata = {16'd0, cb_ki_r};
            16'h003C: rdata = {16'd0, cb_cnt_lat};
            16'h0040: rdata = {22'd0, cb_duty_r};
            16'h0044: rdata = cb_iterm_r;
            16'hFFF0: rdata = 32'h4D435431;  // "MCT1"
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
// basys3_mac_top: Basys3 보드 최상위 래퍼
// ============================================================
module basys3_mac_top (
    input  wire        CLK100MHZ,
    input  wire        btnC,        // 리셋 (센터 버튼)

    // Pmod JA — 채널 A: [0]=ENC_A_A, [1]=ENC_A_B, [2]=PWM_A, [3]=DIR_A
    input  wire [1:0]  ja_enc,      // JA[1:0] 엔코더 입력
    output wire [1:0]  ja_pwm,      // JA[3:2] PWM+DIR 출력

    // Pmod JB — 채널 B: [0]=ENC_B_A, [1]=ENC_B_B, [2]=PWM_B, [3]=DIR_B
    input  wire [1:0]  jb_enc,
    output wire [1:0]  jb_pwm,

    // 상태 LED
    output wire [3:0]  led          // [0]=enable [1]=emstop [2]=ca_sat [3]=cb_sat
);
    wire        clk = CLK100MHZ;
    wire        rst = btnC;

    // 단순 테스트용 MMIO (보드에서는 CPU가 대신)
    // 여기서는 enable, Kp=256(≈0.0625 Q4.12), period=100000 하드코딩
    wire        valid = 1'b0;
    wire        we    = 1'b0;
    wire [31:0] addr  = 32'd0;
    wire [31:0] wdata = 32'd0;
    wire [31:0] rdata;
    wire        irq;

    wire pwm_a, dir_a, pwm_b, dir_b;

    multi_axis_motion_ip dut (
        .clk        (clk),
        .rst        (rst),
        .valid      (valid),
        .we         (we),
        .addr       (addr),
        .wdata      (wdata),
        .rdata      (rdata),
        .enc_a_a    (ja_enc[0]),
        .enc_a_b    (ja_enc[1]),
        .enc_b_a    (jb_enc[0]),
        .enc_b_b    (jb_enc[1]),
        .pwm_a_o    (pwm_a),
        .pwm_a_dir  (dir_a),
        .pwm_b_o    (pwm_b),
        .pwm_b_dir  (dir_b),
        .irq_o      (irq)
    );

    assign ja_pwm = {dir_a, pwm_a};
    assign jb_pwm = {dir_b, pwm_b};
    assign led = {1'b0, 1'b0, 1'b0, 1'b0};

endmodule

`default_nettype wire
