// tb_fir.v — fir_core 자체 점검 테스트벤치
// capstone: mmio-fir-q1p15-mac-ip (stage T4)
// 형식: Verilog-2001, iverilog 호환
//
// 테스트 항목:
//   TC1. 이동평균 필터 (계수 = 1/16 × 16 = all 0x0800)
//        DC 입력 0x4000 → 출력 0x4000 (무손실 통과 확인)
//   TC2. 임펄스 응답 (입력 하나 보내고 계수의 첫 번째 값과 비교)
//   TC3. 포화 테스트 (최대값 계수 × 최대 입력 × 16탭 → 포화 → 0x7FFF)
//   TC4. bypass 모드 (enable=1, bypass=1 → 입력 = 출력)
//   TC5. enable=0 → m_axis_valid 출력 없음

`timescale 1ns/1ps
`default_nettype none

module tb_fir;

// ── 클럭/리셋 ─────────────────────────────────
reg clk;
reg rst_n;
initial clk = 1'b0;
always #5 clk = ~clk;  // 100 MHz

// ── DUT 포트 ─────────────────────────────────
reg  [15:0] s_axis_data;
reg         s_axis_valid;
wire        s_axis_ready;
wire [15:0] m_axis_data;
wire        m_axis_valid;
reg         m_axis_ready;
reg         coeff_we;
reg  [3:0]  coeff_addr;
reg  [15:0] coeff_wdat;
reg         enable;
reg         bypass;
wire        busy;

fir_core #(
    .NUM_TAPS(16),
    .DATA_W(16),
    .COEF_W(16),
    .ADDR_W(4)
) dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .s_axis_data  (s_axis_data),
    .s_axis_valid (s_axis_valid),
    .s_axis_ready (s_axis_ready),
    .m_axis_data  (m_axis_data),
    .m_axis_valid (m_axis_valid),
    .m_axis_ready (m_axis_ready),
    .coeff_we     (coeff_we),
    .coeff_addr   (coeff_addr),
    .coeff_wdat   (coeff_wdat),
    .enable       (enable),
    .bypass       (bypass),
    .busy         (busy)
);

// ── 오류 카운터 ──────────────────────────────
integer err_count;

// ── 헬퍼 태스크 ──────────────────────────────
// 계수 쓰기 (한 탭)
task write_coeff;
    input [3:0]  idx;
    input [15:0] val;
    begin
        @(posedge clk);
        coeff_we   <= 1'b1;
        coeff_addr <= idx;
        coeff_wdat <= val;
        @(posedge clk);
        coeff_we   <= 1'b0;
    end
endtask

// 모든 탭에 같은 값 쓰기
task fill_coeff;
    input [15:0] val;
    integer i;
    begin
        for (i = 0; i < 16; i = i + 1)
            write_coeff(i[3:0], val);
    end
endtask

// 샘플 1건 보내고 출력 기다리기
// (timeout: 50 클럭)
task send_sample;
    input  [15:0] sample_in;
    output [15:0] sample_out;
    integer tout;
    begin
        // 입력 제시
        @(negedge clk);
        s_axis_data  = sample_in;
        s_axis_valid = 1'b1;
        m_axis_ready = 1'b1;
        // ready가 올 때까지 대기
        tout = 0;
        while (!s_axis_ready && tout < 100) begin
            @(posedge clk);
            tout = tout + 1;
        end
        @(posedge clk);
        s_axis_valid = 1'b0;
        // 출력 대기
        tout = 0;
        while (!m_axis_valid && tout < 50) begin
            @(posedge clk);
            tout = tout + 1;
        end
        if (m_axis_valid)
            sample_out = m_axis_data;
        else
            sample_out = 16'hXXXX;
        @(posedge clk);
        m_axis_ready = 1'b0;
    end
endtask

// 출력이 없는지 확인 (20 클럭 동안)
task check_no_output;
    output reg ok;
    integer i;
    begin
        ok = 1'b1;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            if (m_axis_valid) ok = 1'b0;
        end
    end
endtask

// ── 메인 ─────────────────────────────────────
reg [15:0] got;
reg        no_out_ok;

