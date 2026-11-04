// uart_tx.v — UART 8N1 송신 전용 슬레이브 (mmio-pid-step-capture)
// 0x00: DATA   (WO) 송신 바이트 [7:0]
// 0x04: STATUS (RO) bit0=busy
// 115200 baud @ 100 MHz → 분주: 100_000_000/115200 ≈ 868
// Verilog-2001
`default_nettype none

module uart_tx (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid,
    input  wire        we,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    output reg         txd
);

    parameter CLK_HZ   = 100_000_000;
    parameter BAUD     = 115_200;
    localparam DIVIDER = CLK_HZ / BAUD;  // 868

    reg [9:0]  shift;   // start + 8 data + stop
    reg [9:0]  baud_cnt;
    reg [3:0]  bit_cnt;
    reg        busy;

    // 쓰기: 바이트 적재
    always @(posedge clk) begin
        if (rst) begin
            busy    <= 1'b0;
            txd     <= 1'b1;
            bit_cnt <= 4'd0;
            baud_cnt<= 10'd0;
            shift   <= 10'h3FF;
        end else if (!busy && valid && we && addr == 4'h0) begin
            // start(0) + data[7:0] + stop(1)
            shift    <= {1'b1, wdata[7:0], 1'b0};
            bit_cnt  <= 4'd10;
            baud_cnt <= 10'd0;
            busy     <= 1'b1;
        end else if (busy) begin
            if (baud_cnt == DIVIDER - 1) begin
                baud_cnt <= 10'd0;
                txd      <= shift[0];
                shift    <= {1'b1, shift[9:1]};
                bit_cnt  <= bit_cnt - 4'd1;
                if (bit_cnt == 4'd1)
                    busy <= 1'b0;
            end else begin
                baud_cnt <= baud_cnt + 10'd1;
            end
        end
    end

    // 읽기
    always @(*) begin
        case (addr)
            4'h4: rdata = {31'h0, busy};
            default: rdata = 32'h0;
        endcase
    end

endmodule
`default_nettype wire
