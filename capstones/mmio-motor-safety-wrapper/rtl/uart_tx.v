// uart_tx.v — UART 8N1 송신 전용 슬레이브 (MMIO-lite)
// 0x00: DATA   WO  송신 바이트 [7:0]. busy=0 일 때만 유효
// 0x04: STATUS RO  bit0=busy
// CLKS_PER_BIT = 100_000_000 / 115_200 ≈ 868

`default_nettype none

module uart_tx #(
    parameter CLKS_PER_BIT = 868
) (
    input  wire        clk,
    input  wire        rst,
    // MMIO-lite 슬레이브
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // UART 핀
    output reg         tx
);

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [9:0]  baud_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_r;
    reg        busy;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            baud_cnt <= 10'd0;
            bit_idx  <= 3'd0;
            shift_r  <= 8'd0;
            busy     <= 1'b0;
            tx       <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (valid && we && addr[7:2] == 6'd0) begin
                        shift_r  <= wdata[7:0];
                        busy     <= 1'b1;
                        baud_cnt <= 10'd0;
                        state    <= S_START;
                    end
                end
                S_START: begin
                    tx <= 1'b0;
                    if (baud_cnt == CLKS_PER_BIT - 1) begin
                        baud_cnt <= 10'd0;
                        bit_idx  <= 3'd0;
                        state    <= S_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 10'd1;
                    end
                end
                S_DATA: begin
                    tx <= shift_r[bit_idx];
                    if (baud_cnt == CLKS_PER_BIT - 1) begin
                        baud_cnt <= 10'd0;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 10'd1;
                    end
                end
                S_STOP: begin
                    tx <= 1'b1;
                    if (baud_cnt == CLKS_PER_BIT - 1) begin
                        baud_cnt <= 10'd0;
                        busy     <= 1'b0;
                        state    <= S_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 10'd1;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    always @(*) begin
        case (addr[7:2])
            6'd0:    rdata = 32'd0;          // DATA WO
            6'd1:    rdata = {31'd0, busy};
            default: rdata = 32'd0;
        endcase
    end

endmodule

`default_nettype wire