initial begin
    // 초기화
    err_count    = 0;
    rst_n        = 1'b0;
    enable       = 1'b0;
    bypass       = 1'b0;
    s_axis_valid = 1'b0;
    s_axis_data  = 16'h0;
    m_axis_ready = 1'b1;
    coeff_we     = 1'b0;
    coeff_addr   = 4'h0;
    coeff_wdat   = 16'h0;
    got          = 16'h0;

    repeat(4) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);

    // ──────────────────────────────────────────
    // TC5: enable=0 → 출력 없음 확인
    // ──────────────────────────────────────────
    $display("TC5: enable=0 출력 없음 확인...");
    enable = 1'b0;
    bypass = 1'b0;
    fill_coeff(16'h0800);  // 계수 로드
    @(posedge clk);
    enable = 1'b0;
    @(negedge clk);
    s_axis_data  = 16'h4000;
    s_axis_valid = 1'b1;
    @(posedge clk);
    s_axis_valid = 1'b0;
    check_no_output(no_out_ok);
    if (!no_out_ok) begin
        $display("FAIL TC5: enable=0인데 출력 발생");
        err_count = err_count + 1;
    end else begin
        $display("PASS TC5");
    end

    // ──────────────────────────────────────────
    // TC1: 이동평균 (계수 = 0x0800 × 16 = Q1.15 0.0625 × 16 = 1.0)
    // DC 입력 0x4000 (0.5) → 시프트 레지스터 채워지면 출력 0x4000
    // ──────────────────────────────────────────
    $display("TC1: 이동평균 DC 통과...");
    enable = 1'b1;
    bypass = 1'b0;
    // 계수 이미 0x0800로 채워짐
    // 시프트 레지스터를 0x4000으로 채우기 (16 샘플 선행)
    begin : tc1_prime
        integer p;
        for (p = 0; p < 16; p = p + 1) begin
            send_sample(16'h4000, got);
        end
    end
    // 이제 시프트 레지스터 모두 0x4000; 다음 출력도 0x4000
    send_sample(16'h4000, got);
    // 허용 오차 ±2 (반올림 오차)
    if (got[15:0] < 16'h3FFE || got[15:0] > 16'h4002) begin
        $display("FAIL TC1: 이동평균 출력 0x%04x (기대 0x4000 ±2)", got);
        err_count = err_count + 1;
    end else begin
        $display("PASS TC1: 이동평균 출력 0x%04x", got);
    end

    // ──────────────────────────────────────────
    // TC2: 임펄스 응답 첫 번째 출력 확인
    // 계수를 [0]=0x4000 나머지=0 으로 설정
    // SR 모두 0 → 임펄스 1개 → 출력 = 0x4000 × 0x4000 >> (Q1.15×Q1.15)
    // Q1.15 0.5 × Q1.15 0.5 = Q2.30 0.25 → Q4.28 → Q1.15 반올림 ≈ 0x2000
    // ──────────────────────────────────────────
    $display("TC2: 임펄스 응답...");
    // 리셋해서 SR 초기화
    rst_n = 1'b0;
    repeat(2) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);
    // 계수 설정: 탭 0 = 0x4000, 나머지 = 0
    fill_coeff(16'h0000);
    write_coeff(4'h0, 16'h4000);
    enable = 1'b1;
    // 임펄스 (0x4000 하나, 이후 0)
    send_sample(16'h4000, got);
    // 출력 = Q1.15(0.5) × Q1.15(0.5) = Q1.15(0.25) = 0x2000 ± 2
    if (got[15:0] < 16'h1FFE || got[15:0] > 16'h2002) begin
        $display("FAIL TC2: 임펄스 첫 출력 0x%04x (기대 0x2000 ±2)", got);
        err_count = err_count + 1;
    end else begin
        $display("PASS TC2: 임펄스 첫 출력 0x%04x", got);
    end

    // ──────────────────────────────────────────
    // TC3: 양수 포화 테스트
    // 계수 모두 0x7FFF, 입력 0x7FFF → 16탭 모두 최대 → 포화 → 0x7FFF
    // ──────────────────────────────────────────
    $display("TC3: 양수 포화...");
    rst_n = 1'b0;
    repeat(2) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);
    fill_coeff(16'h7FFF);
    enable = 1'b1;
    // SR을 최대값으로 채우기
    begin : tc3_prime
        integer p;
        for (p = 0; p < 16; p = p + 1)
            send_sample(16'h7FFF, got);
    end
    send_sample(16'h7FFF, got);
    if (got !== 16'h7FFF) begin
        $display("FAIL TC3: 양수 포화 출력 0x%04x (기대 0x7FFF)", got);
        err_count = err_count + 1;
    end else begin
        $display("PASS TC3: 양수 포화 0x7FFF");
    end

    // ──────────────────────────────────────────
    // TC4: bypass 모드
    // ──────────────────────────────────────────
    $display("TC4: bypass 모드...");
    rst_n = 1'b0;
    repeat(2) @(posedge clk);
    rst_n = 1'b1;
    repeat(2) @(posedge clk);
    enable = 1'b1;
    bypass = 1'b1;
    send_sample(16'hABCD, got);
    if (got !== 16'hABCD) begin
        $display("FAIL TC4: bypass 출력 0x%04x (기대 0xABCD)", got);
        err_count = err_count + 1;
    end else begin
        $display("PASS TC4: bypass 출력 0x%04x", got);
    end

    // ── 최종 결과 ───────────────────────────────
    #20;
    if (err_count == 0)
        $display("PASS: 모든 테스트 통과 (TC1~TC5)");
    else
        $display("FAIL: %0d개 테스트 실패", err_count);

    $finish;
end

// ── 타임아웃 가드 ─────────────────────────────
initial begin
    #200000;
    $display("FAIL: 시뮬레이션 타임아웃");
    $finish;
end

endmodule

`default_nettype wire
