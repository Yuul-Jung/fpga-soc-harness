// ir_nec_decode.v — NEC IR 프로토콜 디코더 (FSM)
// 클럭: 100 MHz (10 ns/클럭)
// 입력: ir_in (디모듈레이션된 IR 수신 모듈 출력, 액티브 로우)
//       내부에서 액티브 하이(burst=1)로 반전하여 처리
// NEC 타이밍 (100 MHz 기준, ±20% 허용):
//   리더 버스트   : 9.0 ms  = 900,000 클럭
//   리더 스페이스 : 4.5 ms  = 450,000 클럭
//   반복 스페이스 : 2.25 ms = 225,000 클럭
//   데이터 버스트 : 562.5 µs= 56,250  클럭
//   비트0 스페이스 : 562.5 µs= 56,250 클럭
//   비트1 스페이스 : 1.6875ms= 168,750 클럭 (3×562.5 µs)
//   허용 오차 ±20%
// 출력: decoded_valid, decoded_repeat, decoded_err, decoded_addr[7:0], decoded_cmd[7:0]

`timescale 1ns/1ps

module ir_nec_decode (
    input  wire        clk,
    input  wire        rst,          // 동기 리셋, 액티브 하이
    input  wire        ir_in,        // IR 수신 모듈 출력 (액티브 로우)

    output reg         decoded_valid,  // 1클럭 펄스: 완전한 프레임 수신
    output reg         decoded_repeat, // 1클럭 펄스: 반복 코드 수신
    output reg         decoded_err,    // 1클럭 펄스: 반전 검사 실패
    output reg  [7:0]  decoded_addr,
    output reg  [7:0]  decoded_cmd
);

    // ---------------------------------------------------------------
    // 타이밍 상수 (100 MHz)
    // ---------------------------------------------------------------
    localparam CLK_HZ       = 100_000_000;
    // 버스트 길이 범위: 리더 버스트 허용
    localparam LD_BURST_MIN = 720_000;   // 7.2 ms
    localparam LD_BURST_MAX = 1_080_000; // 10.8 ms
    // 리더 스페이스 범위
    localparam LD_SPC_MIN   = 360_000;   // 3.6 ms
    localparam LD_SPC_MAX   = 540_000;   // 5.4 ms
    // 반복 스페이스 범위
    localparam RP_SPC_MIN   = 180_000;   // 1.8 ms
    localparam RP_SPC_MAX   = 270_000;   // 2.7 ms
    // 데이터 버스트 범위
    localparam DB_BURST_MIN = 45_000;    // 0.45 ms
    localparam DB_BURST_MAX = 67_500;    // 0.675 ms
    // 비트0 스페이스 범위
    localparam B0_SPC_MIN   = 45_000;    // 0.45 ms
    localparam B0_SPC_MAX   = 90_000;    // 0.9 ms  (경계 포함)
    // 비트1 스페이스 범위
    localparam B1_SPC_MIN   = 135_000;   // 1.35 ms
    localparam B1_SPC_MAX   = 202_500;   // 2.025 ms
    // 종료 버스트: 최소만 확인
    localparam STOP_BURST_MIN = 45_000;

    // 카운터 최대값 (최대 필요: ~11ms = 1,100,000)
    localparam CNT_W  = 21;  // 2^21 = 2,097,152 > 1,100,000

    // ---------------------------------------------------------------
    // 상태 머신
    // ---------------------------------------------------------------
    localparam S_IDLE        = 4'd0;
    localparam S_LD_BURST    = 4'd1;  // 리더 버스트 측정 중
    localparam S_LD_SPACE    = 4'd2;  // 리더 스페이스 측정 중
    localparam S_DATA_BURST  = 4'd3;  // 데이터 비트 버스트 측정 중
    localparam S_DATA_SPACE  = 4'd4;  // 데이터 비트 스페이스 측정 중
    localparam S_STOP_BURST  = 4'd5;  // 종료 버스트 측정 중
    localparam S_REPEAT_STOP = 4'd6;  // 반복 코드 종료 버스트

    // IR 신호: 액티브 로우 반전
    wire burst;
    assign burst = ~ir_in;

    // 에지 검출
    reg  ir_prev;
    wire rise;
    assign rise = ( burst && !ir_prev);  // 버스트 시작

    // 상태 레지스터
    reg [3:0]           state;
    reg [CNT_W-1:0]     cnt;        // 현재 구간 클럭 수
    reg [31:0]          shift;      // 32비트 시프트 레지스터 (LSB first)
    reg [4:0]           bit_cnt;    // 수신 비트 수

    // ---------------------------------------------------------------
    // 메인 FSM
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state        <= S_IDLE;
            cnt          <= 0;
            shift        <= 0;
            bit_cnt      <= 0;
            ir_prev      <= 0;
            decoded_valid  <= 0;
            decoded_repeat <= 0;
            decoded_err    <= 0;
            decoded_addr   <= 0;
            decoded_cmd    <= 0;
        end else begin
            ir_prev        <= burst;
            decoded_valid  <= 0;
            decoded_repeat <= 0;
            decoded_err    <= 0;

            case (state)

                // --- IDLE: 버스트 시작 대기 ---
                S_IDLE: begin
                    cnt <= 0;
                    if (rise) begin
                        state <= S_LD_BURST;
                        cnt   <= 1;
                    end
                end

                // --- 리더 버스트 측정 ---
                S_LD_BURST: begin
                    if (burst) begin
                        cnt <= cnt + 1;
                        // 최대 초과 → 오류 복귀
                        if (cnt >= LD_BURST_MAX)
                            state <= S_IDLE;
                    end else begin
                        // 버스트 종료(스페이스 시작)
                        if (cnt >= LD_BURST_MIN) begin
                            state <= S_LD_SPACE;
                            cnt   <= 1;
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                end

                // --- 리더 스페이스 측정 ---
                S_LD_SPACE: begin
                    if (!burst) begin
                        cnt <= cnt + 1;
                        if (cnt >= LD_SPC_MAX + RP_SPC_MAX)
                            state <= S_IDLE; // 너무 긴 스페이스 → 복귀
                    end else begin
                        // 버스트 시작(스페이스 종료)
                        if (cnt >= LD_SPC_MIN && cnt <= LD_SPC_MAX) begin
                            // 정상 리더 스페이스 → 데이터 수신 시작
                            state   <= S_DATA_BURST;
                            bit_cnt <= 0;
                            shift   <= 0;
                            cnt     <= 1;
                        end else if (cnt >= RP_SPC_MIN && cnt <= RP_SPC_MAX) begin
                            // 반복 코드 스페이스
                            state <= S_REPEAT_STOP;
                            cnt   <= 1;
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                end

                // --- 데이터 비트 버스트 측정 ---
                S_DATA_BURST: begin
                    if (burst) begin
                        cnt <= cnt + 1;
                        if (cnt >= DB_BURST_MAX * 2)
                            state <= S_IDLE;
                    end else begin
                        // 버스트 종료
                        if (cnt >= DB_BURST_MIN && cnt <= DB_BURST_MAX) begin
                            state <= S_DATA_SPACE;
                            cnt   <= 1;
                        end else begin
                            // 비트 수 32개 채웠을 때 종료 버스트가 올 수 있음
                            if (bit_cnt == 32 && cnt >= STOP_BURST_MIN) begin
                                state <= S_STOP_BURST;
                                cnt   <= 1;
                            end else begin
                                state <= S_IDLE;
                            end
                        end
                    end
                end

                // --- 데이터 비트 스페이스 측정 ---
                S_DATA_SPACE: begin
                    if (!burst) begin
                        cnt <= cnt + 1;
                        if (cnt >= B1_SPC_MAX * 2)
                            state <= S_IDLE;
                    end else begin
                        // 버스트 시작 → 비트 판정 및 상태 전이
                        if (cnt >= B1_SPC_MIN && cnt <= B1_SPC_MAX) begin
                            // 비트 1
                            shift   <= {1'b1, shift[31:1]};
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt == 31) begin
                                state <= S_STOP_BURST;
                                cnt   <= 1;
                            end else begin
                                state <= S_DATA_BURST;
                                cnt   <= 1;
                            end
                        end else if (cnt >= B0_SPC_MIN && cnt <= B0_SPC_MAX) begin
                            // 비트 0
                            shift   <= {1'b0, shift[31:1]};
                            bit_cnt <= bit_cnt + 1;
                            if (bit_cnt == 31) begin
                                state <= S_STOP_BURST;
                                cnt   <= 1;
                            end else begin
                                state <= S_DATA_BURST;
                                cnt   <= 1;
                            end
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                end

                // --- 종료 버스트 ---
                S_STOP_BURST: begin
                    if (burst) begin
                        cnt <= cnt + 1;
                        if (cnt >= DB_BURST_MAX * 2)
                            state <= S_IDLE;
                    end else begin
                        // 버스트 종료 → 프레임 완성
                        if (cnt >= STOP_BURST_MIN) begin
                            // 반전 검사: shift[7:0]=ADDR, shift[15:8]=~ADDR,
                            //            shift[23:16]=CMD, shift[31:24]=~CMD
                            if ((shift[7:0] == ~shift[15:8]) && (shift[23:16] == ~shift[31:24])) begin
                                decoded_valid <= 1;
                                decoded_addr  <= shift[7:0];
                                decoded_cmd   <= shift[23:16];
                            end else begin
                                decoded_err   <= 1;
                            end
                        end
                        state <= S_IDLE;
                    end
                end

                // --- 반복 코드 종료 버스트 ---
                S_REPEAT_STOP: begin
                    if (burst) begin
                        cnt <= cnt + 1;
                        if (cnt >= DB_BURST_MAX * 2)
                            state <= S_IDLE;
                    end else begin
                        if (cnt >= STOP_BURST_MIN) begin
                            decoded_repeat <= 1;
                            decoded_addr   <= decoded_addr; // 직전 값 유지
                            decoded_cmd    <= decoded_cmd;
                        end
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
