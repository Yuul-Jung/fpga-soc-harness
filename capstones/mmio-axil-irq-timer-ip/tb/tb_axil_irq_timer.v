// tb_axil_irq_timer.v
// 자체 점검 테스트벤치 — axil_irq_timer
//
// 검사 항목:
//   TC1: 리셋 후 모든 출력 0
//   TC2: single-shot 타이머 (COUNT=10) → 10 사이클 후 IRQ
//   TC3: IRQ_ACK 쓰기 → expired 클리어, irq_out 비활성
//   TC4: IRQ_MASK=0 → expired 세트돼도 irq_out=0
//   TC5: IRQ_FORCE 쓰기 → 즉시 expired 세트
//   TC6: auto_reload 모드 (COUNT=5, CTRL=3'b11) → 반복 IRQ
//   TC7: 리셋 중 타이머 중단 확인
//
// 출력: PASS: <msg> 또는 FAIL: <msg>
// 종료: "TESTBENCH DONE" 뒤 $finish
//
// 준수: Verilog-2001, iverilog·verilator 호환 (always @(posedge) 형식)

`default_nettype none
`timescale 1ns/1ps

module tb_axil_irq_timer;

// DUT 파라미터
localparam DATA_WIDTH = 32;
localparam ADDR_WIDTH = 5;

// 클럭 (10 ns 주기 = 100 MHz)
reg clk;
initial clk = 1'b0;
always #5 clk = ~clk;

// 리셋 (active-low)
reg aresetn;

// AXI4-Lite 버스 신호
reg  [ADDR_WIDTH-1:0]    awaddr;
reg  [2:0]               awprot;
reg                      awvalid;
wire                     awready;
reg  [DATA_WIDTH-1:0]    wdata;
reg  [DATA_WIDTH/8-1:0]  wstrb;
reg                      wvalid;
wire                     wready;
wire [1:0]               bresp;
wire                     bvalid;
reg                      bready;
reg  [ADDR_WIDTH-1:0]    araddr;
reg  [2:0]               arprot;
reg                      arvalid;
wire                     arready;
wire [DATA_WIDTH-1:0]    rdata;
wire [1:0]               rresp;
wire                     rvalid;
reg                      rready;
wire                     irq_out;

// DUT 인스턴스
axil_irq_timer #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dut (
    .s_axil_aclk     (clk),
    .s_axil_aresetn  (aresetn),
    .s_axil_awaddr   (awaddr),
    .s_axil_awprot   (awprot),
    .s_axil_awvalid  (awvalid),
    .s_axil_awready  (awready),
    .s_axil_wdata    (wdata),
    .s_axil_wstrb    (wstrb),
    .s_axil_wvalid   (wvalid),
    .s_axil_wready   (wready),
    .s_axil_bresp    (bresp),
    .s_axil_bvalid   (bvalid),
    .s_axil_bready   (bready),
    .s_axil_araddr   (araddr),
    .s_axil_arprot   (arprot),
    .s_axil_arvalid  (arvalid),
    .s_axil_arready  (arready),
    .s_axil_rdata    (rdata),
    .s_axil_rresp    (rresp),
    .s_axil_rvalid   (rvalid),
    .s_axil_rready   (rready),
    .irq_out         (irq_out)
);

// 오류 카운터
integer err_count;
integer test_num;

// ============================================================
// 태스크: AXI4-Lite 쓰기 (주소+데이터 동시 발행 간략화)
// ============================================================
task axil_write;
    input [ADDR_WIDTH-1:0] addr;
    input [DATA_WIDTH-1:0] data;
    begin
        @(posedge clk);
        awaddr  <= addr;
        awprot  <= 3'b000;
        awvalid <= 1'b1;
        wdata   <= data;
        wstrb   <= 4'hF;
        wvalid  <= 1'b1;
        bready  <= 1'b1;

        // 주소 수락 대기
        @(posedge clk);
        while (!awready) @(posedge clk);
        awvalid <= 1'b0;

        // 데이터 수락 대기
        while (!wready) @(posedge clk);
        wvalid <= 1'b0;

        // 응답 대기
        while (!bvalid) @(posedge clk);
        bready <= 1'b0;
        @(posedge clk);
    end
endtask

// ============================================================
// 태스크: AXI4-Lite 읽기
// ============================================================
task axil_read;
    input  [ADDR_WIDTH-1:0] addr;
    output [DATA_WIDTH-1:0] data_out;
    begin
        @(posedge clk);
        araddr  <= addr;
        arprot  <= 3'b000;
        arvalid <= 1'b1;
        rready  <= 1'b1;

        // 주소 수락 대기
        @(posedge clk);
        while (!arready) @(posedge clk);
        arvalid <= 1'b0;

        // 데이터 대기
        while (!rvalid) @(posedge clk);
        data_out = rdata;
        rready <= 1'b0;
        @(posedge clk);
    end
endtask

// ============================================================
// 태스크: 체크 (자동 PASS/FAIL 출력)
// ============================================================
task check;
    input        condition;
    input [255:0] msg;
    begin
        if (condition)
            $display("PASS: TC%0d %s", test_num, msg);
        else begin
            $display("FAIL: TC%0d %s", test_num, msg);
            err_count = err_count + 1;
        end
    end
endtask

// ============================================================
// 메인 테스트 시퀀스
// ============================================================
reg [DATA_WIDTH-1:0] rd;

initial begin
    err_count = 0;
    test_num  = 0;

    // 초기화
    aresetn = 1'b0;
    awaddr = 0; awprot = 0; awvalid = 0;
    wdata  = 0; wstrb  = 0; wvalid  = 0; bready = 0;
    araddr = 0; arprot = 0; arvalid = 0; rready = 0;

    // 리셋 10 사이클
    repeat(10) @(posedge clk);
    aresetn = 1'b1;
    @(posedge clk);

    // ----------------------------------------------------------
    // TC1: 리셋 후 IRQ_STATUS=0, irq_out=0
    // ----------------------------------------------------------
    test_num = 1;
    axil_read(5'h08, rd);
    check(rd === 32'h0000_0000, "reset: IRQ_STATUS=0");
    check(irq_out === 1'b0,     "reset: irq_out=0");

    // ----------------------------------------------------------
    // TC2: single-shot 타이머, COUNT=10, CTRL=enable
    //       10 클럭 후 expired 세트 확인
    // ----------------------------------------------------------
    test_num = 2;
    // IRQ_MASK[0]=1 세트 (인터럽트 허용)
    axil_write(5'h0C, 32'h0000_0001);
    // COUNT = 10
    axil_write(5'h04, 32'h0000_000A);
    // CTRL[0]=enable (bit1=0: single-shot)
    axil_write(5'h00, 32'h0000_0001);

    // 최대 15 사이클 대기하며 irq_out 감시
    begin : wait_irq
        integer i;
        for (i = 0; i < 15; i = i + 1) begin
            @(posedge clk);
            if (irq_out) disable wait_irq;
        end
    end

    axil_read(5'h08, rd);
    check(rd[0] === 1'b1, "single-shot: expired=1 after COUNT cycles");
    check(rd[1] === 1'b0, "single-shot: running=0 after expiry");
    check(irq_out === 1'b1, "single-shot: irq_out=1");

    // CTRL[0]가 자동 클리어됐는지 확인
    axil_read(5'h00, rd);
    check(rd[0] === 1'b0, "single-shot: CTRL[0] auto-cleared");

    // ----------------------------------------------------------
    // TC3: IRQ_ACK 쓰기 → expired=0, irq_out=0
    // ----------------------------------------------------------
    test_num = 3;
    axil_write(5'h10, 32'h0000_0001);  // IRQ_ACK
    @(posedge clk);
    axil_read(5'h08, rd);
    check(rd[0] === 1'b0, "ACK: expired cleared");
    check(irq_out === 1'b0, "ACK: irq_out=0 after ACK");

    // ----------------------------------------------------------
    // TC4: IRQ_MASK=0 → expired 세트돼도 irq_out=0
    // ----------------------------------------------------------
    test_num = 4;
    axil_write(5'h0C, 32'h0000_0000);  // IRQ_MASK=0 (마스크)
    axil_write(5'h04, 32'h0000_0005);  // COUNT=5
    axil_write(5'h00, 32'h0000_0001);  // CTRL: enable, single-shot

    // 10 사이클 대기
    repeat(10) @(posedge clk);

    axil_read(5'h08, rd);
    check(rd[0] === 1'b1, "mask: expired=1 (timer fired)");
    check(irq_out === 1'b0, "mask: irq_out=0 when IRQ_MASK[0]=0");

    // ACK 클리어
    axil_write(5'h10, 32'h1);
    // 마스크 복구
    axil_write(5'h0C, 32'h0000_0001);

    // ----------------------------------------------------------
    // TC5: IRQ_FORCE 쓰기 → 즉시 expired=1, irq_out=1
    // ----------------------------------------------------------
    test_num = 5;
    axil_read(5'h08, rd);
    check(rd[0] === 1'b0, "force pre: expired=0 before FORCE");
    axil_write(5'h14, 32'h0000_0001);  // IRQ_FORCE
    @(posedge clk);
    axil_read(5'h08, rd);
    check(rd[0] === 1'b1, "force: expired=1 after FORCE");
    check(irq_out === 1'b1, "force: irq_out=1");

    // ACK 클리어
    axil_write(5'h10, 32'h1);
    @(posedge clk);
    check(irq_out === 1'b0, "force: irq_out=0 after ACK");

    // ----------------------------------------------------------
    // TC6: auto_reload (CTRL[1]=1), COUNT=5
    //       두 번 연속 IRQ 확인
    // ----------------------------------------------------------
    test_num = 6;
    axil_write(5'h04, 32'h0000_0005);  // COUNT=5
    axil_write(5'h00, 32'h0000_0003);  // CTRL: enable=1, auto_reload=1

    // 1차 만료 대기
    begin : wait_irq6a
        integer j;
        for (j = 0; j < 10; j = j + 1) begin
            @(posedge clk);
            if (irq_out) disable wait_irq6a;
        end
    end
    check(irq_out === 1'b1, "auto_reload: 1st IRQ fired");
    // 1차 ACK
    axil_write(5'h10, 32'h1);

    // 2차 만료 대기 (auto_reload → 자동 재시작)
    begin : wait_irq6b
        integer k;
        for (k = 0; k < 10; k = k + 1) begin
            @(posedge clk);
            if (irq_out) disable wait_irq6b;
        end
    end
    check(irq_out === 1'b1, "auto_reload: 2nd IRQ fired");
    // 정지: CTRL[0]=0
    axil_write(5'h00, 32'h0000_0000);
    axil_write(5'h10, 32'h1);
    @(posedge clk);
    axil_read(5'h08, rd);
    check(rd[1] === 1'b0, "auto_reload: running=0 after disable");

    // ----------------------------------------------------------
    // TC7: 리셋 중 타이머 강제 정지
    // ----------------------------------------------------------
    test_num = 7;
    axil_write(5'h04, 32'h0000_0064);  // COUNT=100 (긴 타이머)
    axil_write(5'h00, 32'h0000_0001);  // 시작
    repeat(5) @(posedge clk);
    // 리셋 적용
    aresetn = 1'b0;
    repeat(3) @(posedge clk);
    aresetn = 1'b1;
    @(posedge clk);
    axil_read(5'h08, rd);
    check(rd === 32'h0, "reset: IRQ_STATUS=0 after mid-run reset");
    check(irq_out === 1'b0, "reset: irq_out=0 after mid-run reset");

    // ----------------------------------------------------------
    // 최종 결과
    // ----------------------------------------------------------
    @(posedge clk);
    if (err_count === 0)
        $display("PASS: ALL TESTS PASSED (%0d checks)", 15);
    else
        $display("FAIL: %0d TEST(S) FAILED", err_count);

    $display("TESTBENCH DONE");
    $finish;
end

// 타임아웃: 500 사이클 초과 시 FAIL
initial begin
    #5000;
    $display("FAIL: TIMEOUT (simulation exceeded limit)");
    $finish;
end

endmodule
`default_nettype wire
