// dht11_ctrl.v — DHT11 온습도 센서 단선 FSM
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 100 MHz 기준: 18 ms start = 1_800_000 cycles
// 비트 판별: 50 μs Low 후 High 구간 < 40 μs → 0, > 40 μs → 1
// (100 MHz: 40 μs = 4000 cycles 임계값)

`timescale 1ns/1ps
module dht11_ctrl #(
    parameter START_CYC    = 1_800_000,   // 18 ms
    parameter RELEASE_CYC  =    50_000,   // 0.5 ms pull-up wait
    parameter BIT_THRESH   =     4_000    // 40 μs threshold
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    // 단선 IO (tri-state: oe=1이면 출력 0, oe=0이면 입력)
    output wire       dht_oe,   // 1: drive low
    input  wire       dht_in,   // 풀업 후 입력
    // 결과
    output reg  [7:0] humidity,
    output reg  [7:0] temperature,
    output reg        busy,
    output reg        done,
    output reg        chk_ok
);

    reg [20:0] cnt;
    reg [5:0]  bit_idx;   // 0..39
    reg [39:0] shift_reg;
    reg [15:0] hi_cnt;
    reg [8:0]  chksum;

    // FSM
    localparam S_IDLE      = 4'd0,
               S_START_LOW = 4'd1,
               S_RELEASE   = 4'd2,
               S_RESP_LOW  = 4'd3,  // DHT11 응답 Low(80 μs)
               S_RESP_HIGH = 4'd4,  // DHT11 응답 High(80 μs)
               S_BIT_LOW   = 4'd5,  // 각 비트 시작 Low(50 μs)
               S_BIT_HIGH  = 4'd6,  // 비트 High 구간 계측
               S_DONE      = 4'd7,
               S_ERROR     = 4'd8;

    reg [3:0] state;
    reg       driving_low;  // oe 레지스터

    assign dht_oe = driving_low;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            driving_low <= 1'b0;
            busy        <= 1'b0;
            done        <= 1'b0;
            chk_ok      <= 1'b0;
            humidity    <= 8'd0;
            temperature <= 8'd0;
            cnt         <= 21'd0;
            bit_idx     <= 6'd0;
            shift_reg   <= 40'd0;
            hi_cnt      <= 16'd0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    driving_low <= 1'b0;
                    busy        <= 1'b0;
                    if (start) begin
                        driving_low <= 1'b1;
                        busy        <= 1'b1;
                        cnt         <= 21'd0;
                        state       <= S_START_LOW;
                    end
                end

                S_START_LOW: begin
                    if (cnt == START_CYC - 1) begin
                        driving_low <= 1'b0;
                        cnt         <= 21'd0;
                        state       <= S_RELEASE;
                    end else
                        cnt <= cnt + 1'b1;
                end

                S_RELEASE: begin
                    if (cnt == RELEASE_CYC - 1) begin
                        cnt   <= 21'd0;
                        state <= S_RESP_LOW;
                    end else
                        cnt <= cnt + 1'b1;
                end

                S_RESP_LOW: begin
                    // DHT11이 Low를 내림: 최대 100 μs 기다림
                    if (!dht_in) begin
                        cnt   <= 21'd0;
                        state <= S_RESP_HIGH;
                    end else if (cnt == 10_000) begin
                        state <= S_ERROR;
                    end else
                        cnt <= cnt + 1'b1;
                end

                S_RESP_HIGH: begin
                    // DHT11이 High: 80 μs 후 떨어짐
                    if (dht_in) begin
                        cnt   <= 21'd0;
                        state <= S_BIT_LOW;
                        bit_idx <= 6'd0;
                    end else
                        cnt <= cnt + 1'b1;
                end

                S_BIT_LOW: begin
                    // 비트 시작 Low(50 μs)
                    if (dht_in) begin
                        hi_cnt <= 16'd0;
                        state  <= S_BIT_HIGH;
                    end else if (cnt == 10_000) begin
                        state <= S_ERROR;
                    end else
                        cnt <= cnt + 1'b1;
                end

                S_BIT_HIGH: begin
                    if (!dht_in) begin
                        // High 구간 종료
                        shift_reg <= {shift_reg[38:0],
                                      (hi_cnt > BIT_THRESH) ? 1'b1 : 1'b0};
                        bit_idx   <= bit_idx + 1'b1;
                        cnt       <= 21'd0;
                        if (bit_idx == 6'd39)
                            state <= S_DONE;
                        else
                            state <= S_BIT_LOW;
                    end else begin
                        hi_cnt <= hi_cnt + 1'b1;
                        if (hi_cnt == 16'hFFFF)
                            state <= S_ERROR;
                    end
                end

                S_DONE: begin
                    // 체크섬: 하위 8비트 합
                    chksum = shift_reg[39:32] + shift_reg[31:24] +
                             shift_reg[23:16] + shift_reg[15:8];
                    chk_ok <= (chksum[7:0] == shift_reg[7:0]);
                    humidity    <= shift_reg[39:32];
                    temperature <= shift_reg[23:16];
                    done        <= 1'b1;
                    busy        <= 1'b0;
                    state       <= S_IDLE;
                end

                S_ERROR: begin
                    chk_ok  <= 1'b0;
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    state   <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
