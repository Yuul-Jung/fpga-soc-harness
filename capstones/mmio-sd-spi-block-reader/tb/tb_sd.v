`timescale 1ns/1ps
// 자체 점검 테스트벤치(버스 수준): SD 초기화, 블록 읽기, 읽기 전 오류, 카드 없음 오류를 카드 모델로 확인한다.
module tb_sd;
    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg         m_valid = 1'b0;
    reg         m_we = 1'b0;
    reg  [31:0] m_addr = 32'd0;
    reg  [31:0] m_wdata = 32'd0;
    wire [31:0] m_rdata;
    wire        m_ready;
    wire [15:0] led;
    wire        txd, cs_n, sclk, mosi, miso;
    integer     errors = 0;
    reg  [31:0] rd;
    integer     k;

    always #5 clk = ~clk;

    soc_top dut (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(16'h0000), .led(led), .uart_txd(txd),
        .sd_cs_n(cs_n), .sd_sclk(sclk), .sd_mosi(mosi), .sd_miso(miso)
    );
    sd_card_model #(.SDHC(1)) card (.cs_n(cs_n), .sclk(sclk), .mosi(mosi), .miso(miso));

    task bus_write(input [31:0] a, input [31:0] d);
        begin
            @(posedge clk);
            m_valid <= 1'b1; m_we <= 1'b1; m_addr <= a; m_wdata <= d;
            @(posedge clk);
            m_valid <= 1'b0; m_we <= 1'b0;
        end
    endtask

    task bus_read(input [31:0] a, output [31:0] d);
        begin
            @(posedge clk);
            m_valid <= 1'b1; m_we <= 1'b0; m_addr <= a;
            @(posedge clk);
            d = m_rdata;
            m_valid <= 1'b0;
        end
    endtask

    task check32(input [255:0] name, input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s: got %h expected %h", name, got, exp);
            end
        end
    endtask

    task wait_idle;                       // STATUS.busy가 내려갈 때까지 기다린다
        integer guard;
        begin
            guard = 0;
            bus_read(32'h1000_2004, rd);
            while (rd[0] && guard < 20000) begin
                repeat (50) @(posedge clk);
                bus_read(32'h1000_2004, rd);
                guard = guard + 1;
            end
            if (rd[0]) begin errors = errors + 1; $display("FAIL wait_idle timeout"); end
        end
    endtask

    task check_buf(input [31:0] blk, input [8:0] i);
        begin
            bus_write(32'h1000_200C, {23'd0, i});
            bus_read(32'h1000_2010, rd);
            check32("buf byte", rd, {24'd0, card.exp_byte(blk, i)});
        end
    endtask

    initial begin
        #100_000_000;
        $display("FAIL watchdog");
        $finish;
    end

    initial begin
        repeat (5) @(posedge clk);
        rst <= 1'b0;
        repeat (3) @(posedge clk);

        bus_read(32'h1000_2004, rd);
        check32("status after reset", rd, 32'h0);

        bus_write(32'h1000_2000, 32'h2);                 // 초기화 전 읽기 요청 → 오류, busy 아님
        bus_read(32'h1000_2004, rd);
        check32("read before init", rd, 32'h4);

        bus_write(32'h1000_2000, 32'h1);                 // 초기화
        wait_idle;
        check32("status after init", rd, 32'hA);         // sdhc, init_done
        check32("no order error", {31'd0, card.order_err}, 32'h0);
        check32("slow clock respected", {31'd0, card.slow_viol}, 32'h0);

        bus_write(32'h1000_2008, 32'd5);                 // LBA 5 읽기
        bus_write(32'h1000_2000, 32'h2);
        wait_idle;
        check32("status after read", rd, 32'hA);
        check32("cmd17 arg", card.last17, 32'd5);
        check_buf(5, 0); check_buf(5, 1); check_buf(5, 2); check_buf(5, 255); check_buf(5, 256); check_buf(5, 511);
        for (k = 0; k < 512; k = k + 37) check_buf(5, k);

        bus_write(32'h1000_2008, 32'h1234);              // 다른 LBA
        bus_write(32'h1000_2000, 32'h2);
        wait_idle;
        check32("status after 2nd read", rd, 32'hA);
        check32("cmd17 arg 2", card.last17, 32'h1234);
        check32("cmd17 count", card.n17, 32'd2);
        check_buf(32'h1234, 0); check_buf(32'h1234, 300); check_buf(32'h1234, 511);
        check32("fast clock used", {31'd0, card.fast_seen}, 32'h1);
        check32("no order error end", {31'd0, card.order_err}, 32'h0);

        card.present = 1'b0;                             // 카드 없음: 초기화 실패
        bus_write(32'h1000_2000, 32'h1);
        wait_idle;
        check32("status no card", rd, 32'h4);
        bus_write(32'h1000_2000, 32'h2);
        bus_read(32'h1000_2004, rd);
        check32("read after failed init", rd, 32'h4);

        if (errors == 0) $display("PASS tb_sd");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule
