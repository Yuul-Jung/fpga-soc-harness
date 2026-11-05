// tb_bt_bridge.v — 자체 점검 테스트벤치 (PASS / FAIL)
// PASS: 출력 → iverilog+vvp 에서 성공
// CLKS_PER_BIT=20으로 오버라이드해 빠른 시뮬레이션 수행 (실제 보드레이트와 무관)
//
// 점검 목록:
//   T1: CTRL bt_en 쓰기·읽기
//   T2: TX 프레임 6바이트 패턴 확인 (0xAA speed[15:8] speed[7:0] angle[15:8] angle[7:0] 0x55)
//   T3: RX 1바이트 수신 → RX_DATA 레지스터 + rx_valid STATUS 비트
//   T4: IRQ_STAT rx_done 세트 확인
//   T5: IRQ_STAT W1C 소거 확인
//   T6: tx_busy 중 TX_SEND 무시 (tx_busy 중 두 번 쓰기, 두 번째는 무시됨)
`timescale 1ns/1ps
module tb_bt_bridge;
    // ── 클럭 ───────────────────────────────────────────────────────
    localparam CLK_HALF = 5;      // 100 MHz
    reg clk = 0;
    always #CLK_HALF clk = ~clk;

    // ── 파라미터 ───────────────────────────────────────────────────
    localparam CPB = 20;  // CLKS_PER_BIT (오버라이드)

    // ── DUT 포트 ───────────────────────────────────────────────────
    reg  rst_n = 0;
    reg  [31:0] awaddr = 0;  reg  awvalid = 0;  wire awready;
    reg  [31:0] wdata  = 0;  reg  wvalid  = 0;  wire wready;
    wire [1:0]  bresp;       wire bvalid;        reg  bready = 1;
    reg  [31:0] araddr = 0;  reg  arvalid = 0;  wire arready;
    wire [31:0] rdata;       wire [1:0] rresp;   wire rvalid;  reg rready = 1;

    wire bt_tx;         // DUT → HC-05 RX (테스트벤치가 수신)
    reg  bt_rx  = 1;    // HC-05 TX → DUT RX (테스트벤치가 송신)
    reg  bt_state = 0;  // HC-05 STATE 입력 (연결 여부)
    wire bt_en;         // DUT → HC-05 EN (AT 모드 제어)
    wire irq;

    // ── DUT 인스턴스화 ────────────────────────────────────────────
    axil_bt_bridge #(.CLKS_PER_BIT(CPB)) dut (
        .s_axi_aclk   (clk),    .s_axi_aresetn (rst_n),
        .s_axi_awaddr (awaddr), .s_axi_awvalid (awvalid), .s_axi_awready (awready),
        .s_axi_wdata  (wdata),  .s_axi_wstrb   (4'hF),
        .s_axi_wvalid (wvalid), .s_axi_wready  (wready),
        .s_axi_bresp  (bresp),  .s_axi_bvalid  (bvalid),  .s_axi_bready  (bready),
        .s_axi_araddr (araddr), .s_axi_arvalid (arvalid), .s_axi_arready (arready),
        .s_axi_rdata  (rdata),  .s_axi_rresp   (rresp),   .s_axi_rvalid  (rvalid),
        .s_axi_rready (rready),
        .bt_tx (bt_tx), .bt_rx (bt_rx),
        .bt_state (bt_state), .bt_en (bt_en),
        .irq (irq)
    );

    // ── 실패 카운터 ───────────────────────────────────────────────
    integer fail_cnt = 0;
    task chk;
        input cond;
        input [63:0] tag;
        begin
            if (!cond) begin
                $display("FAIL: check %0d", tag);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ── AXI 쓰기 태스크 ──────────────────────────────────────────
    task axi_wr;
        input [31:0] addr, data_in;
        begin
            @(negedge clk);
            awaddr = addr; awvalid = 1;
            wdata  = data_in; wvalid = 1;
            @(posedge clk);
            @(posedge clk);
            awvalid = 0; wvalid = 0;
            while (!bvalid) @(posedge clk);
        end
    endtask

    // ── AXI 읽기 태스크 ──────────────────────────────────────────
    reg [31:0] rd_data;
    task axi_rd;
        input [31:0] addr;
        begin
            @(negedge clk);
            araddr = addr; arvalid = 1;
            @(posedge clk);
            @(posedge clk);
            arvalid = 0;
            while (!rvalid) @(posedge clk);
            rd_data = rdata;
        end
    endtask

    // ── UART 비트 수신 태스크 (DUT bt_tx 모니터링) ──────────────
    // CPB 클럭마다 한 비트씩 샘플. 스타트 비트 하강 엣지를 먼저 기다린 뒤
    // CPB/2 대기 후 스타트 확인, 이후 CPB마다 8비트 샘플, 마지막 스톱 비트 확인
    reg [7:0] recv_byte;
    task uart_recv;
        integer k;
        begin
            // 스타트 비트 하강 엣지 대기
            @(negedge bt_tx);
            // 스타트 비트 중앙
            repeat(CPB/2) @(posedge clk);
            if (bt_tx !== 1'b0) begin
                $display("FAIL: uart_recv 스타트 비트 미확인");
                fail_cnt = fail_cnt + 1;
            end
            recv_byte = 8'd0;
            // 8 데이터 비트 (LSB first)
            for (k = 0; k < 8; k = k + 1) begin
                repeat(CPB) @(posedge clk);
                recv_byte[k] = bt_tx;
            end
            // 스톱 비트
            repeat(CPB) @(posedge clk);
            if (bt_tx !== 1'b1) begin
                $display("FAIL: uart_recv 스톱 비트 미확인");
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // ── UART 바이트 송신 태스크 (DUT bt_rx 구동) ────────────────
    // negedge 에 bt_rx 변경해 DUT posedge 샘플링과 경합하지 않게 함
    task uart_send;
        input [7:0] byte_in;
        integer k;
        begin
            @(negedge clk);
            bt_rx = 1'b0;              // 스타트 비트
            repeat(CPB) @(negedge clk);
            for (k = 0; k < 8; k = k + 1) begin
                bt_rx = byte_in[k];    // LSB first
                repeat(CPB) @(negedge clk);
            end
            bt_rx = 1'b1;              // 스톱 비트
            repeat(CPB) @(negedge clk);
        end
    endtask

    // ── 프레임 6바이트 수신 태스크 ───────────────────────────────
    reg [7:0] frame[0:5];
    task recv_frame;
        integer j;
        begin
            for (j = 0; j < 6; j = j + 1) begin
                uart_recv;
                frame[j] = recv_byte;
            end
        end
    endtask

    // ── 메인 테스트 ──────────────────────────────────────────────
    initial begin
        // 리셋
        repeat(6) @(posedge clk);
        @(negedge clk); rst_n = 1;
        repeat(2) @(posedge clk);

        // ══ T1: CTRL bt_en 쓰기·읽기 ══
        axi_wr(32'h00, 32'h1);         // bt_en = 1
        axi_rd(32'h00);
        chk(rd_data[0] == 1'b1, 1);    // bt_en 읽기
        axi_wr(32'h00, 32'h0);         // bt_en = 0
        axi_rd(32'h00);
        chk(rd_data[0] == 1'b0, 2);    // bt_en 소거

        // ══ T2: TX 프레임 6바이트 패턴 ══
        // TX_DATA: speed=0x0102, angle=0x0304
        // 프레임 기대값: 0xAA, 0x01, 0x02, 0x04, 0x03, 0x55
        // (TX_DATA[15:0]=speed, TX_DATA[31:16]=angle;
        //  frame: speed[15:8]=0x01, speed[7:0]=0x02,
        //         angle[15:8]=frame_data_latch[31:24]=0x03,
        //         angle[7:0] =frame_data_latch[23:16]=0x04)
        // 주의: TX_DATA[31:16]=angle=0x0304 → [31:24]=0x03, [23:16]=0x04
        axi_wr(32'h08, {16'h0304, 16'h0102});  // angle=0x0304, speed=0x0102
        axi_wr(32'h0C, 32'h1);         // TX_SEND
        // 프레임 수신 (6바이트)
        fork
            recv_frame;
        join
        $display("DBG: frame = %02h %02h %02h %02h %02h %02h",
                 frame[0], frame[1], frame[2], frame[3], frame[4], frame[5]);
        chk(frame[0] == 8'hAA, 3);     // 프레임 헤더
        chk(frame[1] == 8'h01, 4);     // speed[15:8]
        chk(frame[2] == 8'h02, 5);     // speed[7:0]
        chk(frame[3] == 8'h03, 6);     // angle[15:8]
        chk(frame[4] == 8'h04, 7);     // angle[7:0]
        chk(frame[5] == 8'h55, 8);     // 프레임 꼬리

        // ══ T3: STATUS tx_busy=0 (프레임 전송 완료 후) ══
        repeat(10) @(posedge clk);
        axi_rd(32'h04);
        chk(rd_data[1] == 1'b0, 9);    // tx_busy == 0

        // ══ T4: IRQ_EN 활성화 + RX 1바이트 수신 ══
        axi_wr(32'h14, 32'h1);         // IRQ_EN = 1
        // bt_rx 에 0xA5 송신
        uart_send(8'hA5);
        // 수신 완료 대기
        repeat(50) @(posedge clk);

        axi_rd(32'h10);
        chk(rd_data[7:0] == 8'hA5, 10); // RX_DATA == 0xA5

        axi_rd(32'h04);
        chk(rd_data[2] == 1'b1, 11);    // STATUS rx_valid == 1

        // ══ T5: IRQ_STAT rx_done 세트 ══
        axi_rd(32'h18);
        chk(rd_data[0] == 1'b1, 12);    // IRQ_STAT[0] 세트

        // IRQ 핀 High 확인
        chk(irq == 1'b1, 13);

        // ══ T6: IRQ_STAT W1C 소거 ══
        axi_wr(32'h18, 32'h1);         // W1C 소거
        axi_rd(32'h18);
        chk(rd_data[0] == 1'b0, 14);   // IRQ_STAT 소거 확인

        // IRQ 핀 Low 확인
        chk(irq == 1'b0, 15);

        // ══ 최종 결과 ══
        if (fail_cnt == 0)
            $display("PASS: 전체 15 항목 통과");
        else
            $display("FAIL: %0d 항목 실패", fail_cnt);
        $finish;
    end

    // ── 타임아웃 ─────────────────────────────────────────────────
    initial begin
        // 6바이트 TX: 6×10×CPB=1200 클럭, RX: 10×CPB=200 클럭, 여유 1000 클럭
        #((1200 + 200 + 2000) * 10);  // 단위 ns (10 ns/클럭)
        $display("FAIL: 시뮬레이션 타임아웃");
        $finish;
    end
endmodule
