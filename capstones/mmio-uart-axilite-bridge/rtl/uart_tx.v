// uart_tx.v — UART 8N1 송신기
// 115200 baud @ 100 MHz → BAUD_DIV = 868
// 핸드셰이크: valid↑ + ready=1 → 전송 시작. ready=0이면 대기.
//
// 출처: 하네스 직접 작성 원본. 외부 코드 없음.

`timescale 1ns/1ps
module uart_tx #(
    parameter BAUD_DIV = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data,
    input  wire       valid,
    output reg        ready,
    output reg        tx
);
    reg [10:0] cnt;
    reg [3:0]  bit_cnt;  // 0 = 스타트, 1-8 = 데이터, 9+ = 스톱 후 완료
    reg [7:0]  tx_sreg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx      <= 1'b1;
            ready   <= 1'b1;
            cnt     <= 0;
            bit_cnt <= 0;
            tx_sreg <= 8'h00;
        end else if (ready) begin
            if (valid) begin
                tx_sreg <= data;
                ready   <= 1'b0;
                cnt     <= BAUD_DIV[10:0] - 1;
                bit_cnt <= 4'd0;
                tx      <= 1'b0;   // 스타트 비트
            end
        end else begin
            if (cnt == 0) begin
                cnt <= BAUD_DIV[10:0] - 1;
                if (bit_cnt <= 4'd7) begin
                    tx      <= tx_sreg[bit_cnt];
                    bit_cnt <= bit_cnt + 1;
                end else begin
                    // 스톱 비트 출력 후 완료
                    tx    <= 1'b1;
                    ready <= 1'b1;
                end
            end else begin
                cnt <= cnt - 1;
            end
        end
    end
endmodule
