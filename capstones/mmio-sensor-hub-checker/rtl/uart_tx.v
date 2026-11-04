// uart_tx.v — 115200 baud 송신 전용, FIFO 없음
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 100 MHz / 115200 ≈ 868 cycles/bit
// 레지스터: 0x00 DATA(WO) [7:0], 0x04 STATUS(RO) [0]=busy

`timescale 1ns/1ps
module uart_tx #(
    parameter CLK_DIV = 868
)(
    input  wire        clk,
    input  wire        rst_n,
    // MMIO-lite
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        sel,
    output reg  [31:0] rdata,
    // UART 핀
    output reg         tx
);

    reg [9:0]  shift;   // start + 8data + stop
    reg [3:0]  bit_cnt;
    reg [9:0]  clk_cnt;
    reg        busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx      <= 1'b1;
            busy    <= 1'b0;
            bit_cnt <= 4'd0;
            clk_cnt <= 10'd0;
            shift   <= 10'h3FF;
        end else begin
            if (!busy) begin
                tx <= 1'b1;
                if (sel && we && addr[3:0] == 4'h0) begin
                    shift   <= {1'b1, wdata[7:0], 1'b0}; // stop, data, start
                    bit_cnt <= 4'd10;
                    clk_cnt <= 10'd0;
                    busy    <= 1'b1;
                end
            end else begin
                if (clk_cnt == CLK_DIV - 1) begin
                    clk_cnt <= 10'd0;
                    tx      <= shift[0];
                    shift   <= {1'b1, shift[9:1]};
                    bit_cnt <= bit_cnt - 1'b1;
                    if (bit_cnt == 4'd1) busy <= 1'b0;
                end else begin
                    clk_cnt <= clk_cnt + 1'b1;
                end
            end
        end
    end

    always @(*) begin
        rdata = 32'd0;
        if (sel) begin
            case (addr[3:0])
                4'h4: rdata = {31'd0, busy};
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
