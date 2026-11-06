`timescale 1ns/1ps
// tb_ble_trilat_ip.v — 자체 점검형 테스트벤치
// PASS/FAIL 출력. !==로 X/Z도 실패 처리.
// CLKS_PER_BIT=10으로 UART 시뮬레이션 가속.
`default_nettype none
module tb_ble_trilat_ip;

    // ── 클럭·리셋 ─────────────────────────────────────────────────
    localparam CLK_HALF = 5;  // 100 MHz → 10 ns 주기
    reg clk = 0, rst_n = 0;
    always #CLK_HALF clk = ~clk;
    initial begin rst_n=0; repeat(4) @(posedge clk); rst_n=1; end

    // ── DUT ──────────────────────────────────────────────────────
    localparam CPB = 10;  // UART 가속
    localparam [31:0] BASE = 32'h4016_0000;

    reg  [31:0] awaddr=0, wdata=0, araddr=0;
    reg         awvalid=0, wvalid=0, bready=1, arvalid=0, rready=1;
    reg  [3:0]  wstrb=4'hF;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;
    reg         uart_rx_drv = 1;

    ble_trilat_ip #(.CLKS_PER_BIT(CPB)) dut (
        .s_axi_aclk    (clk),   .s_axi_aresetn (rst_n),
        .s_axi_awaddr  (awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata   (wdata),  .s_axi_wstrb  (wstrb),   .s_axi_wvalid (wvalid),
        .s_axi_wready  (wready),
        .s_axi_bresp   (bresp),  .s_axi_bvalid (bvalid),  .s_axi_bready (bready),
        .s_axi_araddr  (araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata   (rdata),  .s_axi_rresp  (rresp),   .s_axi_rvalid (rvalid),
        .s_axi_rready  (rready),
        .uart_rx       (uart_rx_drv),
        .irq           ()
    );

    // ── AXI4-Lite 쓰기 태스크 ────────────────────────────────────
    integer timeout;
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
    begin
        @(posedge clk);
        awaddr <= addr; awvalid <= 1;
        wdata  <= data; wvalid  <= 1;
        // awready + wready 대기
        timeout = 200;
        fork
            begin: wa
                wait(awready); @(posedge clk); awvalid <= 0;
            end
            begin: ww
                wait(wready);  @(posedge clk); wvalid  <= 0;
            end
        join
        // bvalid 대기
        timeout = 200;
        wait(bvalid); @(posedge clk);
    end
    endtask

    // ── AXI4-Lite 읽기 태스크 ────────────────────────────────────
    reg [31:0] rd_result;
    task axi_read;
        input [31:0] addr;
    begin
        @(posedge clk);
        araddr <= addr; arvalid <= 1;
        wait(arready); @(posedge clk); arvalid <= 0;
        wait(rvalid);  rd_result <= rdata; @(posedge clk);
    end
    endtask

    // ── UART 바이트 전송 (LSB 먼저, 8N1) ────────────────────────
    task uart_send_byte;
        input [7:0] byte_val;
        integer i;
    begin
        // start bit
        uart_rx_drv = 0; repeat(CPB) @(posedge clk);
        // 데이터 비트 (LSB first)
        for (i=0; i<8; i=i+1) begin
            uart_rx_drv = byte_val[i]; repeat(CPB) @(posedge clk);
        end
        // stop bit
        uart_rx_drv = 1; repeat(CPB) @(posedge clk);
    end
    endtask

    // ── UART 프레임 전송 ─────────────────────────────────────────
    task uart_send_frame;
        input [15:0] d1, d2, d3;
    begin
        uart_send_byte(8'hBB);
        uart_send_byte(d1[15:8]); uart_send_byte(d1[7:0]);
        uart_send_byte(d2[15:8]); uart_send_byte(d2[7:0]);
        uart_send_byte(d3[15:8]); uart_send_byte(d3[7:0]);
        uart_send_byte(8'hEE);
    end
    endtask

    // ── 검증 카운터 ───────────────────────────────────────────────
    integer pass_cnt = 0, fail_cnt = 0;
    task check_eq;
        input [63:0] got;
        input [63:0] exp;
        input [127:0] label;
    begin
        if (got !== exp) begin
            $display("FAIL: %s got=%0d exp=%0d", label, got, exp);
            fail_cnt = fail_cnt + 1;
        end else begin
            pass_cnt = pass_cnt + 1;
        end
    end
    endtask

    // ── 메인 테스트 시퀀스 ───────────────────────────────────────
    integer i;
    reg [31:0] status;

    initial begin
        $display("=== tb_ble_trilat_ip start ===");
        // 리셋 해제 대기
        wait(rst_n); repeat(2) @(posedge clk);

        // ── TEST 1: IP 표준 관리 레지스터 확인 ──────────────────
        axi_read(BASE + 32'hFFF0); check_eq(rd_result, 32'h544C524C, "ID     ");
        axi_read(BASE + 32'hFFF4); check_eq(rd_result, 32'h01000001, "VER    ");

        // ── TEST 2: D-레지스터 AXI 쓰기/읽기 ───────────────────
        axi_write(BASE + 32'h08, 32'd200);  // D1
        axi_write(BASE + 32'h0C, 32'd300);  // D2
        axi_write(BASE + 32'h10, 32'd500);  // D3
        axi_read (BASE + 32'h08); check_eq(rd_result[15:0], 16'd200, "D1_REG ");
        axi_read (BASE + 32'h0C); check_eq(rd_result[15:0], 16'd300, "D2_REG ");
        axi_read (BASE + 32'h10); check_eq(rd_result[15:0], 16'd500, "D3_REG ");

        // ── TEST 3: 수동 삼변측량 (TRIG=1) ─────────────────────
        // d1=200,d2=300,d3=500 → w1=800,w2=700,w3=500,W=2000
        // x=(700*400+500*200)/2000=(280000+100000)/2000=190
        // y=(500*346)/2000=173000/2000=86 (truncate)
        axi_write(BASE + 32'h14, 32'd1);  // TRIG
        // calc_done 대기 (STATUS[1]=1)
        status = 0;
        for (i=0; i<2000 && !status[1]; i=i+1) begin
            @(posedge clk);
            axi_read(BASE + 32'h04); status = rd_result;
        end
        check_eq(status[1], 1'b1, "calc_done");
        axi_read(BASE + 32'h18); check_eq(rd_result[15:0], 16'd190, "X_POS  ");
        axi_read(BASE + 32'h1C); check_eq(rd_result[15:0], 16'd86,  "Y_POS  ");

        // ── TEST 4: IRQ_ENABLE=1 → irq_stat 확인 ────────────────
        axi_write(BASE + 32'hFFFC, 32'd1);         // IRQ_ENABLE
        axi_read (BASE + 32'hFFF8);
        check_eq(rd_result[0], 1'b1, "IRQ_ST1");   // 아직 1
        axi_write(BASE + 32'hFFF8, 32'd1);          // W1C 소거
        axi_read (BASE + 32'hFFF8);
        check_eq(rd_result[0], 1'b0, "IRQ_CLR");   // 소거됨

        // ── TEST 5: auto_trig=1 + UART 프레임 ──────────────────
        // d1=100,d2=200,d3=400 → w1=900,w2=800,w3=600,W=2300
        // x=(800*400+600*200)/2300=(320000+120000)/2300=440000/2300=191
        // y=(600*346)/2300=207600/2300=90
        axi_write(BASE + 32'h00, 32'd1);  // CTRL auto_trig=1
        uart_send_frame(16'd100, 16'd200, 16'd400);
        // calc_done 대기
        status = 0;
        for (i=0; i<5000 && !status[1]; i=i+1) begin
            @(posedge clk);
            axi_read(BASE + 32'h04); status = rd_result;
        end
        check_eq(status[1], 1'b1, "auto_done");
        axi_read(BASE + 32'h18); check_eq(rd_result[15:0], 16'd191, "X_AUTO ");
        axi_read(BASE + 32'h1C); check_eq(rd_result[15:0], 16'd90,  "Y_AUTO ");

        // ── 결과 ────────────────────────────────────────────────
        if (fail_cnt == 0)
            $display("PASS: all %0d checks", pass_cnt);
        else
            $display("FAIL: %0d/%0d checks failed", fail_cnt, pass_cnt+fail_cnt);

        $finish;
    end

    // ── 타임아웃 가드 ────────────────────────────────────────────
    initial begin
        #2000000;
        $display("FAIL: simulation timeout");
        $finish;
    end

endmodule
`default_nettype wire
