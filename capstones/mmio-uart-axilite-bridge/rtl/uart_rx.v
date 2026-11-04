// uart_rx.v — UART 8N1 수신기
// 115200 baud @ 100 MHz → BAUD_DIV = 868
// 출력: data[7:0], valid (1클럭 펄스)
//
// 출처: 하네스 직접 작성 원본. 외부 코드 없음.

`timescale 1ns/1ps
module uart_rx #(
    parameter BAUD_DIV = 868
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);
    localparam HALF     = BAUD_DIV / 2;
    // 스타트 비트 감지 후 첫 샘플까지 대기: BAUD_DIV + HALF - 2
    // = 1비트(스타트 완료) + 반비트(데이터 비트 0 중간) - 2클럭(감지+1사이클)
    localparam INIT_CNT = BAUD_DIV + HALF - 2;

    reg [10:0] cnt;      // 보율 카운터 (1300 < 2^11)
    reg [3:0]  bit_idx;  // 수신 비트 인덱스 (0..7 = 데이터, 8 = 스톱)
    reg [7:0]  shift;
    reg        active;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt    <= 0;
            bit_idx<= 0;
            active <= 1'b0;
            valid  <= 1'b0;
            data   <= 8'h00;
            shift  <= 8'h00;
        end else begin
            valid <= 1'b0;
            if (!active) begin
                // 스타트 비트 하강 에지 감지
                if (!rx) begin
                    active  <= 1'b1;
                    cnt     <= INIT_CNT[10:0]; // 데이터 비트 0 중간 샘플 위치까지 대기
                    bit_idx <= 4'd0;
                end
            end else begin
                if (cnt == 0) begin
                    cnt <= BAUD_DIV[10:0] - 1;
                    if (bit_idx < 4'd8) begin
                        // 데이터 비트 샘플 (LSB 먼저)
                        shift   <= {rx, shift[7:1]};
                        bit_idx <= bit_idx + 1;
                    end else begin
                        // 스톱 비트 샘플
                        active <= 1'b0;
                        if (rx) begin   // 유효한 스톱 비트
                            data  <= shift;
                            valid <= 1'b1;
                        end
                    end
                end else begin
                    cnt <= cnt - 1;
                end
            end
        end
    end
endmodule
