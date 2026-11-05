`timescale 1ns/1ps
// uart_tx.v — UART 8N1 송신기
// clk 100 MHz, 동기 리셋(active-low rst_n)
// CLKS_PER_BIT 파라미터로 보드레이트 설정 (기본 10417 = 100 MHz / 9600 bps)
// start 1클럭 펄스 → data[7:0] 직렬 출력 → busy 하강 시 완료
`default_nettype none
module uart_tx #(
    parameter CLKS_PER_BIT = 10417  // 100 MHz / 9600
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data,    // 송신 데이터 (start 시 래치)
    input  wire       start,   // 1클럭 송신 시작 펄스
    output reg        tx,      // 직렬 출력 (idle=1)
    output reg        busy     // 송신 중
);
    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [13:0] clk_cnt;   // CLKS_PER_BIT ≤ 10417 < 2^14
    reg [2:0]  bit_idx;
    reg [7:0]  data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            tx       <= 1'b1;
            busy     <= 1'b0;
            clk_cnt  <= 14'd0;
            bit_idx  <= 3'd0;
            data_reg <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (start) begin
                        data_reg <= data;
                        clk_cnt  <= 14'd0;
                        busy     <= 1'b1;
                        tx       <= 1'b0;   // 스타트 비트
                        state    <= S_START;
                    end
                end
                S_START: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 14'd0;
                        bit_idx <= 3'd0;
                        tx      <= data_reg[0];
                        state   <= S_DATA;
                    end else
                        clk_cnt <= clk_cnt + 14'd1;
                end
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 14'd0;
                        if (bit_idx == 3'd7) begin
                            tx    <= 1'b1;  // 스톱 비트
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                            tx      <= data_reg[bit_idx + 3'd1];
                        end
                    end else
                        clk_cnt <= clk_cnt + 14'd1;
                end
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 14'd0;
                        busy    <= 1'b0;
                        state   <= S_IDLE;
                    end else
                        clk_cnt <= clk_cnt + 14'd1;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
