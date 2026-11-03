// UART 송신(8N1): 0x00 DATA(WO, busy일 때 쓰기는 무시), 0x04 STATUS(RO, bit0=busy)
module uart_tx #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD   = 115200
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [7:0]  off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output wire        txd
);
    localparam DIV = CLK_HZ / BAUD;

    reg [9:0]  sh;
    reg [3:0]  nbit;
    reg [15:0] cnt;
    reg        busy;
    reg        tx;
    assign txd = tx;

    wire wr_data = sel && we && (off == 8'h00);

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
            8'h04:   rdata = {31'd0, busy};
            default: rdata = 32'h0000_0000;
        endcase
    end
endmodule
