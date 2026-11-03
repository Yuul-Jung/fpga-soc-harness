// uart_tx.v — UART 8N1 송신 전용 (mmio-lite 슬레이브)
// 0x00 DATA(WO, busy일 때 쓰기 무시), 0x04 STATUS(RO, bit0=busy)
`timescale 1ns/1ps
module uart_tx #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD   = 115200
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        txd
);
    localparam DIV = CLK_HZ / BAUD;

    reg [9:0]  sh;    // {stop, data[7:0], start}
    reg [3:0]  nbit;
    reg [15:0] cnt;
    reg        busy;
    reg        tx;

    assign txd = tx;

    wire wr_data = sel && we && (off == 16'h0000);

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            tx   <= 1'b1;
            cnt  <= 16'd0;
            nbit <= 4'd0;
            sh   <= 10'h3FF;
        end else if (!busy) begin
            tx <= 1'b1;
            if (wr_data) begin
                sh   <= {1'b1, wdata[7:0], 1'b0};
                busy <= 1'b1;
                cnt  <= DIV - 1;
                nbit <= 4'd0;
                tx   <= 1'b0;
            end
        end else begin
            if (cnt == 16'd0) begin
                cnt <= DIV - 1;
                if (nbit == 4'd9) begin
                    busy <= 1'b0;
                    tx   <= 1'b1;
                end else begin
                    nbit <= nbit + 4'd1;
                    tx   <= sh[nbit + 4'd1];
                end
            end else begin
                cnt <= cnt - 16'd1;
            end
        end
    end

    always @* begin
        case (off)
            16'h0004: rdata = {31'd0, busy};
            default:  rdata = 32'h0000_0000;
        endcase
    end
endmodule
