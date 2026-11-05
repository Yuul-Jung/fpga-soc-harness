// tb_axil_hc05_bt.v — 자체 점검 테스트벤치 (PASS / FAIL)
// PASS: 출력 → iverilog+vvp 에서 성공
// BAUD_DIV=4 오버라이드로 빠른 시뮬레이션
// 10 비트/바이트 × 4 클럭/비트 = 40 클럭/바이트
`timescale 1ns/1ps
module tb_axil_hc05_bt;
    localparam CLK_HALF  = 5;    // 100 MHz
    localparam BAUD_DIV  = 4;    // 테스트 가속 (실제: 10417)

    // ── 클럭 ───────────────────────────────────────────────────
    reg clk = 0;
    always #CLK_HALF clk = ~clk;

    // ── DUT 포트 ───────────────────────────────────────────────
    reg  rst_n = 0;
    reg  [31:0] awaddr = 0;  reg  awvalid = 0;  wire awready;
    reg  [31:0] wdata  = 0;  reg  wvalid  = 0;  wire wready;
    wire [1:0]  bresp;       wire bvalid;        reg  bready = 1;
    reg  [31:0] araddr = 0;  reg  arvalid = 0;  wire arready;
    wire [31:0] rdata;       wire [1:0] rresp;   wire rvalid;  reg rready = 1;

    wire uart_tx_pin;
    reg  uart_rx_pin = 1;    // idle = high
    reg  bt_state    = 0;
    wire bt_en;
    wire irq;

    axil_hc05_bt #(.BAUD_DIV(BAUD_DIV)) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        .s_axi_awaddr  (awaddr),  .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata   (wdata),   .s_axi_wstrb(4'hF),
        .s_axi_wvalid  (wvalid),  .s_axi_wready(wready),
        .s_axi_bresp   (bresp),   .s_axi_bvalid(bvalid),  .s_axi_bready(bready),
        .s_axi_araddr  (araddr),  .s_axi_arvalid(arvalid),.s_axi_arready(arready),
        .s_axi_rdata   (rdata),   .s_axi_rresp(rresp),    .s_axi_rvalid(rvalid),
        .s_axi_rready  (rready),
        .uart_tx_pin   (uart_tx_pin),
        .uart_rx_pin   (uart_rx_pin),
        .bt_state      (bt_state),
        .bt_en         (bt_en),
        .irq           (irq)
    );

    // ── 실패 카운터 ────────────────────────────────────────────
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

    // ── AXI 쓰기 태스크 (negedge 에 세팅) ─────────────────────
    task axi_wr;
        input [31:0] addr, data;
        begin
            @(negedge clk);
            awaddr = addr;  awvalid = 1;
            wdata  = data;  wvalid  = 1;
            @(posedge clk);
            @(posedge clk);
            awvalid = 0;    wvalid = 0;
            while (!bvalid) @(posedge clk);
        end
    endtask

    // ── AXI 읽기 태스크 ───────────────────────────────────────
    reg [31:0] rd_data;
    task axi_rd;
        input [31:0] addr;
        begin
            @(negedge clk);
            araddr = addr;  arvalid = 1;
            @(posedge clk);
            @(posedge clk);
            arvalid = 0;
            while (!rvalid) @(posedge clk);
            rd_data = rdata;
        end
    endtask

    // ── UART TX 캡처 태스크 (DUT→외부 방향, uart_tx_pin 감시) ─
    reg [7:0] cap_byte;
    task uart_cap;
        output [7:0] out;
        integer b;
        begin
            // 스타트 비트 하강 대기
            while (uart_tx_pin !== 1'b0) @(posedge clk);
            // 중간 샘플: 비트 0 중간 = BAUD_DIV + BAUD_DIV/2 클럭
            repeat(BAUD_DIV + BAUD_DIV/2) @(posedge clk);
            for (b = 0; b < 8; b = b + 1) begin
                out[b] = uart_tx_pin;
                repeat(BAUD_DIV) @(posedge clk);
            end
        end
    endtask

    // ── UART TX 드라이버 (외부→DUT 방향, uart_rx_pin 구동) ───
    task uart_drv;
        input [7:0] byte_in;
        integer b;
        begin
            @(negedge clk);
            uart_rx_pin = 0;                        // 스타트 비트
            repeat(BAUD_DIV) @(negedge clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx_pin = byte_in[b];
                repeat(BAUD_DIV) @(negedge clk);
            end
            uart_rx_pin = 1;                        // 스톱 비트
            repeat(BAUD_DIV) @(negedge clk);
        end
    endtask

    // ── 메인 테스트 ────────────────────────────────────────────
    reg [7:0] byte0, byte1;
    initial begin
        // 리셋
        repeat(6) @(posedge clk);
        @(negedge clk); rst_n = 1;
        repeat(2) @(posedge clk);

        // ══ T1: EN 비트 쓰기·읽기 + bt_en 핀 확인 ══
        axi_wr(32'h00, 32'h2);        // CTRL[1]=EN=1
        axi_rd(32'h00);
        chk(rd_data[1] == 1'b1, 1);   // EN 읽기
        @(negedge clk); @(posedge clk);
        chk(bt_en == 1'b1, 2);        // 핀 확인

        // ══ T2: TX_SPD / TX_ANG 쓰기·읽기 ══
        axi_wr(32'h04, 32'h42);       // TX_SPD = 0x42
        axi_rd(32'h04);
        chk(rd_data[7:0] == 8'h42, 3);

        axi_wr(32'h08, 32'h37);       // TX_ANG = 0x37
        axi_rd(32'h08);
        chk(rd_data[7:0] == 8'h37, 4);

        // ══ T3: TX_GO → 2바이트 캡처 ══
        // IRQ_EN 활성화 (RX용)
        axi_wr(32'h10, 32'h1);        // IRQ_EN[0]=1

        // TX_GO 발사 (fork 로 동시에 2바이트 캡처)
        fork
            begin
                axi_wr(32'h00, 32'h3); // CTRL[0]=TX_GO, [1]=EN
            end
            begin
                uart_cap(byte0);
                uart_cap(byte1);
            end
        join

        chk(byte0 == 8'h42, 5);       // 속도 바이트
        chk(byte1 == 8'h37, 6);       // 조향 바이트

        // ══ T4: 외부→DUT RX + IRQ ══
        uart_drv(8'hA5);
        repeat(10) @(posedge clk);    // RX 처리 여유

        axi_rd(32'h0C);
        chk(rd_data[7:0] == 8'hA5, 7); // RX_DAT

        axi_rd(32'h14);
        chk(rd_data[0] == 1'b1, 8);   // IRQ_STAT[0] 세트

        chk(irq == 1'b1, 9);           // IRQ 핀 HIGH

        // ══ T5: IRQ_STAT W1C 소거 ══
        axi_wr(32'h14, 32'h1);        // W1C
        axi_rd(32'h14);
        chk(rd_data[0] == 1'b0, 10);  // 소거 확인

        chk(irq == 1'b0, 11);         // IRQ 핀 LOW

        // ══ T6: STATE 핀 → CTRL[9] 반영 ══
        @(negedge clk);
        bt_state = 1;
        repeat(2) @(posedge clk);
        axi_rd(32'h00);
        chk(rd_data[9] == 1'b1, 12);  // STATE_IN

        // ══ 최종 결과 ══
        if (fail_cnt == 0)
            $display("PASS: 전체 12 항목 통과");
        else
            $display("FAIL: %0d 항목 실패", fail_cnt);
        $finish;
    end

    // ── 타임아웃 ──────────────────────────────────────────────
    initial begin
        #5000000;
        $display("FAIL: 시뮬레이션 타임아웃");
        $finish;
    end
endmodule
