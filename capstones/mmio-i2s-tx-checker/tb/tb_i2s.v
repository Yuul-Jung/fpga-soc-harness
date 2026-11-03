// tb_i2s.v — I2S TX + 클럭 생성기 통합 검증 테스트벤치
// 검사 항목:
//   CHECK 1: BCLK 주기 = 320 ns (100 MHz / 32 × 2 = 3.125 MHz)
//   CHECK 2: LRCLK 주기 = 10240 ns (100 MHz / 1024 = 97.656 kHz)
//   CHECK 3: LRCLK 반주기당 BCLK 하강 에지 15~16개 (fork...join + disable)
//   CHECK 4: L_DATA=0x8001 기록 후 TX_EN 활성화; LRCLK 하강 뒤 첫 번째·두 번째
//            BCLK 하강 에지에서 SDIN = 1(bit15), 0(bit14)
// 통과하면 "PASS all checks", 실패하면 "FAIL: N check(s) failed"로 시작하는 줄 출력
// 비교는 !==을 사용해 X/Z도 실패로 센다.
`timescale 1ns/1ps
module tb_i2s;

    // -------------------------------------------------------
    // 신호 선언
    // -------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         sel;
    reg         we;
    reg  [15:0] off_r;
    reg  [31:0] wdata;
    wire [31:0] rdata;
    wire        sdin;
    wire        irq;
    wire        mclk, bclk, lrclk;

    // 모듈 수준 보조 변수 (iverilog 호환)
    integer     fail_cnt;
    time        t0, t1;
    integer     bclk_half_cnt;

    // -------------------------------------------------------
    // DUT 인스턴스
    // -------------------------------------------------------
    i2s_clk_gen u_clkgen (
        .clk   (clk),
        .rst   (rst),
        .mclk  (mclk),
        .bclk  (bclk),
        .lrclk (lrclk)
    );

    i2s_tx u_dut (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel),
        .we    (we),
        .off   (off_r),
        .wdata (wdata),
        .rdata (rdata),
        .mclk  (mclk),
        .bclk  (bclk),
        .lrclk (lrclk),
        .sdin  (sdin),
        .irq   (irq)
    );

    // -------------------------------------------------------
    // 100 MHz 클럭 (10 ns 주기)
    // -------------------------------------------------------
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------
    // do_write 태스크 — 1사이클 MMIO 쓰기
    // -------------------------------------------------------
    task do_write;
        input [15:0] addr;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            sel = 1'b1; we = 1'b1; off_r = addr; wdata = data;
            @(posedge clk); #1;
            sel = 1'b0; we = 1'b0;
        end
    endtask

    // -------------------------------------------------------
    // 메인 테스트
    // -------------------------------------------------------
    initial begin
        fail_cnt = 0;
        sel  = 1'b0; we   = 1'b0;
        off_r  = 16'h0000; wdata = 32'h0;

        // 리셋
        rst = 1'b1;
        repeat (4) @(posedge clk);
        @(posedge clk); #1;
        rst = 1'b0;

        // ---- CHECK 1: BCLK 주기 = 320 ns ----
        @(posedge bclk); t0 = $time;
        @(posedge bclk); t1 = $time;
        if ((t1 - t0) !== 64'd320) begin
            $display("FAIL CHECK1: BCLK period expected 320 ns, got %0d ns", t1-t0);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("CHECK 1 PASS: BCLK period = %0d ns", t1-t0);
        end

        // ---- CHECK 2: LRCLK 주기 = 10240 ns ----
        @(posedge lrclk); t0 = $time;
        @(posedge lrclk); t1 = $time;
        if ((t1 - t0) !== 64'd10240) begin
            $display("FAIL CHECK2: LRCLK period expected 10240 ns, got %0d ns", t1-t0);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("CHECK 2 PASS: LRCLK period = %0d ns", t1-t0);
        end

        // ---- CHECK 3: LRCLK 반주기당 BCLK 하강 에지 15~16개 ----
        // bclk와 lrclk는 같은 계수기 출발점에서 동기화되어 있어
        // lrclk 에지와 bclk 에지가 같은 사이클에 겹친다.
        // @(negedge lrclk) 이후 카운트를 시작하므로 겹친 에지는 제외되고
        // @(posedge lrclk) 에서 카운터를 멈춘다. 15 또는 16을 허용한다.
        bclk_half_cnt = 0;
        @(negedge lrclk);
        fork
            begin : cnt_bclk_blk
                forever @(negedge bclk) bclk_half_cnt = bclk_half_cnt + 1;
            end
            begin
                @(posedge lrclk);
                disable cnt_bclk_blk;
            end
        join
        if (bclk_half_cnt < 15 || bclk_half_cnt > 16) begin
            $display("FAIL CHECK3: BCLK negedges per LRCLK half expected 15-16, got %0d",
                     bclk_half_cnt);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("CHECK 3 PASS: BCLK negedges per LRCLK half = %0d", bclk_half_cnt);
        end

        // ---- CHECK 4: SDIN MSB-우선 직렬화 ----
        // L_DATA = 0x8001 (bit15=1, bit14=0, ... bit1=1, bit0=0 (미전송))
        // TX_EN 활성화 → LRCLK 하강 에지 대기 → 첫 BCLK 하강 에지에서 SDIN=1(bit15)
        //                                      → 두 번째 BCLK 하강 에지에서 SDIN=0(bit14)
        do_write(16'h0008, 32'h00008001);  // L_DATA = 0x8001
        do_write(16'h0000, 32'h00000001);  // CTRL: TX_EN = 1

        @(negedge lrclk);    // lrclk 하강 → l_reg 래치됨 (동시에 bclk도 하강)
        @(negedge bclk);     // 첫 번째 유효 BCLK 하강 (bit15 출력 사이클)
        if (sdin !== 1'b1) begin
            $display("FAIL CHECK4a: SDIN[bit15] expected 1, got %b (L_DATA=0x8001)", sdin);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("CHECK 4a PASS: SDIN[bit15]=1");
        end

        @(negedge bclk);     // 두 번째 BCLK 하강 (bit14 출력 사이클)
        if (sdin !== 1'b0) begin
            $display("FAIL CHECK4b: SDIN[bit14] expected 0, got %b (L_DATA=0x8001)", sdin);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("CHECK 4b PASS: SDIN[bit14]=0");
        end

        // ---- 최종 결과 출력 ----
        repeat (10) @(posedge clk);
        if (fail_cnt === 0)
            $display("PASS all checks");
        else
            $display("FAIL: %0d check(s) failed", fail_cnt);
        $finish;
    end

    // -------------------------------------------------------
    // 타임아웃: 2 ms
    // -------------------------------------------------------
    initial begin
        #2_000_000;
        $display("FAIL: simulation timeout at 2ms");
        $finish;
    end

endmodule
