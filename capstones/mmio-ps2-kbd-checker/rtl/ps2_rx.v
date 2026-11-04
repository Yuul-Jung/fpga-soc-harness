// ps2_rx.v — PS/2 수신기 (PS/2 Set 2 스캔코드, Verilog-2001)
// 하네스 직접 작성 원본.
//
// PS/2 프레임 구조: [START=0] [D0..D7] [PARITY(홀수)] [STOP=1]
// 하강 에지에서 데이터를 샘플링한다.
// PS/2 CLK과 DATA는 2단 동기화 후 사용한다.
//
// 출력:
//   rx_data[7:0]  — 수신된 스캔코드 바이트 (rx_valid 사이클에만 유효)
//   rx_valid      — 1사이클 펄스, 오류 없이 한 프레임을 완수했을 때
//   rx_err        — 1사이클 펄스, 패리티 또는 정지 비트 오류
`timescale 1ns/1ps
module ps2_rx (
    input  wire       clk,
    input  wire       rst,
    // PS/2 핀 (외부 입력)
    input  wire       ps2_clk_in,
    input  wire       ps2_data_in,
    // 출력
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    output reg        rx_err
);

    // ----------------------------------------------------------------
    // PS/2 CLK 2단 동기화 + 하강 에지 검출
    // ----------------------------------------------------------------
    reg ps2_c1, ps2_c2, ps2_c3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ps2_c1 <= 1'b1;
            ps2_c2 <= 1'b1;
            ps2_c3 <= 1'b1;
        end else begin
            ps2_c1 <= ps2_clk_in;
            ps2_c2 <= ps2_c1;
            ps2_c3 <= ps2_c2;
        end
    end
    // 하강 에지: 직전이 High, 현재가 Low
    wire clk_fall = ps2_c3 & (~ps2_c2);

    // ----------------------------------------------------------------
    // PS/2 DATA 2단 동기화
    // ----------------------------------------------------------------
    reg ps2_d1, ps2_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ps2_d1 <= 1'b1;
            ps2_d2 <= 1'b1;
        end else begin
            ps2_d1 <= ps2_data_in;
            ps2_d2 <= ps2_d1;
        end
    end

    // ----------------------------------------------------------------
    // 수신 FSM
    //   bit_cnt=0  : 대기 (START 비트 검출)
    //   bit_cnt=1~8: 데이터 비트 D0~D7 (LSB 먼저)
    //   bit_cnt=9  : 패리티 비트
    //   bit_cnt=10 : 정지 비트 → 출력
    // ----------------------------------------------------------------
    reg [3:0]  bit_cnt;
    reg [7:0]  data_sr;    // D0부터 순서대로 쌓는 시프트 레지스터
    reg        parity_acc; // 수신한 데이터 비트의 XOR 누산

    always @(posedge clk or posedge rst) begin
        rx_valid <= 1'b0;
        rx_err   <= 1'b0;
        if (rst) begin
            bit_cnt    <= 4'd0;
            data_sr    <= 8'h00;
            parity_acc <= 1'b0;
        end else if (clk_fall) begin
            case (bit_cnt)
                4'd0: begin
                    // START 비트 = 0 이면 수신 시작
                    if (~ps2_d2) begin
                        data_sr    <= 8'h00;
                        parity_acc <= 1'b0;
                        bit_cnt    <= 4'd1;
                    end
                    // START = 1 이면 무시 (라인 High 상태)
                end
                4'd1, 4'd2, 4'd3, 4'd4,
                4'd5, 4'd6, 4'd7, 4'd8: begin
                    // 데이터 비트: D0(bit_cnt=1)~D7(bit_cnt=8)
                    // LSB 먼저이므로 MSB 쪽으로 밀어 쌓는다
                    data_sr    <= {ps2_d2, data_sr[7:1]};
                    parity_acc <= parity_acc ^ ps2_d2;
                    bit_cnt    <= bit_cnt + 4'd1;
                end
                4'd9: begin
                    // 패리티 비트 (홀수 패리티 → data XOR parity = 1)
                    // 여기서는 parity_acc에 패리티 비트를 XOR해 나중에 판정
                    data_sr    <= data_sr; // 유지
                    parity_acc <= parity_acc ^ ps2_d2;
                    bit_cnt    <= 4'd10;
                end
                4'd10: begin
                    // 정지 비트 = 1
                    bit_cnt <= 4'd0;
                    if (ps2_d2 && (parity_acc == 1'b1)) begin
                        // 정지=1, 홀수 패리티 OK
                        rx_data  <= data_sr;
                        rx_valid <= 1'b1;
                    end else begin
                        rx_err <= 1'b1;
                    end
                end
                default: bit_cnt <= 4'd0;
            endcase
        end
    end
endmodule
