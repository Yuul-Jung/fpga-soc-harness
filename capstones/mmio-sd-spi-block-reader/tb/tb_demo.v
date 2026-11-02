`timescale 1ns/1ps
// 자체 점검 테스트벤치(시스템 수준): 데모 마스터가 버튼 한 번에 SD 블록 0의 첫 16바이트를 UART로 내보내는지 확인한다.
module tb_demo;
    localparam BIT_NS = 8680;                       // 115200 baud 근사 (100 MHz에서 868 클럭)

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg         btn = 1'b0;
    wire        m_valid, m_we, m_ready;
    wire [31:0] m_addr, m_wdata, m_rdata;
    wire [15:0] led;
    wire        txd, cs_n, sclk, mosi, miso;
    integer     errors = 0;
    integer     got = 0;
    integer     j;
    integer     jj;
    reg  [7:0]  rxb [0:15];
    reg  [7:0]  sh;

    always #5 clk = ~clk;

    demo_master u_master (
        .clk(clk), .rst(rst), .btn(btn),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready)
    );
    soc_top #(.CLK_HZ(100_000_000), .BAUD(115200)) dut (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(16'h0000), .led(led), .uart_txd(txd),
        .sd_cs_n(cs_n), .sd_sclk(sclk), .sd_mosi(mosi), .sd_miso(miso)
    );
    sd_card_model #(.SDHC(1)) card (.cs_n(cs_n), .sclk(sclk), .mosi(mosi), .miso(miso));

    always begin : uart_rx                          // 시작 비트 에지 → 각 비트 중앙에서 표본
        @(negedge txd);
        #(BIT_NS / 2);
        for (jj = 0; jj < 8; jj = jj + 1) begin
            #(BIT_NS);
            sh[jj] = txd;
        end
        #(BIT_NS);
        if (txd !== 1'b1) begin errors = errors + 1; $display("FAIL stop bit"); end
        if (got < 16) rxb[got] = sh;
        got = got + 1;
    end

    initial begin
        #100_000_000;
        $display("FAIL watchdog (got %0d bytes)", got);
        $finish;
    end

    initial begin
        repeat (5) @(posedge clk);
        rst <= 1'b0;
        repeat (10) @(posedge clk);
        btn <= 1'b1;
        repeat (10) @(posedge clk);
        btn <= 1'b0;
        wait (got == 16);
        repeat (2000) @(posedge clk);
        for (j = 0; j < 16; j = j + 1)
            if (rxb[j] !== card.exp_byte(0, j)) begin
                errors = errors + 1;
                $display("FAIL byte %0d: got %h expected %h", j, rxb[j], card.exp_byte(0, j));
            end
        if (got !== 16) begin errors = errors + 1; $display("FAIL byte count %0d", got); end
        if (led !== 16'h010A) begin errors = errors + 1; $display("FAIL led %h expected 010a", led); end
        if (card.order_err || card.slow_viol) begin errors = errors + 1; $display("FAIL card protocol flags"); end
        if (errors == 0) $display("PASS tb_demo");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule
