// tb_hcsr04.v — HC-SR04 FSM 자체 점검 테스트벤치
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 테스트:
//   T1: 에코 1,750 μs → 기대 거리 = 1,750,000 ns / 580 ns = 30 cm (1750000/5800=301 ≈ 30cm)
//       실제: echo_cycles = 1750 * 100 = 175,000. 175000/5800 = 30 cm (정수 나눗셈)
//   T2: 에코 없음(타임아웃) → timeout=1

`timescale 1ns/1ps
module tb_hcsr04;

    reg clk, rst_n, start, echo_i;
    wire trig_o;
    wire [15:0] dist_cm;
    wire busy, done, timeout;

    hcsr04_ctrl #(
        .CLK_HZ      (100_000_000),
        .TRIG_CYC    (1000),
        .TIMEOUT_CYC (3_800_000)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (start),
        .trig_o  (trig_o),
        .echo_i  (echo_i),
        .dist_cm (dist_cm),
        .busy    (busy),
        .done    (done),
        .timeout (timeout)
    );

    // 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    integer fail = 0;

    task check_eq;
        input [31:0] got;
        input [31:0] exp;
        input [127:0] tag;
        begin
            if (got !== exp) begin
                $display("FAIL %s: got=%0d exp=%0d", tag, got, exp);
                fail = fail + 1;
            end
        end
    endtask

    // ---- T1: 30 cm 에코 ----
    initial begin
        rst_n = 0; start = 0; echo_i = 0;
        @(posedge clk); @(posedge clk);
        rst_n = 1;

        // --- T1: 에코 175000 cycles → 30 cm ---
        @(posedge clk);
        start = 1; @(posedge clk); start = 0;

        // TRIG 종료 대기 (1000 cycles)
        repeat(1050) @(posedge clk);

        // WAIT_HI: echo_i = 1 (에코 시작)
        echo_i = 1;
        // 에코 175000 cycles 유지
        repeat(175000) @(posedge clk);
        echo_i = 0;

        // done 대기
        wait(done === 1'b1);
        @(posedge clk);

        check_eq(dist_cm, 30, "T1_dist_cm");
        check_eq(timeout,  0, "T1_timeout");
        check_eq(busy,     0, "T1_busy");

        // --- T2: 타임아웃 ---
        @(posedge clk);
        start = 1; @(posedge clk); start = 0;

        // echo_i = 0 유지 → 타임아웃
        echo_i = 0;
        wait(done === 1'b1);
        @(posedge clk);

        check_eq(timeout, 1, "T2_timeout");
        check_eq(busy,    0, "T2_busy");

        if (fail == 0)
            $display("PASS tb_hcsr04: T1(30cm) T2(timeout) all checks OK");
        else
            $display("FAIL tb_hcsr04: %0d check(s) failed", fail);

        $finish;
    end

    // 최대 실행 시간 (타임아웃 사이클을 훨씬 넘음)
    initial begin
        #500_000_000;
        $display("FAIL tb_hcsr04: simulation timeout");
        $finish;
    end

endmodule
