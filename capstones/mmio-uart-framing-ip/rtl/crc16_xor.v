// crc16_xor.v — CRC-16/CCITT-FALSE 병렬 XOR 트리
// poly=0x1021, init=0xFFFF, refin=false, refout=false, xorout=0x0000
// 입력: 1바이트씩 스트리밍 (data_valid strobe)
// 리셋: crc_rst=1 → 내부 상태를 0xFFFF로 초기화
// 출력: crc_out — 현재 누적 CRC (조합 출력이 아니라 등록 출력)
// BRAM/ROM 없음; 조합 XOR 트리 1클럭 지연

`timescale 1ns/1ps
module crc16_xor (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        crc_rst,     // 패킷 시작마다 1클럭 High
    input  wire [7:0]  data_in,
    input  wire        data_valid,  // 1클럭 strobe
    output reg  [15:0] crc_out
);

// CRC-16/CCITT-FALSE 조합 함수
// crc_next[i] = XOR 트리 (256비트 입력에서 각 출력 비트를 계산)
function [15:0] crc16_next;
    input [15:0] crc;
    input [7:0]  d;
    reg [15:0] c;
    begin
        c = crc;
        crc16_next[0]  = c[8]  ^ c[12] ^ d[0] ^ d[4];
        crc16_next[1]  = c[9]  ^ c[13] ^ d[1] ^ d[5];
        crc16_next[2]  = c[10] ^ c[14] ^ d[2] ^ d[6];
        crc16_next[3]  = c[11] ^ c[15] ^ d[3] ^ d[7];
        crc16_next[4]  = c[12] ^ d[4];
        crc16_next[5]  = c[8]  ^ c[12] ^ c[13] ^ d[0] ^ d[4] ^ d[5];
        crc16_next[6]  = c[9]  ^ c[13] ^ c[14] ^ d[1] ^ d[5] ^ d[6];
        crc16_next[7]  = c[10] ^ c[14] ^ c[15] ^ d[2] ^ d[6] ^ d[7];
        crc16_next[8]  = c[0]  ^ c[11] ^ c[15] ^ d[3] ^ d[7];
        crc16_next[9]  = c[1]  ^ c[12] ^ d[4];
        crc16_next[10] = c[2]  ^ c[13] ^ d[5];
        crc16_next[11] = c[3]  ^ c[14] ^ d[6];
        crc16_next[12] = c[4]  ^ c[8]  ^ c[12] ^ c[15] ^ d[0] ^ d[4] ^ d[7];
        crc16_next[13] = c[5]  ^ c[9]  ^ c[13] ^ d[1] ^ d[5];
        crc16_next[14] = c[6]  ^ c[10] ^ c[14] ^ d[2] ^ d[6];
        crc16_next[15] = c[7]  ^ c[11] ^ c[15] ^ d[3] ^ d[7];
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n || crc_rst) begin
        crc_out <= 16'hFFFF;
    end else if (data_valid) begin
        crc_out <= crc16_next(crc_out, data_in);
    end
end

endmodule
