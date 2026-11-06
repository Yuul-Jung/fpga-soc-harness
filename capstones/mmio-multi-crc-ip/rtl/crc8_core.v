// crc8_core.v — CRC-8/Dallas-Maxim (1-Wire) parallel combinational core
// Polynomial: 0x31 (x^8+x^5+x^4+1), reflected (refin=true, refout=true)
// Reflected poly: 0x8C
// Init: 0xFF (applied by wrapper, not this core)
// XorOut: 0x00
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
// Algorithm: 8-step serial LFSR unrolled as a Verilog function (synthesisable in yosys/verilator)
`default_nettype none
module crc8_core (
    input  wire [7:0] crc_in,   // current CRC accumulator
    input  wire [7:0] data,     // 1 byte input
    output wire [7:0] crc_out   // next CRC accumulator
);

// crc8_step: 8x unrolled reflected LFSR (poly=0x8C)
// d[0] is processed first (LSB first), CRC shifts right, XOR on LSB feedback
function [7:0] crc8_step;
    input [7:0] c;
    input [7:0] d;
    integer i;
    reg [7:0] t;
    begin
        t = c;
        for (i = 0; i < 8; i = i + 1) begin
            if ((t[0] ^ d[i]) == 1'b1)
                t = {1'b0, t[7:1]} ^ 8'h8C;
            else
                t = {1'b0, t[7:1]};
        end
        crc8_step = t;
    end
endfunction

assign crc_out = crc8_step(crc_in, data);

endmodule
`default_nettype wire
