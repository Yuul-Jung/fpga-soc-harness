// ts_fifo.v
// Synchronous FIFO with configurable depth and data width
// Depth must be power of 2; uses distributed RAM (no BRAM pragma)
// Verilog-2001

`timescale 1ns/1ps

module ts_fifo #(
    parameter DEPTH  = 16,
    parameter DWIDTH = 72
) (
    input  wire              clk,
    input  wire              rst_n,     // synchronous, active-low
    input  wire              push,
    input  wire [DWIDTH-1:0] din,
    input  wire              pop,
    output wire [DWIDTH-1:0] dout,
    output wire [4:0]        cnt,
    output wire              full,
    output wire              empty
);

    localparam ADDR_W = $clog2(DEPTH);

    reg [DWIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W:0]   wr_ptr;
    reg [ADDR_W:0]   rd_ptr;

    wire [ADDR_W-1:0] wr_addr = wr_ptr[ADDR_W-1:0];
    wire [ADDR_W-1:0] rd_addr = rd_ptr[ADDR_W-1:0];

    assign cnt   = wr_ptr - rd_ptr;
    assign full  = (cnt >= DEPTH[4:0]);
    assign empty = (cnt == 5'd0);
    assign dout  = mem[rd_addr];

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= {(ADDR_W+1){1'b0}};
            rd_ptr <= {(ADDR_W+1){1'b0}};
        end else begin
            if (push && !full) begin
                mem[wr_addr] <= din;
                wr_ptr       <= wr_ptr + 1'b1;
            end
            if (pop && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule
