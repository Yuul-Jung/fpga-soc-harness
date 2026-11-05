// tb_rc_car_arb.v — 자체 점검 테스트벤치 (PASS / FAIL)
// PASS: 출력 → iverilog+vvp 에서 성공
// SETTLE_CYC=10 으로 오버라이드해 빠른 시뮬레이션 수행
// 에코: 각 방향 5800 클럭 (= 1 cm @ 100 MHz CM_DIVISOR=5800)
`timescale 1ns/1ps
module tb_rc_car_arb;
    // ── 클럭 ───────────────────────────────────────────────────────
    localparam CLK_HALF = 5;      // 100 MHz → 10 ns
    reg clk = 0;
    always #CLK_HALF clk = ~clk;

    // ── DUT 포트 ───────────────────────────────────────────────────
    reg  rst_n  = 0;
    // AXI write
    reg  [31:0] awaddr = 0;  reg  awvalid = 0;  wire awready;
    reg  [31:0] wdata  = 0;  reg  wvalid  = 0;  wire wready;
    wire [1:0]  bresp;       wire bvalid;        reg  bready = 1;
    // AXI read
    reg  [31:0] araddr = 0;  reg  arvalid = 0;  wire arready;
    wire [31:0] rdata;       wire [1:0] rresp;   wire rvalid;  reg rready = 1;
    // 외부
    wire trig, pwm_servo, ain1, ain2, pwm_a, bin1, bin2, pwm_b, irq;
    reg  echo = 0;

    // ── DUT 인스턴스화 (SETTLE_CYC=10으로 오버라이드) ────────────
    axil_rc_arb #(.SETTLE_CYC(10)) dut (
        .s_axi_aclk(clk),  .s_axi_aresetn(rst_n),
        .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata),   .s_axi_wstrb(4'hF),
        .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp),   .s_axi_bvalid(bvalid),  .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arvalid(arvalid),.s_axi_arready(arready),
        .s_axi_rdata(rdata),   .s_axi_rresp(rresp),    .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),
        .trig(trig), .echo(echo), .pwm_servo(pwm_servo),
        .ain1(ain1), .ain2(ain2), .pwm_a(pwm_a),
        .bin1(bin1), .bin2(bin2), .pwm_b(pwm_b), .irq(irq)
    );

    // ── 실패 카운터 ────────────────────────────────────────────────
    integer fail_cnt = 0;
    task chk;
        input       cond;
        input [63:0] tag;
        begin
            if (!cond) begin
                $display("FAIL: check %0d", tag);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ── AXI 쓰기 태스크 ───────────────────────────────────────────
    // 신호를 negedge 에 세팅해 posedge 에서 슬레이브가 샘플링하도록 함
    task axi_wr;
        input [31:0] addr, data;
        begin
            @(negedge clk);
            awaddr = addr;  awvalid = 1;
            wdata  = data;  wvalid  = 1;
            @(posedge clk); // 슬레이브가 AW·W 샘플링
            @(posedge clk); // awready/wready 가 반영됨
            awvalid = 0;    wvalid = 0;
            while (!bvalid) @(posedge clk); // 응답 대기
        end
    endtask

    // ── AXI 읽기 태스크 ───────────────────────────────────────────
    reg [31:0] rd_data;
    task axi_rd;
        input [31:0] addr;
        begin
            @(negedge clk);
            araddr = addr;  arvalid = 1;
            @(posedge clk);
            @(posedge clk); // rvalid·rdata 반영
            arvalid = 0;
            while (!rvalid) @(posedge clk);
            rd_data = rdata;
        end
    endtask

    // ── 메인 테스트 ────────────────────────────────────────────────
    integer i;
    initial begin
        // 리셋
        repeat(6) @(posedge clk);
        @(negedge clk); rst_n = 1;
        repeat(2) @(posedge clk);
        $display("DBG: reset done");

        // ══ T1: THRESHOLD 레지스터 쓰기·읽기 ══
        axi_wr(32'h10, 32'd30);        // THRESHOLD = 30 cm
        axi_rd(32'h10);
        chk(rd_data[7:0] == 8'd30, 1); // THRESHOLD 읽기

        axi_wr(32'h18, 32'h1);         // IRQ_EN[0] = 1
        axi_rd(32'h18);
        chk(rd_data[0] == 1'b1, 2);    // IRQ_EN 읽기

        // ══ T2: 모터 방향 핀 (arb_stop=0, 초깃값 dist=0x3FF > thr=30) ══
        // FWD: ain1=1,ain2=0,bin1=1,bin2=0
        axi_wr(32'h00, 32'h0003);      // EN=1, DIR=01(FWD)
        @(negedge clk); @(posedge clk);
        chk(ain1 == 1'b1 && ain2 == 1'b0 && bin1 == 1'b1 && bin2 == 1'b0, 3);

        // BWD: ain1=0,ain2=1,bin1=0,bin2=1
        axi_wr(32'h00, 32'h0005);      // EN=1, DIR=10(BWD)
        @(negedge clk); @(posedge clk);
        chk(ain1 == 1'b0 && ain2 == 1'b1 && bin1 == 1'b0 && bin2 == 1'b1, 4);

        // SPIN_L: ain1=0,ain2=1,bin1=1,bin2=0
        axi_wr(32'h00, 32'h0007);      // EN=1, DIR=11(SPIN_L)
        @(negedge clk); @(posedge clk);
        chk(ain1 == 1'b0 && ain2 == 1'b1 && bin1 == 1'b1 && bin2 == 1'b0, 5);

        // ══ T3: 초기 arb_stop=0 확인 (dist=0x3FF >> thr=30) ══
        axi_wr(32'h00, 32'h0001);      // EN=1, DIR=STOP
        repeat(5) @(posedge clk);
        axi_rd(32'h14);
        chk(rd_data[4] == 1'b0, 6);   // arb_stop == 0

        // ══ T4: 스캔 실행 + 에코 응답 (dist = 1 cm per direction) ══
        // 스캔 개시: CTRL[12]=1
        axi_wr(32'h00, 32'h1001);      // EN=1, SCAN_START=1
        $display("DBG: scan started");
        // 에코 드라이버: L/C/R 각각 5800 클럭(= 1 cm)
        for (i = 0; i < 3; i = i + 1) begin
            $display("DBG: waiting for trig[%0d]", i);
            if (!trig) @(posedge trig); // TRIG 상승 (이미 high면 skip)
            $display("DBG: trig[%0d] high at %0t", i, $time);
            @(negedge trig);            // TRIG 하강 (1000 클럭 후)
            $display("DBG: trig[%0d] low, sending echo", i);
            repeat(5) @(posedge clk);   // 짧은 대기
            echo = 1;
            repeat(5800) @(posedge clk);// 1 cm = 5800 클럭
            echo = 0;
            $display("DBG: echo[%0d] done at %0t", i, $time);
            repeat(20) @(posedge clk);  // 측정 완료 여유
        end
        $display("DBG: all echoes done, waiting settle");
        repeat(100) @(posedge clk);     // S_RET 정착 + scan_done 처리
        $display("DBG: settle done");

        // DIST_L/C/R = 1 cm
        axi_rd(32'h04);
        chk(rd_data[9:0] == 10'd1, 7); // DIST_L
        axi_rd(32'h08);
        chk(rd_data[9:0] == 10'd1, 8); // DIST_C
        axi_rd(32'h0C);
        chk(rd_data[9:0] == 10'd1, 9); // DIST_R

        // ══ T5: dist=1 < thr=30 → arb_stop=1 (안전 정지) ══
        repeat(5) @(posedge clk);
        axi_rd(32'h14);
        chk(rd_data[4] == 1'b1, 10);  // arb_stop==1

        // arb_stop=1 → 모터 출력 강제 0 (FWD 명령에도 불구하고)
        axi_wr(32'h00, 32'h0003);      // EN=1, DIR=FWD
        @(negedge clk); @(posedge clk);
        chk(ain1 == 1'b0 && ain2 == 1'b0, 11); // arb_stop이 FWD 무효화

        // ══ T6: IRQ_STAT scan_done + W1C ══
        axi_rd(32'h1C);
        chk(rd_data[0] == 1'b1, 12);  // IRQ_STAT[0] 세트
        axi_wr(32'h1C, 32'h1);         // W1C: 소거
        axi_rd(32'h1C);
        chk(rd_data[0] == 1'b0, 13);  // IRQ_STAT[0] 소거 확인

        // ══ 최종 결과 ══
        if (fail_cnt == 0)
            $display("PASS: 전체 13 항목 통과");
        else
            $display("FAIL: %0d 항목 실패", fail_cnt);
        $finish;
    end

    // ── 타임아웃 ──────────────────────────────────────────────────
    initial begin
        #2500000;  // 2.5 ms 시뮬레이션 타임아웃 (충분: 스캔 ≈ 200 µs)
        $display("FAIL: 시뮬레이션 타임아웃");
        $finish;
    end
endmodule
