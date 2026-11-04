// tb_lqr_ctrl.v — LQR 제어기 IP 자체 점검형 테스트벤치 (TC1~TC5)
// PASS / FAIL 출력. !==로 X/Z도 실패로 처리.
// lqr_ip 코어를 직접 구동 (AXI 래퍼 없이).
//
// TC1: 모든 K, 상태 0 → u = 0
// TC2: K0=1.0, x=1.0, 나머지 0 → u = 1.0
// TC3: K3=0.5, dtheta=2.0, 나머지 0 → u = 1.0
// TC4: K2=-1.0, theta=2.0, 나머지 0 → u = -2.0 (Q8.8: 0xFE00)
// TC5: 모든 K=64.0, 모든 상태=64.0 → 오버플로 → 포화(0x7FFF)
//
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)
`default_nettype none
`timescale 1ns/1ps

module tb_lqr_ctrl;

// ─── DUT 신호 ────────────────────────────────────────────────────────────────
reg         clk, rst;
reg         start;
wire        done, busy;
reg  signed [15:0] k0, k1, k2, k3;
reg  signed [15:0] x_state, dx_state, theta, dtheta;
wire signed [15:0] u_out;

// ─── DUT 인스턴스 ────────────────────────────────────────────────────────────
lqr_ip u_dut (
    .clk      (clk),
    .rst      (rst),
    .start    (start),
    .done     (done),
    .busy     (busy),
    .k0       (k0),
    .k1       (k1),
    .k2       (k2),
    .k3       (k3),
    .x_state  (x_state),
    .dx_state (dx_state),
    .theta    (theta),
    .dtheta   (dtheta),
    .u_out    (u_out)
);

// ─── 클럭 (100 MHz) ──────────────────────────────────────────────────────────
initial clk = 0;
always  #5 clk = ~clk;

// ─── 헬퍼 태스크: start 펄스 → done 대기 ────────────────────────────────────
integer wait_cnt;
task run_lqr;
    begin
        @(posedge clk); #1;
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;
        wait_cnt = 0;
        while (done !== 1'b1 && wait_cnt < 20) begin
            @(posedge clk); #1;
            wait_cnt = wait_cnt + 1;
        end
        if (done !== 1'b1) begin
            $display("FAIL: done never asserted (timeout)");
            $finish;
        end
    end
endtask

// ─── 헬퍼 함수: Q8.8 정수 표현 → 소수 문자열 (디버그용) ────────────────────
// (실제 비교는 정수로 수행)

// ─── 검증 헬퍼 ───────────────────────────────────────────────────────────────
integer fail_cnt;
task check_u;
    input signed [15:0] expected;
    input [63:0] tc_name; // 최대 8자 (8바이트)
    begin
        if (u_out !== expected) begin
            $display("FAIL TC%0s: u_out=%0d (0x%04X), expected=%0d (0x%04X)",
                     tc_name, u_out, u_out[15:0], expected, expected[15:0]);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("ok   TC%0s: u_out=0x%04X (%0d)", tc_name, u_out[15:0], u_out);
        end
    end
endtask

// ─── 메인 ────────────────────────────────────────────────────────────────────
integer tc;
initial begin
    fail_cnt = 0;

    // 초기화
    rst = 1'b1; start = 1'b0;
    k0 = 0; k1 = 0; k2 = 0; k3 = 0;
    x_state = 0; dx_state = 0; theta = 0; dtheta = 0;
    repeat(4) @(posedge clk);
    rst = 1'b0;
    @(posedge clk); #1;

    // ── TC1: 전부 0 → u = 0 ─────────────────────────────────────────────────
    k0=16'sd0; k1=16'sd0; k2=16'sd0; k3=16'sd0;
    x_state=16'sd0; dx_state=16'sd0; theta=16'sd0; dtheta=16'sd0;
    run_lqr;
    check_u(16'sd0, "1");

    // ── TC2: K0=1.0(0x0100), x=1.0(0x0100), 나머지 0 → u=1.0(0x0100) ─────
    // K0*x = 0x0100 * 0x0100 = 0x0001_0000 (Q16.16). bits[23:8]=0x0100.
    k0=16'sh0100; k1=16'sd0; k2=16'sd0; k3=16'sd0;
    x_state=16'sh0100; dx_state=16'sd0; theta=16'sd0; dtheta=16'sd0;
    run_lqr;
    check_u(16'sh0100, "2");

    // ── TC3: K3=0.5(0x0080), dtheta=2.0(0x0200), 나머지 0 → u=1.0(0x0100)
    // K3*dtheta = 0x0080 * 0x0200 = 0x0001_0000 (Q16.16). bits[23:8]=0x0100.
    k0=16'sd0; k1=16'sd0; k2=16'sd0; k3=16'sh0080;
    x_state=16'sd0; dx_state=16'sd0; theta=16'sd0; dtheta=16'sh0200;
    run_lqr;
    check_u(16'sh0100, "3");

    // ── TC4: K2=-1.0(0xFF00), theta=2.0(0x0200), 나머지 0 → u=-2.0(0xFE00)
    // K2*theta = 0xFF00(=-256Q8.8→-1.0) * 0x0200(=512Q8.8→2.0)
    //          = -256 * 512 = -131072 = 0xFFFE_0000 (Q16.16)
    // bits[23:8] = 0xFE00 (-2.0 in Q8.8)
    k0=16'sd0; k1=16'sd0; k2=16'shFF00; k3=16'sd0;
    x_state=16'sd0; dx_state=16'sd0; theta=16'sh0200; dtheta=16'sd0;
    run_lqr;
    check_u(16'shFE00, "4");

    // ── TC5: K*=64.0(0x4000), state=64.0(0x4000) → 각 항 = 16384.0
    //   sum = 4 * 16384.0 = 65536.0 → 오버플로 → 포화 0x7FFF
    // K*state = 0x4000 * 0x4000 = 0x1000_0000 (Q16.16) = 16384.0
    // 4개 합 = 0x4000_0000 (Q16.16) = 65536.0 → Q8.8로 변환 불가 (>127.996)
    // 양의 오버플로 → 0x7FFF
    k0=16'sh4000; k1=16'sh4000; k2=16'sh4000; k3=16'sh4000;
    x_state=16'sh4000; dx_state=16'sh4000; theta=16'sh4000; dtheta=16'sh4000;
    run_lqr;
    check_u(16'sh7FFF, "5");

    // ── 결과 ─────────────────────────────────────────────────────────────────
    if (fail_cnt == 0) begin
        $display("PASS: 모든 TC (%0d개) 통과", 5);
    end else begin
        $display("FAIL: %0d개 TC 실패", fail_cnt);
    end
    $finish;
end

// ─── 타임아웃 보호 ───────────────────────────────────────────────────────────
initial begin
    #50000;
    $display("FAIL: 전체 타임아웃");
    $finish;
end

endmodule
`default_nettype wire
