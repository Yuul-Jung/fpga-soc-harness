`timescale 1ns/1ps
// uart_rx.v — UART 8N1 수신기
// clk 100 MHz, 동기 리셋(active-low rst_n)
// CLKS_PER_BIT 파라미터로 보드레이트 설정 (기본 10417 = 100 MHz / 9600 bps)
// 2단 FF 동기화 → 스타트 비트 중앙(CLKS_PER_BIT/2) 확인 → 각 데이터 비트 중앙 샘플
// 스톱 비트 확인 후 rx_done 1클럭 펄스 + data[7:0] 출력
`default_nettype none
module uart_rx #(
    parameter CLKS_PER_BIT = 10417
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,       // 직렬 입력 (idle=1)
    output reg  [7:0] data,     // 수신 데이터 (rx_done과 동시에 유효)
    output reg        rx_done   // 1클럭 수신 완료 펄스
);
    // 2단 동기화
    reg rx_s1, rx_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_s1 <= 1'b1;
            rx_s2 <= 1'b1;
        end else begin
            rx_s1 <= rx;
            rx_s2 <= rx_s1;
        end
    end

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    // CLKS_PER_BIT/2: 스타트 비트 중앙 오프셋
    localparam HALF_BIT = CLKS_PER_BIT / 2;

    reg [1:0]  state;
    reg [13:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            clk_cnt  <= 14'd0;
            bit_idx  <= 3'd0;
            data_reg <= 8'd0;
            data     <= 8'd0;
            rx_done  <= 1'b0;
        end else begin
            rx_done <= 1'b0;  // 기본값
            case (state)
                S_IDLE: begin
                    if (!rx_s2) begin  // 스타트 비트 하강 엣지
                        clk_cnt <= 14'd0;
                        state   <= S_START;
                    end
                end
                S_START: begin
                    // 스타트 비트 중앙(HALF_BIT - 1)에서 여전히 Low인지 확인
                    if (clk_cnt == HALF_BIT - 1) begin
                        if (!rx_s2) begin
                            clk_cnt <= 14'd0;
                            bit_idx <= 3'd0;
                            state   <= S_DATA;
                        end else
                            state   <= S_IDLE;  // 잡음 무시
                    end else
                        clk_cnt <= clk_cnt + 14'd1;
                end
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt           <= 14'd0;
                        data_reg[bit_idx] <= rx_s2;  // 비트 중앙에서 샘플
                        if (bit_idx == 3'd7)
                            state   <= S_STOP;
                        else
                            bit_idx <= bit_idx + 3'd1;
                    end else
                        clk_cnt <= clk_cnt + 14'd1;
                end
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 14'd0;
                        if (rx_s2) begin  // 스톱 비트 확인
                            data    <= data_reg;
                            rx_done <= 1'b1;
                        end
                        state <= S_IDLE;
                    end else
                        clk_cnt <= clk_cnt + 14'd1;
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
