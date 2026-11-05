// uart_rx.v — UART 8N1 수신기
// 원본: capstones/mmio-uart-axilite-bridge/rtl/uart_rx.v
// 이 복사본은 mmio-hc05-bt-tel-ip 에서 사용. 원본 수정 시 함께 반영할 것.
// BAUD_DIV 기본값: 10417 (9600 bps @ 100 MHz)
// 출력: data[7:0], valid (1클럭 펄스)
//
// 출처: 하네스 직접 작성 원본. 외부 코드 없음.

`timescale 1ns/1ps
module uart_rx #(
    parameter BAUD_DIV = 10417
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);
    localparam HALF     = BAUD_DIV / 2;
    // 스타트 비트 감지 후 첫 샘플까지 대기: BAUD_DIV + HALF - 2
    localparam INIT_CNT = BAUD_DIV + HALF - 2;

    reg [13:0] cnt;      // 보율 카운터
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
                    cnt     <= INIT_CNT[13:0];
                    bit_idx <= 4'd0;
                end
            end else begin
                if (cnt == 0) begin
                    cnt <= BAUD_DIV[13:0] - 1;
                    if (bit_idx < 4'd8) begin
                        shift   <= {rx, shift[7:1]};
                        bit_idx <= bit_idx + 1;
                    end else begin
                        active <= 1'b0;
                        if (rx) begin
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
