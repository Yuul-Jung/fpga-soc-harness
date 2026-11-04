// imu_cf_ip.v — IMU 상보 필터 FSM + CORDIC 시퀀서
// 입력 : ay, az (롤용 accel Q2.14), ax (피치용), gx_del, gy_del (자이로 증분 Q7.9)
//        alpha (상보 필터 계수 *65536, 기본 0.98*65536=64225)
// 출력 : roll, pitch (Q7.9 degrees*512, 18비트 부호)
// 상보 필터:
//   roll  = (alpha*(roll_prev  + gx_del) + (65536-alpha)*atan2(ay,az )) >> 16
//   pitch = (alpha*(pitch_prev + gy_del) + (65536-alpha)*atan2(ax,-az)) >> 16
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
module imu_cf_ip (
    input  wire        clk,
    input  wire        rst,
    // 제어
    input  wire        start,
    output reg         done,
    output reg         busy,
    // 센서 입력
    input  wire signed [15:0] ay,
    input  wire signed [15:0] az,
    input  wire signed [15:0] ax,
    input  wire signed [17:0] gx_del,  // 롤 자이로 증분 (Q7.9)
    input  wire signed [17:0] gy_del,  // 피치 자이로 증분 (Q7.9)
    input  wire        [15:0] alpha,   // *65536 계수 (0x0000=0.0, 0xFFFF≈1.0)
    // 각도 출력
    output reg  signed [17:0] roll,
    output reg  signed [17:0] pitch
);

// ─── CORDIC 인스턴스 신호 ────────────────────────────────────────────────────
reg         cord_start;
reg  signed [15:0] cord_xi, cord_yi;
wire signed [17:0] cord_angle;
wire               cord_done;

cordic_atan2 u_cordic (
    .clk   (clk),
    .rst   (rst),
    .start (cord_start),
    .xi    (cord_xi),
    .yi    (cord_yi),
    .angle (cord_angle),
    .done  (cord_done)
);

// ─── FSM 상태 ────────────────────────────────────────────────────────────────
localparam ST_IDLE         = 3'd0;
localparam ST_CORD_ROLL    = 3'd1;  // atan2(ay, az) 시작
localparam ST_WAIT_ROLL    = 3'd2;  // CORDIC 완료 대기
localparam ST_CORD_PITCH   = 3'd3;  // atan2(ax, -az) 시작
localparam ST_WAIT_PITCH   = 3'd4;  // CORDIC 완료 대기
localparam ST_BLEND        = 3'd5;  // 상보 필터 혼합
localparam ST_DONE         = 3'd6;

reg [2:0] state;

// 중간 계산용
reg signed [17:0] accel_roll;   // atan2(ay, az) 결과
reg signed [17:0] accel_pitch;  // atan2(ax, -az) 결과
reg signed [17:0] gyro_roll;    // roll_prev + gx_del
reg signed [17:0] gyro_pitch;   // pitch_prev + gy_del

// 상보 필터 계산 (36비트 중간 — 오버플로 방지)
// roll = (alpha*gyro_roll + (65536-alpha)*accel_roll) >> 16
// 주의: alpha는 16비트 비부호, angle/gyro는 18비트 부호
// 곱 최대: 65536 * 92160 = 6,039,797,760 → 33비트 필요. 36비트로 충분
reg signed [35:0] blend_a;
reg signed [35:0] blend_b;
reg signed [17:0] one_minus_alpha_18;  // 65536 - alpha (16비트 비부호 → 항상 ≤65536)

// ─── 순차 로직 ───────────────────────────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= ST_IDLE;
        done        <= 1'b0;
        busy        <= 1'b0;
        cord_start  <= 1'b0;
        roll        <= 18'sd0;
        pitch       <= 18'sd0;
        accel_roll  <= 18'sd0;
        accel_pitch <= 18'sd0;
        gyro_roll   <= 18'sd0;
        gyro_pitch  <= 18'sd0;
        blend_a     <= 36'sd0;
        blend_b     <= 36'sd0;
        one_minus_alpha_18 <= 18'sd0;
    end else begin
        done       <= 1'b0;
        cord_start <= 1'b0;

        case (state)
        // ── 대기 ──────────────────────────────────────────────────────────
        ST_IDLE: begin
            if (start) begin
                busy  <= 1'b1;
                state <= ST_CORD_ROLL;
                // 자이로 적분항 미리 계산
                gyro_roll  <= roll  + gx_del;
                gyro_pitch <= pitch + gy_del;
            end
        end

        // ── 롤 CORDIC 시작: atan2(ay, az) ────────────────────────────────
        ST_CORD_ROLL: begin
            cord_xi    <= az;
            cord_yi    <= ay;
            cord_start <= 1'b1;
            state      <= ST_WAIT_ROLL;
        end

        // ── 롤 CORDIC 완료 대기 ───────────────────────────────────────────
        ST_WAIT_ROLL: begin
            if (cord_done) begin
                accel_roll <= cord_angle;
                state      <= ST_CORD_PITCH;
            end
        end

        // ── 피치 CORDIC 시작: atan2(ax, -az) ────────────────────────────
        ST_CORD_PITCH: begin
            cord_xi    <= -az;
            cord_yi    <= ax;
            cord_start <= 1'b1;
            state      <= ST_WAIT_PITCH;
        end

        // ── 피치 CORDIC 완료 대기 ─────────────────────────────────────────
        ST_WAIT_PITCH: begin
            if (cord_done) begin
                accel_pitch <= cord_angle;
                state       <= ST_BLEND;
                // 상보 필터 계수 준비
                // one_minus_alpha: 65536 - alpha (alpha는 0~65535)
                // alpha가 0이면 65536인데, 16비트에 담을 수 없으나
                // alpha=0 → 순수 가속도계, (1-alpha)=1.0=65536
                // 18비트 부호로 충분 (최대 65536 = 17비트)
                one_minus_alpha_18 <= 18'sd65536 - {{2{1'b0}}, alpha};
                // blend 계산 준비 (alpha * gyro_roll, 비부호*부호 = 부호)
                blend_a <= $signed({{2{1'b0}}, alpha}) * $signed(roll + gx_del);
                blend_b <= $signed(18'sd65536 - {{2{1'b0}}, alpha}) * $signed(cord_angle);
            end
        end

        // ── 상보 필터 혼합 ────────────────────────────────────────────────
        // blend_a, blend_b는 아직 이전 값(피치 CORDIC 중 계산됨)
        // 여기서 다시 계산해서 최신 accel_roll/pitch 반영
        ST_BLEND: begin
            // 롤: alpha*gyro_roll + (65536-alpha)*accel_roll, >> 16
            roll  <= (($signed({{2{1'b0}},alpha}) * $signed(gyro_roll))
                    + ($signed(one_minus_alpha_18) * $signed(accel_roll))) >>> 16;
            // 피치: alpha*gyro_pitch + (65536-alpha)*accel_pitch, >> 16
            pitch <= (($signed({{2{1'b0}},alpha}) * $signed(gyro_pitch))
                    + ($signed(one_minus_alpha_18) * $signed(accel_pitch))) >>> 16;
            state <= ST_DONE;
        end

        // ── 완료 ──────────────────────────────────────────────────────────
        ST_DONE: begin
            done  <= 1'b1;
            busy  <= 1'b0;
            state <= ST_IDLE;
        end
        endcase
    end
end

endmodule
`default_nettype wire
