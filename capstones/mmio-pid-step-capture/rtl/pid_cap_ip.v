// pid_cap_ip.v — PID 캡처 IP (mmio-pid-step-capture)
// 기능:
//   - 4× 직교 엔코더 2단 동기화 + 창 계수 속도 측정
//   - 8.8 고정소수점 PID FSM (anti-windup 적분기 클램프)
//   - PWM 출력
//   - BRAM 32엔트리 계단 응답 로거
//   - IP 표준 Rev.1 관리 레지스터 (0xFFF0~FFFC)
//
// 레지스터맵 (오프셋 바이트, 16비트 버스):
//   0x00: CTRL        RW  bit0=enable, bit1=clear_pos, bit2=cap_start
//   0x04: TARGET      RW  [15:0] 목표 속도 (카운트/창)
//   0x08: KP          RW  [15:0] 비례 이득 8.8 고정소수점
//   0x0C: KI          RW  [15:0] 적분 이득 8.8 고정소수점
//   0x10: KD          RW  [15:0] 미분 이득 8.8 고정소수점
//   0x14: SPEED       RO  [15:0] 현재 속도 (카운트/창)
//   0x18: PERIOD      RW  [15:0] PWM 주기 (클럭 사이클)
//   0x1C: DUTY        RO  [15:0] 현재 PWM 듀티
//   0x20: MIN_DUTY    RW  [15:0] 최소 PWM 듀티
//   0x24: CAP_ADDR    RW  [4:0]  BRAM 읽기 주소 (0~31)
//   0x28: CAP_DATA    RO  [15:0] CAP_ADDR 위치 속도 로그
//   0x2C: CAP_STATUS  RO  bit0=cap_full, [12:8]=cap_count
//   0xFFF0: ID        RO  0x50494431 (PID1)
//   0xFFF4: VER       RO  0x01000001
//   0xFFF8: IRQ_STATUS  RW1C  bit0=speed_ready, bit1=cap_full
//   0xFFFC: IRQ_ENABLE  RW    bit0=speed_irq_en, bit1=cap_irq_en
//
// Verilog-2001
`default_nettype none

module pid_cap_ip #(
    parameter WINDOW_CYCLES = 1_000,    // 시뮬: 1_000, 합성: 1_000_000
    parameter CAP_DEPTH     = 32,       // BRAM 로그 엔트리 수
    parameter PWM_PERIOD    = 1_000     // 기본 PWM 주기 (클럭 사이클)
) (
    input  wire        clk,
    input  wire        rst,
    // MMIO-lite 슬레이브 포트
    input  wire        valid,
    input  wire        we,
    input  wire [15:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // 하드웨어 포트
    input  wire        enc_a,
    input  wire        enc_b,
    output wire        pwm
);

    // ─── 레지스터 ──────────────────────────────────────────────────────
    reg        enable;
    reg        clear_pos;
    reg        cap_start_r;
    reg [15:0] target;
    reg [15:0] kp;
    reg [15:0] ki;
    reg [15:0] kd;
    reg [15:0] period;      // PWM 주기
    reg [15:0] min_duty;
    reg [4:0]  cap_rd_addr;
    reg [1:0]  irq_en;

    // ─── 엔코더 동기화 ─────────────────────────────────────────────────
    reg [1:0] enc_a_sr, enc_b_sr;
    wire enc_a_s = enc_a_sr[1];
    wire enc_b_s = enc_b_sr[1];

    always @(posedge clk) begin
        enc_a_sr <= {enc_a_sr[0], enc_a};
        enc_b_sr <= {enc_b_sr[0], enc_b};
    end

    // 4× 직교 디코더
    reg  enc_a_prev, enc_b_prev;
    wire a_rise = enc_a_s & ~enc_a_prev;
    wire a_fall = ~enc_a_s & enc_a_prev;
    wire b_rise = enc_b_s & ~enc_b_prev;
    wire b_fall = ~enc_b_s & enc_b_prev;
    wire fwd = (a_rise & ~enc_b_s) | (b_rise & enc_a_s) |
               (a_fall & enc_b_s)  | (b_fall & ~enc_a_s);
    wire rev = (a_rise & enc_b_s)  | (b_rise & ~enc_a_s) |
               (a_fall & ~enc_b_s) | (b_fall & enc_a_s);

    always @(posedge clk) begin
        enc_a_prev <= enc_a_s;
        enc_b_prev <= enc_b_s;
    end

    // ─── 창 계수 속도 측정 ─────────────────────────────────────────────
    reg [19:0] win_cnt;
    reg [15:0] pulse_acc;
    reg [15:0] speed;       // 현재 속도 (카운트/창)
    reg        speed_ready;

    always @(posedge clk) begin
        if (rst || !enable) begin
            win_cnt    <= 20'd0;
            pulse_acc  <= 16'd0;
            speed      <= 16'd0;
            speed_ready<= 1'b0;
        end else begin
            speed_ready <= 1'b0;
            if (fwd && !rev) pulse_acc <= pulse_acc + 16'd1;
            if (win_cnt == WINDOW_CYCLES - 1) begin
                win_cnt    <= 20'd0;
                speed      <= pulse_acc;
                pulse_acc  <= 16'd0;
                speed_ready<= 1'b1;
            end else begin
                win_cnt <= win_cnt + 20'd1;
            end
        end
    end

    // ─── PID FSM ───────────────────────────────────────────────────────
    // 상태: IDLE → CALC_ERR → CALC_P → CALC_I → CALC_D → CALC_SUM → UPDATE
    localparam S_IDLE     = 3'd0;
    localparam S_CALC_ERR = 3'd1;
    localparam S_CALC_P   = 3'd2;
    localparam S_CALC_I   = 3'd3;
    localparam S_CALC_D   = 3'd4;
    localparam S_CALC_SUM = 3'd5;
    localparam S_UPDATE   = 3'd6;

    reg [2:0]  pid_state;
    reg signed [15:0] err;
    reg signed [15:0] err_prev;
    reg signed [31:0] integrator;   // 클램프: -32768 ~ 32767
    reg signed [31:0] new_intg;     // 적분기 중간값 (S_CALC_I)
    reg signed [15:0] p_term;
    reg signed [15:0] i_term;
    reg signed [15:0] d_term;
    reg signed [23:0] pid_out_raw;
    reg [15:0] duty;

    // 8.8 고정소수점 곱셈 (부호 있음): 결과 하위 8비트를 버려 16비트 정수 반환
    function signed [15:0] fxp_mul;
        input signed [15:0] a;
        input signed [15:0] b;
        reg signed [31:0] tmp;
        begin
            tmp = $signed(a) * $signed(b);
            fxp_mul = tmp[23:8];
        end
    endfunction

    always @(posedge clk) begin
        if (rst || !enable) begin
            pid_state  <= S_IDLE;
            err        <= 16'sd0;
            err_prev   <= 16'sd0;
            integrator <= 32'sd0;
            duty       <= 16'd0;
            p_term     <= 16'sd0;
            i_term     <= 16'sd0;
            d_term     <= 16'sd0;
            pid_out_raw<= 24'sd0;
        end else begin
            case (pid_state)
                S_IDLE: begin
                    if (speed_ready)
                        pid_state <= S_CALC_ERR;
                end
                S_CALC_ERR: begin
                    err       <= $signed({1'b0, target}) - $signed({1'b0, speed});
                    pid_state <= S_CALC_P;
                end
                S_CALC_P: begin
                    p_term    <= fxp_mul(err, $signed(kp));
                    pid_state <= S_CALC_I;
                end
                S_CALC_I: begin
                    // 적분기 클램프 (anti-windup)
                    new_intg = integrator + $signed({{16{err[15]}}, err});
                    if (new_intg > 32'sd32767)
                        integrator <= 32'sd32767;
                    else if (new_intg < -32'sd32768)
                        integrator <= -32'sd32768;
                    else
                        integrator <= new_intg;
                    i_term    <= fxp_mul($signed(integrator[15:0]), $signed(ki));
                    pid_state <= S_CALC_D;
                end
                S_CALC_D: begin
                    d_term    <= fxp_mul((err - err_prev), $signed(kd));
                    err_prev  <= err;
                    pid_state <= S_CALC_SUM;
                end
                S_CALC_SUM: begin
                    pid_out_raw <= $signed({{8{p_term[15]}}, p_term}) +
                                   $signed({{8{i_term[15]}}, i_term}) +
                                   $signed({{8{d_term[15]}}, d_term});
                    pid_state   <= S_UPDATE;
                end
                S_UPDATE: begin
                    // 듀티 클램프: min_duty ~ period
                    if ($signed(pid_out_raw) <= 24'sd0)
                        duty <= min_duty;
                    else if (pid_out_raw[15:0] > period)
                        duty <= period;
                    else if (pid_out_raw[15:0] < min_duty)
                        duty <= min_duty;
                    else
                        duty <= pid_out_raw[15:0];
                    pid_state <= S_IDLE;
                end
                default: pid_state <= S_IDLE;
            endcase
        end
    end

    // ─── PWM 출력 ──────────────────────────────────────────────────────
    reg [15:0] pwm_cnt;
    reg        pwm_r;

    always @(posedge clk) begin
        if (rst || !enable) begin
            pwm_cnt <= 16'd0;
            pwm_r   <= 1'b0;
        end else begin
            if (pwm_cnt >= period - 1)
                pwm_cnt <= 16'd0;
            else
                pwm_cnt <= pwm_cnt + 16'd1;
            pwm_r <= (pwm_cnt < duty) ? 1'b1 : 1'b0;
        end
    end
    assign pwm = pwm_r;

    // ─── BRAM 계단 응답 로거 ──────────────────────────────────────────
    // 32엔트리 × 16비트 동기 BRAM
    reg [15:0] cap_bram [0:CAP_DEPTH-1];
    reg [4:0]  cap_wr_addr;
    reg        cap_active;
    reg        cap_full;
    reg [5:0]  cap_count;   // 0~32
    reg [15:0] cap_rd_data;

    // BRAM 읽기 (동기)
    always @(posedge clk) begin
        cap_rd_data <= cap_bram[cap_rd_addr];
    end

    // BRAM 쓰기 (속도 준비 시 캡처 활성이면 기록)
    always @(posedge clk) begin
        if (rst) begin
            cap_wr_addr <= 5'd0;
            cap_active  <= 1'b0;
            cap_full    <= 1'b0;
            cap_count   <= 6'd0;
        end else begin
            // cap_start_r 엣지로 캡처 시작
            if (cap_start_r && !cap_active && !cap_full) begin
                cap_active  <= 1'b1;
                cap_wr_addr <= 5'd0;
                cap_full    <= 1'b0;
                cap_count   <= 6'd0;
            end
            // 속도 갱신 시 로그
            if (cap_active && speed_ready) begin
                cap_bram[cap_wr_addr] <= speed;
                if (cap_wr_addr == CAP_DEPTH - 1) begin
                    cap_active  <= 1'b0;
                    cap_full    <= 1'b1;
                    cap_count   <= CAP_DEPTH;
                end else begin
                    cap_wr_addr <= cap_wr_addr + 5'd1;
                    cap_count   <= cap_count + 6'd1;
                end
            end
        end
    end

    // ─── IRQ ──────────────────────────────────────────────────────────
    reg [1:0] irq_status;
    always @(posedge clk) begin
        if (rst)
            irq_status <= 2'b0;
        else begin
            if (speed_ready) irq_status[0] <= 1'b1;
            if (cap_full)    irq_status[1] <= 1'b1;
            // RW1C: 쓰기로 클리어
            if (valid && we && addr == 16'hFFF8)
                irq_status <= irq_status & ~wdata[1:0];
        end
    end

    // ─── 레지스터 쓰기 ────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            enable      <= 1'b0;
            clear_pos   <= 1'b0;
            cap_start_r <= 1'b0;
            target      <= 16'd0;
            kp          <= 16'h0100; // 1.0 in 8.8
            ki          <= 16'h0010;
            kd          <= 16'h0008;
            period      <= PWM_PERIOD[15:0];
            min_duty    <= 16'd50;
            cap_rd_addr <= 5'd0;
            irq_en      <= 2'b0;
        end else begin
            cap_start_r <= 1'b0; // 1사이클 펄스
            clear_pos   <= 1'b0;
            if (valid && we) begin
                case (addr[7:0])
                    8'h00: begin
                        enable      <= wdata[0];
                        clear_pos   <= wdata[1];
                        cap_start_r <= wdata[2];
                    end
                    8'h04: target    <= wdata[15:0];
                    8'h08: kp        <= wdata[15:0];
                    8'h0C: ki        <= wdata[15:0];
                    8'h10: kd        <= wdata[15:0];
                    8'h18: period    <= wdata[15:0];
                    8'h20: min_duty  <= wdata[15:0];
                    8'h24: cap_rd_addr <= wdata[4:0];
                    8'hFC: irq_en    <= wdata[1:0];
                    default: ;
                endcase
            end
        end
    end

    // ─── 레지스터 읽기 ────────────────────────────────────────────────
    always @(*) begin
        case (addr)
            16'h0000: rdata = {29'h0, cap_start_r, clear_pos, enable};
            16'h0004: rdata = {16'h0, target};
            16'h0008: rdata = {16'h0, kp};
            16'h000C: rdata = {16'h0, ki};
            16'h0010: rdata = {16'h0, kd};
            16'h0014: rdata = {16'h0, speed};
            16'h0018: rdata = {16'h0, period};
            16'h001C: rdata = {16'h0, duty};
            16'h0020: rdata = {16'h0, min_duty};
            16'h0024: rdata = {27'h0, cap_rd_addr};
            16'h0028: rdata = {16'h0, cap_rd_data};
            16'h002C: rdata = {19'h0, cap_count[4:0], 3'h0, cap_full};
            16'hFFF0: rdata = 32'h50494431; // "PID1"
            16'hFFF4: rdata = 32'h01000001;
            16'hFFF8: rdata = {30'h0, irq_status};
            16'hFFFC: rdata = {30'h0, irq_en};
            default:  rdata = 32'h0;
        endcase
    end

endmodule
`default_nettype wire
