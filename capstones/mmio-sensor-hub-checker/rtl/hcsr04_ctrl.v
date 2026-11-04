// hcsr04_ctrl.v — HC-SR04 초음파 거리 센서 FSM
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 100 MHz 기준: TRIG 10 μs = 1000 cycles, 거리(cm) = echo_cycles / 5800
// ECHO 핀 5V 출력 → Basys3 Pmod 3.3V 레벨 변환 필수

`timescale 1ns/1ps
module hcsr04_ctrl #(
    parameter CLK_HZ     = 100_000_000,
    parameter TRIG_CYC   = 1000,          // 10 μs
    parameter TIMEOUT_CYC= 3_800_000      // 38 ms max echo
)(
    input  wire       clk,
    input  wire       rst_n,
    // MMIO 제어
    input  wire       start,              // 1-cycle 펄스
    // 센서 핀
    output reg        trig_o,
    input  wire       echo_i,             // 레벨 변환 후 입력
    // 결과
    output reg  [15:0] dist_cm,
    output reg        busy,
    output reg        done,
    output reg        timeout
);

    // 에코 카운터 비트 폭: log2(TIMEOUT_CYC) ≈ 22비트
    reg [22:0] cnt;
    reg [22:0] echo_cnt;

    // FSM 상태
    localparam S_IDLE    = 3'd0,
               S_TRIG    = 3'd1,
               S_WAIT_HI = 3'd2,   // 에코 High 대기
               S_MEASURE = 3'd3,   // 에코 High 구간 계측
               S_DONE    = 3'd4;

    reg [2:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            trig_o   <= 1'b0;
            busy     <= 1'b0;
            done     <= 1'b0;
            timeout  <= 1'b0;
            dist_cm  <= 16'd0;
            cnt      <= 23'd0;
            echo_cnt <= 23'd0;
        end else begin
            done <= 1'b0; // 1-cycle 펄스

            case (state)
                S_IDLE: begin
                    trig_o  <= 1'b0;
                    busy    <= 1'b0;
                    if (start) begin
                        trig_o  <= 1'b1;
                        busy    <= 1'b1;
                        timeout <= 1'b0;
                        cnt     <= 23'd0;
                        state   <= S_TRIG;
                    end
                end

                S_TRIG: begin
                    if (cnt == TRIG_CYC - 1) begin
                        trig_o <= 1'b0;
                        cnt    <= 23'd0;
                        state  <= S_WAIT_HI;
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end

                S_WAIT_HI: begin
                    if (echo_i) begin
                        echo_cnt <= 23'd0;
                        state    <= S_MEASURE;
                    end else if (cnt == TIMEOUT_CYC - 1) begin
                        timeout <= 1'b1;
                        state   <= S_DONE;
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end

                S_MEASURE: begin
                    if (!echo_i) begin
                        // 에코 종료 → 거리 계산
                        dist_cm <= echo_cnt[22:0] / 5800;
                        state   <= S_DONE;
                    end else if (echo_cnt == TIMEOUT_CYC - 1) begin
                        timeout <= 1'b1;
                        state   <= S_DONE;
                    end else begin
                        echo_cnt <= echo_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
