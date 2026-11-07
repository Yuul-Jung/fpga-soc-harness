// tb_debounce_cmp.v — 디바운스 3방식 비교 자기검사 테스트벤치
// 카운터·FSM·시프트레지스터 세 방식을 동시에 인스턴스화하고
// 동일한 글리치 패턴을 주입해 출력을 비교한다.
// 성공: "PASS" 출력, 실패: "FAIL: <설명>" 출력
// Verilog-2001, iverilog/verilator/yosys 호환.

`timescale 1ns / 1ps
`default_nettype none

module tb_debounce_cmp;

    // 세 방식의 안정 판정 사이클 수를 같은 값으로 고정
    localparam STABLE = 10;

    // 클럭: 10ns 주기 (100MHz)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    reg rst;
    reg btn_in;

    // 세 디바운스 모듈의 출력
    wire clean_c;  // 카운터
    wire clean_f;  // FSM
    wire clean_s;  // 시프트레지스터

    // 인스턴스화
    debounce_counter #(.STABLE_COUNT(STABLE)) u_cnt (
        .clk(clk), .rst(rst), .btn_in(btn_in), .clean_out(clean_c)
    );

    debounce_fsm #(.WAIT_COUNT(STABLE)) u_fsm (
        .clk(clk), .rst(rst), .btn_in(btn_in), .clean_out(clean_f)
    );

    debounce_sr #(.SR_WIDTH(STABLE)) u_sr (
        .clk(clk), .rst(rst), .btn_in(btn_in), .clean_out(clean_s)
    );

    // 오류 카운터
    integer fail_count;

    // 클럭 대기 태스크
    task wait_clk;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // 출력 확인 태스크
    task check_outputs;
        input expected;
        input [63:0] step_id;  // 테스트 단계 번호
        begin
            @(posedge clk); #1;  // 클럭 에지 직후 샘플링
            if (clean_c !== expected) begin
                $display("FAIL: step %0d counter out=%b, expected=%b", step_id, clean_c, expected);
                fail_count = fail_count + 1;
            end
            if (clean_f !== expected) begin
                $display("FAIL: step %0d fsm out=%b, expected=%b", step_id, clean_f, expected);
                fail_count = fail_count + 1;
            end
            if (clean_s !== expected) begin
                $display("FAIL: step %0d shift-reg out=%b, expected=%b", step_id, clean_s, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        btn_in = 0;
        wait_clk(5);
        rst = 0;
        wait_clk(2);

        // ── 테스트 1: 리셋 후 출력이 0인지 확인 ──
        @(posedge clk); #1;
        if (clean_c !== 1'b0) begin
            $display("FAIL: T1 counter after reset=%b", clean_c);
            fail_count = fail_count + 1;
        end
        if (clean_f !== 1'b0) begin
            $display("FAIL: T1 fsm after reset=%b", clean_f);
            fail_count = fail_count + 1;
        end
        if (clean_s !== 1'b0) begin
            $display("FAIL: T1 shift-reg after reset=%b", clean_s);
            fail_count = fail_count + 1;
        end

        // ── 테스트 2: 짧은 글리치 (STABLE-2 사이클) → 출력 변화 없어야 함 ──
        btn_in = 1;
        wait_clk(STABLE - 2);   // 안정 사이클보다 짧게 유지
        btn_in = 0;
        wait_clk(STABLE + 5);   // 충분히 기다려 출력 안정
        @(posedge clk); #1;
        if (clean_c !== 1'b0) begin
            $display("FAIL: T2 counter glitch not filtered: out=%b", clean_c);
            fail_count = fail_count + 1;
        end
        if (clean_f !== 1'b0) begin
            $display("FAIL: T2 fsm glitch not filtered: out=%b", clean_f);
            fail_count = fail_count + 1;
        end
        if (clean_s !== 1'b0) begin
            $display("FAIL: T2 shift-reg glitch not filtered: out=%b", clean_s);
            fail_count = fail_count + 1;
        end

        // ── 테스트 3: 안정적인 눌림 (STABLE+5 사이클) → 출력 1 ──
        btn_in = 1;
        wait_clk(STABLE + 5);
        @(posedge clk); #1;
        if (clean_c !== 1'b1) begin
            $display("FAIL: T3 counter stable press not detected: out=%b", clean_c);
            fail_count = fail_count + 1;
        end
        if (clean_f !== 1'b1) begin
            $display("FAIL: T3 fsm stable press not detected: out=%b", clean_f);
            fail_count = fail_count + 1;
        end
        if (clean_s !== 1'b1) begin
            $display("FAIL: T3 shift-reg stable press not detected: out=%b", clean_s);
            fail_count = fail_count + 1;
        end

        // ── 테스트 4: 짧은 해제 글리치 (STABLE-2 사이클) → 출력 1 유지 ──
        btn_in = 0;
        wait_clk(STABLE - 2);
        btn_in = 1;
        wait_clk(STABLE + 5);
        @(posedge clk); #1;
        if (clean_c !== 1'b1) begin
            $display("FAIL: T4 counter release glitch not filtered: out=%b", clean_c);
            fail_count = fail_count + 1;
        end
        if (clean_f !== 1'b1) begin
            $display("FAIL: T4 fsm release glitch not filtered: out=%b", clean_f);
            fail_count = fail_count + 1;
        end
        if (clean_s !== 1'b1) begin
            $display("FAIL: T4 shift-reg release glitch not filtered: out=%b", clean_s);
            fail_count = fail_count + 1;
        end

        // ── 테스트 5: 안정적인 해제 (STABLE+5 사이클) → 출력 0 ──
        btn_in = 0;
        wait_clk(STABLE + 5);
        @(posedge clk); #1;
        if (clean_c !== 1'b0) begin
            $display("FAIL: T5 counter stable release not detected: out=%b", clean_c);
            fail_count = fail_count + 1;
        end
        if (clean_f !== 1'b0) begin
            $display("FAIL: T5 fsm stable release not detected: out=%b", clean_f);
            fail_count = fail_count + 1;
        end
        if (clean_s !== 1'b0) begin
            $display("FAIL: T5 shift-reg stable release not detected: out=%b", clean_s);
            fail_count = fail_count + 1;
        end

        // ── 테스트 6: 연속 글리치 패턴 (교번 1·0, 각 2 사이클씩, 총 STABLE*4) → 출력 0 유지 ──
        begin : glitch_loop
            integer gi;
            for (gi = 0; gi < STABLE * 2; gi = gi + 1) begin
                btn_in = gi[0];  // 짝수=0, 홀수=1
                wait_clk(2);
            end
        end
        btn_in = 0;
        wait_clk(STABLE + 5);
        @(posedge clk); #1;
        if (clean_c !== 1'b0) begin
            $display("FAIL: T6 counter burst glitch not filtered: out=%b", clean_c);
            fail_count = fail_count + 1;
        end
        if (clean_f !== 1'b0) begin
            $display("FAIL: T6 fsm burst glitch not filtered: out=%b", clean_f);
            fail_count = fail_count + 1;
        end
        if (clean_s !== 1'b0) begin
            $display("FAIL: T6 shift-reg burst glitch not filtered: out=%b", clean_s);
            fail_count = fail_count + 1;
        end

        // ── 최종 판정 ──
        wait_clk(2);
        if (fail_count == 0) begin
            $display("PASS: 디바운스 3방식 비교 — 카운터·FSM·SR 모두 %0d 사이클 안정, 6개 테스트 통과", STABLE);
        end else begin
            $display("FAIL: %0d 개 오류 발생", fail_count);
        end

        $finish;
    end

    // 시뮬레이션 타임아웃 보호 (10000 사이클)
    initial begin
        #100000;
        $display("FAIL: 시뮬레이션 타임아웃");
        $finish;
    end

endmodule

`default_nettype wire
