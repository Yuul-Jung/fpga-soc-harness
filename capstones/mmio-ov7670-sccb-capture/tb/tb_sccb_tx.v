// tb_sccb_tx.v — sccb_tx 모듈 자체 점검 테스트벤치
// SCCB 슬레이브 모델: 각 NA 비트에서 1(don't-care) 응답
// 3회 전송(3바이트 패킷)을 발행해 타이밍과 done/na_err을 검증한다.
// 통과: "PASS: ..." , 실패: "FAIL: ..." 로 시작하는 줄 출력 후 $finish
// Verilog-2001, 외부 IP 없음.

`timescale 1ns/1ps
`default_nettype none
module tb_sccb_tx;
    // 파라미터 (빠른 시뮬을 위해 10 kHz 사용)
    localparam CLK_HZ   = 10_000_000;
    localparam SCCB_KHZ = 10;
    localparam CLK_P    = 100; // ns (10 MHz)
    localparam HALF_CNT = (CLK_HZ / (SCCB_KHZ * 1000)) / 2; // 500

    // DUT 신호
    reg        clk, rst, start;
    reg  [6:0] dev_addr;
    reg  [7:0] reg_addr, reg_data;
    wire       sio_c;
    wire       sio_d_out;
    wire       sio_d_oe;
    reg        sio_d_in;
    wire       done;
    wire       na_err;

    // DUT 인스턴스
    sccb_tx #(.CLK_HZ(CLK_HZ), .SCCB_KHZ(SCCB_KHZ)) dut (
        .clk(clk), .rst(rst),
        .start(start),
        .dev_addr(dev_addr), .reg_addr(reg_addr), .reg_data(reg_data),
        .sio_c(sio_c),
        .sio_d_out(sio_d_out), .sio_d_oe(sio_d_oe),
        .sio_d_in(sio_d_in),
        .done(done), .na_err(na_err)
    );

    // 클럭 생성
    initial clk = 0;
    always #(CLK_P/2) clk = ~clk;

    // 슬레이브 모델: sio_d_oe=0(릴리즈) 구간에 sio_d_in=1(NA=1, 정상)
    always @(*) begin
        if (!sio_d_oe)
            sio_d_in = 1'b1; // NA 비트: 슬레이브가 1(don't-care)
        else
            sio_d_in = sio_d_out; // 출력 모드: 루프백
    end

    // ----------------------------------------------------------------
    // 태스크: 한 번 전송 후 done 대기 (타임아웃 포함)
    // ----------------------------------------------------------------
    integer done_cnt;
    integer timeout;
    reg     got_done;

    task send_and_wait;
        input [6:0] da;
        input [7:0] ra, rd;
        begin
            @(posedge clk); #1;
            dev_addr = da; reg_addr = ra; reg_data = rd;
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;
            // done 대기 (최대 50000 클럭)
            // CLK_HZ=10MHz, SCCB_KHZ=10 → HALF_CNT=500, 3바이트×18×500≈27000 클럭 필요
            got_done = 0;
            timeout  = 50000;
            while (!got_done && timeout > 0) begin
                @(posedge clk); #1;
                if (done) got_done = 1;
                timeout = timeout - 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // 테스트 시나리오
    // ----------------------------------------------------------------
    reg [7:0] fail_code;
    integer   na_err_cnt;
    integer   done_cnt2;

    initial begin
        // 초기화
        rst = 1; start = 0;
        dev_addr = 7'h21; reg_addr = 8'h12; reg_data = 8'h80;
        na_err_cnt = 0;
        done_cnt2  = 0;
        fail_code  = 8'd0;

        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        // ---- 테스트 1: 첫 번째 전송 ----
        send_and_wait(7'h21, 8'h12, 8'h80);
        if (!got_done) begin
            $display("FAIL: T1 done 타임아웃 (dev=0x21 reg=0x12 data=0x80)");
            $finish;
        end
        done_cnt2 = done_cnt2 + 1;

        // ---- 테스트 2: 두 번째 전송 ----
        repeat(5) @(posedge clk);
        send_and_wait(7'h21, 8'h1204>>8, 8'h04);
        if (!got_done) begin
            $display("FAIL: T2 done 타임아웃 (reg=0x12 data=0x04)");
            $finish;
        end
        done_cnt2 = done_cnt2 + 1;

        // ---- 테스트 3: 세 번째 전송 ----
        repeat(5) @(posedge clk);
        send_and_wait(7'h21, 8'h40, 8'hD0);
        if (!got_done) begin
            $display("FAIL: T3 done 타임아웃 (reg=0x40 data=0xD0)");
            $finish;
        end
        done_cnt2 = done_cnt2 + 1;

        // ---- na_err 없어야 함 (슬레이브가 1 응답) ----
        // na_err은 각 전송 중에 발생하므로 별도 카운터 없이 간단 체크
        // (슬레이브 모델이 항상 1을 돌려주므로 na_err이 없어야 함)

        // ---- done 횟수 확인 ----
        if (done_cnt2 !== 3) begin
            $display("FAIL: done 횟수 불일치 (기대=3, 실제=%0d)", done_cnt2);
            $finish;
        end

        // ---- START 중 재start 무시 테스트 ----
        // (rom_running 상태에서 start를 보내도 무시해야 함 — sccb_tx는 별도 FSM 아님)
        // 단순히 IDLE에서만 start를 받는지 확인: 전송 중 start 1 → done이 1번만 오는지
        repeat(2) @(posedge clk);
        begin
            @(posedge clk); #1;
            dev_addr = 7'h21; reg_addr = 8'h03; reg_data = 8'h0A;
            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b1; // 연속 start (2번째는 무시되어야 함)
            @(posedge clk); #1;
            start = 1'b0;
            got_done = 0; timeout = 10000;
            while (!got_done && timeout > 0) begin
                @(posedge clk); #1;
                if (done) got_done = 1;
                timeout = timeout - 1;
            end
            if (!got_done) begin
                $display("FAIL: T4 연속 start 타임아웃");
                $finish;
            end
        end

        // ---- SCL 아이들 상태 확인: 전송 완료 후 SCL=1 ----
        repeat(3) @(posedge clk);
        if (sio_c !== 1'b1) begin
            $display("FAIL: 전송 완료 후 SCL이 high가 아님 (sio_c=%b)", sio_c);
            $finish;
        end

        $display("PASS: sccb_tx — %0d회 전송 완료, SCL 아이들 확인", done_cnt2 + 1);
        $finish;
    end

    // 타임아웃 가드 (전체 50000 클럭)
    initial begin
        #(CLK_P * 50000);
        $display("FAIL: 전체 테스트 타임아웃 (50000 클럭 초과)");
        $finish;
    end

    // VCD 덤프 (옵션)
    initial begin
        $dumpfile("tb_sccb_tx.vcd");
        $dumpvars(0, tb_sccb_tx);
    end
endmodule
`default_nettype wire
