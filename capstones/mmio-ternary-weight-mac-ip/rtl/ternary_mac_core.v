// ternary_mac_core.v — 삼진 가중치 순차 MAC 코어
// 가중치 2비트 인코딩: 2'b00=0, 2'b01=+1, 2'b10=−1 (2'b11=unused)
// veclen 사이클 동안 순차적으로 2비트 가중치×8비트 활성화를 누산 (DSP 없음)
// Verilog-2001 — iverilog / verilator / yosys 호환
//
// 포트:
//   clk, rst_n       — 100 MHz, active-low reset
//   start            — 1클럭 펄스로 계산 시작
//   veclen[3:0]      — 요소 수 (0=1, 15=16)
//   weights[31:0]    — 2비트×16요소 패킹 (bit[1:0]=w[0], bit[3:2]=w[1], ...)
//   acts[127:0]      — 8비트×16요소 패킹 (bit[7:0]=a[0], bit[15:8]=a[1], ...)
//   result[23:0]     — 내적 결과 (부호 있는 24비트)
//   busy, done       — 상태 출력 (done은 1클럭 후 STATUS 레지스터가 래치)

`timescale 1ns/1ps

module ternary_mac_core (
    input  wire        clk,
    input  wire        rst_n,
    // 제어
    input  wire        start,
    input  wire [3:0]  veclen,      // 0 = 1요소, 15 = 16요소
    // 데이터
    input  wire [31:0] weights,     // 2비트×16 패킹
    input  wire [127:0] acts,       // 8비트×16 패킹 (부호 있는)
    // 출력
    output reg  [23:0] result,
    output reg         busy,
    output reg         done
);

    // 내부 상태
    reg [3:0]  idx;         // 현재 요소 인덱스
    reg [3:0]  total;       // veclen 래치

    // weight[i] = weights[i*2+1 : i*2]
    // act[i]    = acts[i*8+7   : i*8]  (8비트 부호 있음 → 24비트 부호 확장)

    wire [1:0]  w_i  = weights[idx*2 +:  2];
    wire [7:0]  a_i8 = acts[idx*8   +:  8];
    wire [23:0] a_i  = {{16{a_i8[7]}}, a_i8};  // 부호 확장

    localparam ST_IDLE = 2'd0, ST_RUN = 2'd1, ST_DONE = 2'd2;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= ST_IDLE;
            idx    <= 4'd0;
            total  <= 4'd0;
            result <= 24'd0;
            busy   <= 1'b0;
            done   <= 1'b0;
        end else begin
            done <= 1'b0;   // 1클럭 펄스

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        result <= 24'd0;
                        idx    <= 4'd0;
                        total  <= veclen;
                        busy   <= 1'b1;
                        state  <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    // 비트마스크 AND + 가산기 (DSP 없음)
                    case (w_i)
                        2'b01: result <= result + a_i;          // +1 × act
                        2'b10: result <= result + (~a_i + 24'd1); // −1 × act (부호 반전)
                        default: ; // 0: 아무것도 더하지 않음
                    endcase

                    if (idx == total) begin
                        // 마지막 요소 처리 완료
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= ST_DONE;
                    end else begin
                        idx <= idx + 4'd1;
                    end
                end

                ST_DONE: begin
                    // done 펄스는 이전 사이클에 발생. 여기서는 start 대기
                    if (start) begin
                        result <= 24'd0;
                        idx    <= 4'd0;
                        total  <= veclen;
                        busy   <= 1'b1;
                        done   <= 1'b0;
                        state  <= ST_RUN;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
