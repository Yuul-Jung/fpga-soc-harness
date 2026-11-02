`timescale 1ns/1ps
// 자체 점검 테스트벤치: LED/SW 레지스터, 미매핑 주소, UART 비트열(8N1, LSB 먼저)을 확인한다.
module tb_soc;
    localparam CLK_HZ = 1_000_000;
    localparam BAUD   = 100_000;
    localparam BIT_NS = (CLK_HZ / BAUD) * 10;   // 클럭 주기 10ns × 분주비

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg         m_valid = 1'b0;
    reg         m_we = 1'b0;
    reg  [31:0] m_addr = 32'd0;
    reg  [31:0] m_wdata = 32'd0;
    wire [31:0] m_rdata;
    wire        m_ready;
    reg  [15:0] sw = 16'hA5C3;
    wire [15:0] led;
    wire        txd;
    integer     errors = 0;

    always #5 clk = ~clk;

    soc_top #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) dut (
        .clk(clk), .rst(rst),
        .m_valid(m_valid), .m_we(m_we), .m_addr(m_addr), .m_wdata(m_wdata),
        .m_rdata(m_rdata), .m_ready(m_ready),
        .sw(sw), .led(led), .uart_txd(txd)
    );

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

    task uart_expect(input [7:0] data);
        integer i;
        begin
            @(negedge txd);
            #(BIT_NS / 2);
            if (txd !== 1'b0) begin errors = errors + 1; $display("FAIL start bit"); end
            for (i = 0; i < 8; i = i + 1) begin
                #(BIT_NS);
                if (txd !== data[i]) begin
                    errors = errors + 1;
                    $display("FAIL data bit %0d: got %b expected %b", i, txd, data[i]);
                end
            end
            #(BIT_NS);
            if (txd !== 1'b1) begin errors = errors + 1; $display("FAIL stop bit"); end
        end
    endtask

    reg [31:0] rd;

    initial begin
        #200000;
        $display("FAIL timeout");
        $finish;
    end

    initial begin
        repeat (5) @(posedge clk);
        rst <= 1'b0;
        repeat (3) @(posedge clk);

        // GPIO
        bus_write(32'h1000_0000, 32'h0000_1234);
        @(posedge clk);
        check32("led pin", {16'h0000, led}, 32'h0000_1234);
        bus_read(32'h1000_0000, rd);
        check32("led reg readback", rd, 32'h0000_1234);
        bus_read(32'h1000_0004, rd);
        check32("sw reg", rd, 32'h0000_A5C3);

        // 미매핑 주소
        bus_read(32'h2000_0000, rd);
        check32("unmapped read", rd, 32'h0000_0000);

        // UART
        bus_read(32'h1000_1004, rd);
        check32("uart idle status", rd, 32'h0000_0000);
        fork
            bus_write(32'h1000_1000, 32'h0000_00B2);
            uart_expect(8'hB2);
        join
        bus_read(32'h1000_1004, rd);
        check32("uart idle after tx", rd, 32'h0000_0000);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule
