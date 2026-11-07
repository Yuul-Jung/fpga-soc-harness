// crc32_core.v — CRC-32/Ethernet 단계 함수 (바이트 단위, 조합 논리)
// slug: mmio-crc32-axil-ip
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
//
// 알고리즘: CRC-32/Ethernet
//   poly    = 0x04C11DB7, reflected = 0xEDB88320
//   refin   = true (LSB-first)
//   refout  = true (LSB-first output)
//   init    = 0xFFFFFFFF (crc_reg 초기값, 이 모듈 밖에서 보관)
//   xorout  = 0xFFFFFFFF (소프트웨어 드라이버가 CRC_OUT 읽은 뒤 XOR)
//
// 포트:
//   crc_in  [31:0] — 현재 누산 CRC (레지스터 값)
//   data_in [ 7:0] — 처리할 1바이트
//   crc_out [31:0] — 1바이트 처리 후 새 CRC (조합 출력)
//
// 구현: 8스텝 직렬 LFSR 전개. 순수 조합 논리.
//   각 스텝: feedback = crc[0] XOR data_bit
//           if feedback: c = {0, c[31:1]} ^ 0xEDB88320
//           else:        c = {0, c[31:1]}
//
// Verilog-2001. iverilog/verilator/yosys 호환.

`default_nettype none
`timescale 1ns/1ps

module crc32_core (
    input  wire [31:0] crc_in,
    input  wire [ 7:0] data_in,
    output wire [31:0] crc_out
);

    // 8단계 LFSR 전개 (반사 CRC-32)
    function [31:0] crc32_step8;
        input [31:0] crc;
        input [ 7:0] d;
        reg [31:0] c;
        reg [ 7:0] dd;
        integer j;
        begin
            c  = crc;
            dd = d;
            for (j = 0; j < 8; j = j + 1) begin
                if ((c[0] ^ dd[0]) == 1'b1)
                    c = {1'b0, c[31:1]} ^ 32'hEDB8_8320;
                else
                    c = {1'b0, c[31:1]};
                dd = {1'b0, dd[7:1]};
            end
            crc32_step8 = c;
        end
    endfunction

    assign crc_out = crc32_step8(crc_in, data_in);

endmodule
`default_nettype wire
