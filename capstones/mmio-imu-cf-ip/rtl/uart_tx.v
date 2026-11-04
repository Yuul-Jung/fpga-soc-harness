// uart_tx.v — 디버그 UART 송신기 (8N1, 115200 baud @ 100MHz)
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
module uart_tx #(
    parameter CLK_HZ   = 100_000_000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data,
    input  wire       valid,
    output reg        ready,
    output reg        tx
);

localparam CLKS_PER_BIT = CLK_HZ / BAUD; // 868

localparam ST_IDLE  = 2'd0;
localparam ST_START = 2'd1;
localparam ST_DATA  = 2'd2;
localparam ST_STOP  = 2'd3;

reg [1:0]  state;
reg [9:0]  clk_cnt;
reg [2:0]  bit_idx;
reg [7:0]  shift;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state   <= ST_IDLE;
        tx      <= 1'b1;
        ready   <= 1'b1;
        clk_cnt <= 10'd0;
        bit_idx <= 3'd0;
        shift   <= 8'd0;
    end else begin
        case (state)
        ST_IDLE: begin
            tx    <= 1'b1;
            ready <= 1'b1;
            if (valid) begin
                ready   <= 1'b0;
                shift   <= data;
                state   <= ST_START;
                clk_cnt <= 10'd0;
            end
        end
        ST_START: begin
            tx <= 1'b0;
            if (clk_cnt == CLKS_PER_BIT - 1) begin
                clk_cnt <= 10'd0;
                bit_idx <= 3'd0;
                state   <= ST_DATA;
            end else clk_cnt <= clk_cnt + 10'd1;
        end
        ST_DATA: begin
            tx <= shift[0];
            if (clk_cnt == CLKS_PER_BIT - 1) begin
                clk_cnt <= 10'd0;
                shift   <= {1'b0, shift[7:1]};
                if (bit_idx == 3'd7) state <= ST_STOP;
                else bit_idx <= bit_idx + 3'd1;
            end else clk_cnt <= clk_cnt + 10'd1;
        end
        ST_STOP: begin
            tx <= 1'b1;
            if (clk_cnt == CLKS_PER_BIT - 1) begin
                clk_cnt <= 10'd0;
                state   <= ST_IDLE;
            end else clk_cnt <= clk_cnt + 10'd1;
        end
        endcase
    end
end

endmodule
`default_nettype wire
