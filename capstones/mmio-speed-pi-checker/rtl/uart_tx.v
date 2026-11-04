// uart_tx.v — UART 8N1 송신 전용
// 원본: capstones/mmio-pwm-qenc-checker/rtl/uart_tx.v
// 115200 baud @ 100 MHz → 분주비 868
`timescale 1ns/1ps
module uart_tx (
    input  wire        clk,
    input  wire        rst,
    // MMIO 슬레이브 포트
    input  wire        valid,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // 보드 I/O
    output reg         tx
);
    localparam BAUD_DIV = 868;

    reg [9:0]  shift;
    reg [3:0]  bit_cnt;
    reg [9:0]  baud_cnt;
    reg        busy;

    always @(posedge clk) begin
        if (rst) begin
            tx       <= 1'b1;
            busy     <= 1'b0;
            bit_cnt  <= 4'd0;
            baud_cnt <= 10'd0;
            shift    <= 10'h3FF;
            rdata    <= 32'd0;
        end else begin
            // MMIO 읽기
            if (valid && !we) begin
                case (off)
                    16'h0004: rdata <= {31'd0, busy};
                    default:  rdata <= 32'd0;
                endcase
            end
            // MMIO 쓰기 (DATA)
            if (valid && we && off == 16'h0000 && !busy) begin
                shift   <= {1'b1, wdata[7:0], 1'b0}; // stop, data[7:0], start
                bit_cnt <= 4'd10;
                busy    <= 1'b1;
                baud_cnt <= 10'd0;
            end
            // 보내기
            if (busy) begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 10'd0;
                    tx       <= shift[0];
                    shift    <= {1'b1, shift[9:1]};
                    bit_cnt  <= bit_cnt - 4'd1;
                    if (bit_cnt == 4'd1) busy <= 1'b0;
                end else begin
                    baud_cnt <= baud_cnt + 10'd1;
                end
            end else begin
                tx <= 1'b1;
            end
        end
    end
endmodule
