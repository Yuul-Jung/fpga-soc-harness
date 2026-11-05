`timescale 1ns/1ps
// hcsr04_drv.v — HC-SR04 단일 측정 드라이버
// clk 100 MHz, 동기 리셋(active-low rst_n)
// start 펄스 → TRIG 10 µs → ECHO 계측 → dist_cm 출력 + done 펄스
// 타임아웃: 23 ms (≒ 400 cm 초과)
// dist_cm = 0x3FF (1023) → 타임아웃(범위 초과)
// 거리 환산: 100 MHz, echo_cycles / 5800 = cm (반왕복 340 m/s 기준)
`default_nettype none
module hcsr04_drv (
    input  wire        clk,
    input  wire        rst_n,
    // 제어
    input  wire        start,       // 1-클럭 펄스로 측정 개시
    // 외부 핀
    output reg         trig,        // → HC-SR04 TRIG
    input  wire        echo,        // ← HC-SR04 ECHO (레벨 변환 후)
    // 결과
    output reg  [9:0]  dist_cm,     // 측정 거리 cm (0~399, 1023=범위초과)
    output reg         done         // 1-클럭 완료 펄스
);

    // 타이밍 상수 (100 MHz 기준)
    localparam TRIG_CYCLES  = 1000;       // 10 µs
    localparam TIMEOUT_CYC  = 2_300_000;  // 23 ms
    localparam CM_DIVISOR   = 5800;       // cycles/cm

    // FSM 상태
    localparam S_IDLE    = 2'd0;
    localparam S_TRIG    = 2'd1;
    localparam S_WAIT    = 2'd2;
    localparam S_MEAS    = 2'd3;

    reg [1:0]  state;
    reg [21:0] cnt;    // 최대 2300000 < 2^22

    // 에코 동기화 (2단 FF)
    reg echo_s1, echo_s2;
    always @(posedge clk) begin
        echo_s1 <= echo;
        echo_s2 <= echo_s1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= S_IDLE;
            trig    <= 1'b0;
            dist_cm <= 10'd0;
            done    <= 1'b0;
            cnt     <= 22'd0;
        end else begin
            done <= 1'b0;  // 기본값
            case (state)
                S_IDLE: begin
                    trig <= 1'b0;
                    if (start) begin
                        cnt   <= 22'd0;
                        trig  <= 1'b1;
                        state <= S_TRIG;
                    end
                end
                S_TRIG: begin
                    if (cnt == TRIG_CYCLES - 1) begin
                        trig  <= 1'b0;
                        cnt   <= 22'd0;
                        state <= S_WAIT;
                    end else begin
                        cnt <= cnt + 22'd1;
                    end
                end
                S_WAIT: begin
                    // ECHO 상승 엣지를 기다린다
                    if (echo_s2) begin
                        cnt   <= 22'd0;
                        state <= S_MEAS;
                    end else if (cnt == TIMEOUT_CYC - 1) begin
                        dist_cm <= 10'h3FF;  // 타임아웃
                        done    <= 1'b1;
                        state   <= S_IDLE;
                    end else begin
                        cnt <= cnt + 22'd1;
                    end
                end
                S_MEAS: begin
                    // ECHO HIGH 동안 카운트
                    if (!echo_s2) begin
                        // 하강 엣지: 거리 계산
                        dist_cm <= (cnt >= TIMEOUT_CYC) ? 10'h3FF
                                   : cnt / CM_DIVISOR;
                        done    <= 1'b1;
                        state   <= S_IDLE;
                    end else if (cnt == TIMEOUT_CYC - 1) begin
                        dist_cm <= 10'h3FF;
                        done    <= 1'b1;
                        state   <= S_IDLE;
                    end else begin
                        cnt <= cnt + 22'd1;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
