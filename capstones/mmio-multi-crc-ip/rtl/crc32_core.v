// crc32_core.v — CRC-32/Ethernet parallel combinational core
// Polynomial: 0x04C11DB7, reflected (refin=true, refout=true)
// Reflected poly: 0xEDB88320
// Init: 0xFFFFFFFF (applied by wrapper, not this core)
// XorOut: 0xFFFFFFFF (applied by software driver, not this core)
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
// Algorithm: 8-step serial LFSR unrolled as a Verilog function (synthesisable in yosys/verilator)
`default_nettype none
module crc32_core (
    input  wire [31:0] crc_in,   // current CRC accumulator
    input  wire  [7:0] data,     // 1 byte input
    output wire [31:0] crc_out   // next CRC accumulator
);

// crc32_step: 8x unrolled reflected LFSR (reflected poly=0xEDB88320)
// d[0] is processed first (LSB first), CRC shifts right, XOR on LSB feedback
function [31:0] crc32_step;
    input [31:0] c;
    input  [7:0] d;
    integer i;
    reg [31:0] t;
    begin
        t = c;
        for (i = 0; i < 8; i = i + 1) begin
            if ((t[0] ^ d[i]) == 1'b1)
                t = {1'b0, t[31:1]} ^ 32'hEDB88320;
            else
                t = {1'b0, t[31:1]};
        end
        crc32_step = t;
    end
endfunction

assign crc_out = crc32_step(crc_in, data);

endmodule
`default_nettype wire
