// tb_loop_jitter_mon.v — 자체 점검형 시험 (Verilog-2001)
// 하네스 직접 작성 원본.
//
// 종료 조건:
//   "PASS" 로 시작하는 줄 출력 → vvp 종료 코드 0 (Makefile이 grep으로 확인)
//   "FAIL" 로 시작하는 줄 출력 → 오류로 처리
//
// 시험 케이스:
//   T01: 리셋 직후 초기값 확인
//   T02: enable 없이 tick을 넣어도 통계 불변 확인
//   T03: enable 후 첫 에지는 카운터만 초기화(통계 미갱신)
//   T04: 두 번째 에지에서 주기 기록 (PERIOD_LAST, MIN, MAX = 100)
//   T05: 주기 200 → PERIOD_MAX=200, PERIOD_MIN 유지(100)
//   T06: 주기 50 → PERIOD_MIN=50, PERIOD_MAX 유지(200)
//   T07: THRESHOLD=120, 주기 200 → OVERRUN_CNT=1, IRQ_STATUS[0]=1
//   T08: IRQ_ENABLE=1 → irq 출력 활성 확인
//   T09: IRQ_STATUS W1C → irq_status 클리어 (enable 중 IRQ_ENABLE=1 유지)
//   T10: stats_clear(CTRL[1]=1) → min/max/overrun/irq_status 초기화
//   T11: stats_clear 후 측정 재시작 (PERIOD_LAST=80 확인)
//   T12: ID, VER 관리 레지스터 읽기 확인
//   T13: THRESHOLD=0 → 오버런 검출 비활성 (오버런 카운트 불변)
//
`timescale 1ns/1ps

module tb_loop_jitter_mon;

    // ----------------------------------------------------------------
    // 클럭·리셋
    // ----------------------------------------------------------------
    reg clk;
    reg rst;

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz (주기 10 ns)

    // ----------------------------------------------------------------
    // DUT 포트
    // ----------------------------------------------------------------
    reg        tick_in;
    reg        sel;
    reg        we;
    reg [15:0] offset;
    reg [31:0] wdata;
    wire [31:0] rdata;
    wire        irq;

    loop_jitter_mon dut (
        .clk     (clk),
        .rst     (rst),
        .tick_in (tick_in),
        .sel     (sel),
        .we      (we),
        .offset  (offset),
        .wdata   (wdata),
        .rdata   (rdata),
        .irq     (irq)
    );

    // ----------------------------------------------------------------
    // 버스 접근 태스크
    // ----------------------------------------------------------------
    task bus_write;
        input [15:0] off;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            sel    = 1'b1;
            we     = 1'b1;
            offset = off;
            wdata  = data;
            @(posedge clk); #1;
            sel = 1'b0; we = 1'b0;
        end
    endtask

    task bus_read;
        input  [15:0] off;
        output [31:0] data;
        begin
            @(posedge clk); #1;
            sel    = 1'b1;
            we     = 1'b0;
            offset = off;
            wdata  = 32'h0;
            #1; // rdata는 조합 출력이므로 같은 사이클에 유효
            data = rdata;
            @(posedge clk); #1;
            sel = 1'b0;
        end
    endtask

    // ----------------------------------------------------------------
    // tick 발생 태스크: 지정 사이클 후 상승 에지 발생
    // ----------------------------------------------------------------
    task send_tick;
        input [31:0] period_clk; // 이 사이클 뒤에 tick_in 토글 (상승→하강)
        begin
            repeat (period_clk) @(posedge clk);
            #1; tick_in = 1'b1;
            @(posedge clk); #1;
            tick_in = 1'b0;
        end
    endtask

    // ----------------------------------------------------------------
    // 검증 헬퍼
    // ----------------------------------------------------------------
    integer fail_count;

    task check;
        input [255:0] name;
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s: got 0x%08X, exp 0x%08X", name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // 시험 본문
    // ----------------------------------------------------------------
    reg [31:0] rd;

    initial begin
        // 초기화
        fail_count = 0;
        rst     = 1'b1;
        tick_in = 1'b0;
        sel     = 1'b0;
        we      = 1'b0;
        offset  = 16'h0;
        wdata   = 32'h0;

        repeat (4) @(posedge clk);
        #1; rst = 1'b0;
        repeat (2) @(posedge clk); #1;

        // -------------------------------------------------------
        // T01: 리셋 직후 초기값
        // -------------------------------------------------------
        bus_read(16'h0000, rd); check("T01_CTRL",        rd, 32'h0);
        bus_read(16'h0004, rd); check("T01_PERIOD_MIN",  rd, 32'hFFFF_FFFF);
        bus_read(16'h0008, rd); check("T01_PERIOD_MAX",  rd, 32'h0);
        bus_read(16'h000C, rd); check("T01_PERIOD_LAST", rd, 32'h0);
        bus_read(16'h0010, rd); check("T01_OVERRUN_CNT", rd, 32'h0);
        bus_read(16'h0014, rd); check("T01_THRESHOLD",   rd, 32'h0);
        bus_read(16'hFFF8, rd); check("T01_IRQ_STATUS",  rd, 32'h0);
        bus_read(16'hFFFC, rd); check("T01_IRQ_ENABLE",  rd, 32'h0);
        check("T01_irq", {31'h0, irq}, 32'h0);

        // -------------------------------------------------------
        // T02: enable 없이 tick — 통계 불변
        // -------------------------------------------------------
        // tick_in=1 → 1 → 0 (에지 발생)
        @(posedge clk); #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;
        bus_read(16'h0004, rd); check("T02_PERIOD_MIN_unchanged", rd, 32'hFFFF_FFFF);
        bus_read(16'h000C, rd); check("T02_PERIOD_LAST_unchanged", rd, 32'h0);

        // -------------------------------------------------------
        // T03: enable 후 첫 에지는 카운터만 초기화
        // -------------------------------------------------------
        bus_write(16'h0000, 32'h1); // CTRL: enable_meas=1
        bus_read(16'h0000, rd); check("T03_CTRL_enabled", rd, 32'h1);

        // 첫 에지
        @(posedge clk); #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (3) @(posedge clk); #1;

        // 첫 에지 직후 — first_tick이므로 통계는 아직 갱신 안 됨
        bus_read(16'h000C, rd); check("T03_PERIOD_LAST_still0", rd, 32'h0);
        bus_read(16'h0004, rd); check("T03_MIN_still_max",      rd, 32'hFFFF_FFFF);

        // -------------------------------------------------------
        // T04: 두 번째 에지 (100클럭 후) — PERIOD_LAST=100, MIN=100, MAX=100
        // -------------------------------------------------------
        // 카운터는 첫 에지 이후 클럭 카운트 중. 아직 몇 클럭이 경과했으므로
        // 정확히 100이 되려면 카운터를 리셋 직후부터 맞춰야 함.
        // 여기서는 별도 주기를 보장하기 위해 현재 카운터 상태를 무시하고
        // 첫 에지를 기준으로 100클럭 후 두 번째 에지를 발생시킨다.
        // 위에서 첫 에지 발생 후 3+1(bus_read×2: 각 2클럭) = 약 7클럭 경과.
        // 단, bus_read가 2클럭씩 소비한다고 가정하면:
        //   첫 에지 후 경과 클럭 수 = 약 (1+1)×bus_reads + repeat = 모호
        // 따라서 T04는 고정 주기 대신 "2번째 에지를 적당히 늦게"로 구성.

        // 간단히: stats_clear 후 enable, 100클럭 정확히 맞추기
        bus_write(16'h0000, 32'h3); // CTRL: stats_clear=1, enable=1
        repeat (2) @(posedge clk); #1; // 클리어 적용 대기

        // 첫 에지
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        // 정확히 100클럭 대기 후 두 번째 에지
        repeat (99) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1; // 동기화(3클럭) + 여유

        bus_read(16'h000C, rd); check("T04_PERIOD_LAST_100", rd, 32'd100);
        bus_read(16'h0004, rd); check("T04_PERIOD_MIN_100",  rd, 32'd100);
        bus_read(16'h0008, rd); check("T04_PERIOD_MAX_100",  rd, 32'd100);

        // -------------------------------------------------------
        // T05: 주기 200 → MAX=200, MIN 유지 (100)
        // -------------------------------------------------------
        repeat (199) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;

        bus_read(16'h000C, rd); check("T05_PERIOD_LAST_200", rd, 32'd200);
        bus_read(16'h0004, rd); check("T05_MIN_still_100",   rd, 32'd100);
        bus_read(16'h0008, rd); check("T05_MAX_200",         rd, 32'd200);

        // -------------------------------------------------------
        // T06: 주기 50 → MIN=50, MAX 유지 (200)
        // -------------------------------------------------------
        repeat (49) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;

        bus_read(16'h000C, rd); check("T06_PERIOD_LAST_50", rd, 32'd50);
        bus_read(16'h0004, rd); check("T06_MIN_50",         rd, 32'd50);
        bus_read(16'h0008, rd); check("T06_MAX_200",        rd, 32'd200);

        // -------------------------------------------------------
        // T07: THRESHOLD=120, 주기 200 → OVERRUN_CNT=1, IRQ_STATUS[0]=1
        // -------------------------------------------------------
        bus_write(16'h0014, 32'd120); // THRESHOLD = 120

        repeat (199) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;

        bus_read(16'h0010, rd); check("T07_OVERRUN_CNT_1",    rd, 32'd1);
        bus_read(16'hFFF8, rd); check("T07_IRQ_STATUS_1",     rd, 32'h1);

        // -------------------------------------------------------
        // T08: IRQ_ENABLE=1 → irq 출력 활성
        // -------------------------------------------------------
        bus_write(16'hFFFC, 32'h1); // IRQ_ENABLE=1
        @(posedge clk); #1; // 반영 대기
        check("T08_irq_active", {31'h0, irq}, 32'h1);

        // -------------------------------------------------------
        // T09: IRQ_STATUS W1C → irq_status 클리어 (IRQ_ENABLE은 유지)
        // -------------------------------------------------------
        bus_write(16'hFFF8, 32'h1); // W1C: IRQ_STATUS[0] 클리어
        @(posedge clk); #1;
        bus_read(16'hFFF8, rd); check("T09_IRQ_STATUS_cleared", rd, 32'h0);
        check("T09_irq_low", {31'h0, irq}, 32'h0);

        // -------------------------------------------------------
        // T10: stats_clear(CTRL[1]=1) → 통계 초기화
        // -------------------------------------------------------
        // 먼저 IRQ 다시 발생시키기
        repeat (199) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;

        bus_read(16'h0010, rd); check("T10_pre_clear_overrun", rd, 32'd2); // 2번 오버런
        bus_read(16'hFFF8, rd); check("T10_pre_clear_irq_st",  rd, 32'h1);

        // stats_clear
        bus_write(16'h0000, 32'h3); // CTRL[1:0] = 2'b11 (stats_clear + enable)
        repeat (2) @(posedge clk); #1;

        bus_read(16'h0004, rd); check("T10_MIN_reset",          rd, 32'hFFFF_FFFF);
        bus_read(16'h0008, rd); check("T10_MAX_reset",          rd, 32'h0);
        bus_read(16'h000C, rd); check("T10_LAST_reset",         rd, 32'h0);
        bus_read(16'h0010, rd); check("T10_OVERRUN_CNT_reset",  rd, 32'h0);
        bus_read(16'hFFF8, rd); check("T10_IRQ_STATUS_reset",   rd, 32'h0);
        check("T10_irq_low", {31'h0, irq}, 32'h0); // IRQ_ENABLE=1이지만 irq_status=0

        // -------------------------------------------------------
        // T11: stats_clear 후 측정 재시작 (PERIOD_LAST=80 확인)
        // -------------------------------------------------------
        // stats_clear 직후 first_tick=1이므로 첫 에지를 발생시켜 카운터 초기화
        @(posedge clk); #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        // 80클럭 후 두 번째 에지
        repeat (79) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;

        bus_read(16'h000C, rd); check("T11_PERIOD_LAST_80", rd, 32'd80);
        bus_read(16'h0004, rd); check("T11_MIN_80",         rd, 32'd80);
        bus_read(16'h0008, rd); check("T11_MAX_80",         rd, 32'd80);

        // -------------------------------------------------------
        // T12: ID, VER 관리 레지스터 확인
        // -------------------------------------------------------
        bus_read(16'hFFF0, rd); check("T12_ID",  rd, 32'h4A4D_4F4E); // 'J','M','O','N'
        bus_read(16'hFFF4, rd); check("T12_VER", rd, 32'h0100_0100);

        // -------------------------------------------------------
        // T13: THRESHOLD=0 → 오버런 비활성 (카운트 불변)
        // -------------------------------------------------------
        bus_write(16'h0014, 32'h0); // THRESHOLD = 0 (비활성)
        bus_read(16'h0010, rd);
        // stats_clear 없이 현재 카운트 저장
        // 임의로 큰 주기 발생 (1000클럭)
        repeat (999) @(posedge clk);
        #1; tick_in = 1'b1;
        @(posedge clk); #1; tick_in = 1'b0;
        repeat (5) @(posedge clk); #1;

        // OVERRUN_CNT는 rd(이전값)와 같아야 함 (threshold=0이므로 증가 없음)
        bus_read(16'h0010, rd);
        // 여기서 rd가 0이면 PASS (stats_clear 후 카운트가 0 → threshold 비활성이면 그대로)
        check("T13_OVERRUN_CNT_unchanged", rd, 32'h0);
        bus_read(16'hFFF8, rd); check("T13_IRQ_STATUS_no_new_overrun", rd, 32'h0);

        // -------------------------------------------------------
        // 최종 결과
        // -------------------------------------------------------
        repeat (5) @(posedge clk);
        if (fail_count == 0) begin
            $display("PASS: 모든 시험 통과 (%0d개 항목)", 13);
        end else begin
            $display("FAIL: %0d개 항목 불일치", fail_count);
        end
        $finish;
    end

    // 타임아웃 (10 μs = 10000 ns)
    initial begin
        #100_000;
        $display("FAIL: 시뮬레이션 타임아웃 (100 us 초과)");
        $finish;
    end

endmodule
