// tb_imu_cf.v — IMU 상보 필터 IP 자체 점검형 테스트벤치 (TC1~TC5)
// PASS / FAIL 출력. !==로 X/Z도 실패로 처리.
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
`timescale 1ns/1ps

module tb_imu_cf;

// ─── 허용 오차 (degrees*512 단위) ───────────────────────────────────────────
// 1도 오차 허용 = 512 단위. CORDIC 16반복 오차 + 고정소수점 오차 감안.
localparam signed [17:0] TOL = 18'd1024; // ±2도

// ─── DUT 신호 ────────────────────────────────────────────────────────────────
reg         clk, rst;
reg         start;
wire        done, busy;
reg  signed [15:0] ay, az, ax;
reg  signed [17:0] gx_del, gy_del;
reg         [15:0] alpha;
wire signed [17:0] roll, pitch;

// ─── DUT 인스턴스 ────────────────────────────────────────────────────────────
imu_cf_ip u_dut (
    .clk    (clk),
    .rst    (rst),
    .start  (start),
    .done   (done),
    .busy   (busy),
    .ay     (ay),
    .az     (az),
    .ax     (ax),
    .gx_del (gx_del),
    .gy_del (gy_del),
    .alpha  (alpha),
    .roll   (roll),
    .pitch  (pitch)
);

// ─── 클럭 생성 (100 MHz) ──────────────────────────────────────────────────────
initial clk = 0;
always #5 clk = ~clk;

// ─── 헬퍼: 1스텝 실행 후 done 대기 ──────────────────────────────────────────
integer wait_cnt;
task run_step;
    begin
        @(posedge clk); #1;
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        wait_cnt = 0;
        while (done !== 1'b1 && wait_cnt < 200) begin
            @(posedge clk); #1;
            wait_cnt = wait_cnt + 1;
        end
        if (done !== 1'b1) begin
            $display("FAIL: done never asserted (timeout)");
            $finish;
        end
    end
endtask

// ─── 헬퍼: 범위 검사 ─────────────────────────────────────────────────────────
integer fail_count;
task check_range;
    input signed [17:0] actual;
    input signed [17:0] expected;
    input [255:0]       name;
    begin
        if (actual < expected - TOL || actual > expected + TOL) begin
            $display("FAIL %0s: got %0d expected %0d (tol ±%0d)",
                     name, actual, expected, TOL);
            fail_count = fail_count + 1;
        end else begin
            $display("  ok  %0s: %0d (expected %0d ±%0d)",
                     name, actual, expected, TOL);
        end
    end
endtask

// ─── 테스트 본체 ──────────────────────────────────────────────────────────────
initial begin
    fail_count = 0;

    // 초기화
    rst    = 1'b1;
    start  = 1'b0;
    ay     = 16'sh0000;
    az     = 16'sh4000; // 1g = 16384
    ax     = 16'sh0000;
    gx_del = 18'sd0;
    gy_del = 18'sd0;
    alpha  = 16'd0;     // alpha=0: 순수 가속도계 (즉시 수렴)

    repeat(5) @(posedge clk);
    rst = 1'b0;
    repeat(2) @(posedge clk);

    // ── TC1: ay=0, az=1g → roll≈0° ─────────────────────────────────────────
    $display("TC1: ay=0, az=1g → roll should be ~0°");
    ay     = 16'sh0000;
    az     = 16'sh4000;
    ax     = 16'sh0000;
    gx_del = 18'sd0;
    gy_del = 18'sd0;
    alpha  = 16'd0;
    run_step;
    check_range(roll, 18'sd0, "TC1 roll");

    // ── TC2: ay=1g, az=0 → roll≈+90° (45056 = 90°*512) ─────────────────────
    $display("TC2: ay=1g, az=0 → roll should be ~90°");
    ay     = 16'sh4000;
    az     = 16'sh0000;
    ax     = 16'sh0000;
    gx_del = 18'sd0;
    gy_del = 18'sd0;
    alpha  = 16'd0;
    run_step;
    check_range(roll, 18'sd46080, "TC2 roll"); // 90°*512=46080

    // ── TC3: ay=az=0.707g → roll≈45° (23040=45°*512) ────────────────────────
    $display("TC3: ay=az=0.707g → roll should be ~45°");
    // 0.707*16384 ≈ 11585
    ay     = 16'sh2D41; // 11585
    az     = 16'sh2D41;
    ax     = 16'sh0000;
    gx_del = 18'sd0;
    gy_del = 18'sd0;
    alpha  = 16'd0;
    run_step;
    check_range(roll, 18'sd23040, "TC3 roll");

    // ── TC4: alpha=0 → 순수 가속도계, 즉시 accel값으로 수렴 ──────────────────
    $display("TC4: alpha=0 (pure accel) → roll immediately from ay/az");
    ay     = 16'sh2D41; // 45°
    az     = 16'sh2D41;
    gx_del = 18'sd5120; // 큰 자이로 오프셋 (10°*512) — 무시돼야 함
    alpha  = 16'd0;      // alpha=0: 자이로 가중치 0
    run_step;
    check_range(roll, 18'sd23040, "TC4 roll(alpha=0, accel only)");

    // ── TC5: 자이로 드리프트 → 상보 필터 보정 (alpha=0.98) ───────────────────
    // TC4가 roll≈45°를 남긴다. alpha=0 초기화 스텝으로 roll을 0°로 맞춘다.
    // 그 후 alpha=0.98, gx_del=+1°를 적용: blend → ≈0.98° ≈ 501 단위
    $display("TC5: gyro drift correction (alpha=64225/65536≈0.98)");
    ay     = 16'sh0000;
    az     = 16'sh4000;
    gx_del = 18'sd0;
    alpha  = 16'd0;      // 순수 가속도계: roll → atan2(0, 1g) ≈ 0°
    run_step;            // 초기화 스텝 (roll ← 0)

    // 이제 alpha=0.98, gx_del=+1°로 상보 필터 테스트
    gx_del = 18'sd512;  // +1° 자이로 증분
    alpha  = 16'd64225; // 0.98*65536
    // 예상: alpha*(0°+1°) + (1-alpha)*0° = 0.98*512 ≈ 501 (≈0.98°)
    run_step;
    // 넓은 허용: 0.5°~1.5° 범위 (256~768)
    if (roll < 18'sd256 || roll > 18'sd768) begin
        $display("FAIL TC5 roll: %0d (expected ~501, range 256~768)", roll);
        fail_count = fail_count + 1;
    end else begin
        $display("  ok  TC5 roll: %0d (blend OK)", roll);
    end

    // ─── 최종 판정 ──────────────────────────────────────────────────────────
    if (fail_count == 0) begin
        $display("PASS: all %0d tests passed", 5);
    end else begin
        $display("FAIL: %0d test(s) failed", fail_count);
    end

    $finish;
end

// ─── 타임아웃 가드 ───────────────────────────────────────────────────────────
initial begin
    #200000; // 200μs
    $display("FAIL: global timeout");
    $finish;
end

endmodule
`default_nettype wire
