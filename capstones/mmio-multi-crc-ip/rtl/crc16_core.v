// crc16_core.v — CRC-16-CCITT parallel combinational core
// Polynomial: 0x1021 (x^16+x^12+x^5+1), not reflected (refin=false, refout=false)
// Init: 0xFFFF (applied by wrapper, not this core)
// XorOut: 0x0000
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
// Algorithm: 8-step serial LFSR unrolled as a Verilog function (synthesisable in yosys/verilator)
`default_nettype none
module crc16_core (
    input  wire [15:0] crc_in,   // current CRC accumulator
    input  wire  [7:0] data,     // 1 byte input
    output wire [15:0] crc_out   // next CRC accumulator
);

// crc16_step: 8x unrolled MSB-first LFSR (poly=0x1021, not reflected)
// d[7] is processed first (MSB first), CRC shifts left, XOR on MSB feedback
function [15:0] crc16_step;
    input [15:0] c;
    input  [7:0] d;
    integer i;
    reg [15:0] t;
    begin
        t = c;
        for (i = 7; i >= 0; i = i - 1) begin
            if ((t[15] ^ d[i]) == 1'b1)
                t = {t[14:0], 1'b0} ^ 16'h1021;
            else
                t = {t[14:0], 1'b0};
        end
        crc16_step = t;
    end
endfunction

assign crc_out = crc16_step(crc_in, data);

endmodule
`default_nettype wire
