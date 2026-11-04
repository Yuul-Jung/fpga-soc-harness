// wdt_core.v — 워치독 타이머 코어 (기본 카운터 + 타임아웃 FSM)
// I-070 AXI4-Lite 워치독 IP (mmio-wdt-tier1, T1)
// Verilog-2001. iverilog/verilator/yosys 호환.
//
// 포트:
//   clk        — 시스템 클럭
//   rst        — 동기 active-high 리셋
//   enable     — 1=카운터 활성 (0이면 IDLE, 카운터 정지)
//   kick       — 1사이클 펄스: 카운터를 load_val로 재적재 (timeout_lat도 클리어)
//   srst       — 1사이클 펄스: 소프트 리셋 (타임아웃 클리어, 카운터 재적재)
//   load_val   — 카운트다운 초기값 (0이면 즉시 타임아웃)
//   count_out  — 현재 카운터 값
//   timeout    — 1사이클 펄스 (카운터가 0에 도달할 때 1사이클만 high)
//   timeout_lat — 래치된 타임아웃 플래그 (kick/srst로 클리어)
//   running    — 1=카운터 감소 중 (enable=1 이고 타임아웃 미발생)

`default_nettype none

module wdt_core #(
    parameter CNT_W = 32
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,
    input  wire             kick,
    input  wire             srst,
    input  wire [CNT_W-1:0] load_val,
    output reg  [CNT_W-1:0] count_out,
    output reg              timeout,
    output reg              timeout_lat,
    output reg              running
);

    // ── FSM 상태 ─────────────────────────────────────────
    localparam S_IDLE    = 2'd0;  // enable=0
    localparam S_RUNNING = 2'd1;  // 카운터 감소 중
    localparam S_TIMEOUT = 2'd2;  // 카운터 0 도달, 리셋 대기

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;
            count_out   <= {CNT_W{1'b0}};
            timeout     <= 1'b0;
            timeout_lat <= 1'b0;
            running     <= 1'b0;
        end else begin
            // 1사이클 펄스 자동 클리어
            timeout <= 1'b0;

            case (state)
                S_IDLE: begin
                    running <= 1'b0;
                    if (srst) begin
                        count_out   <= load_val;
                        timeout_lat <= 1'b0;
                    end
                    if (enable && !timeout_lat) begin
                        // enable이 올라오면 카운터를 적재하고 감소 시작
                        state     <= S_RUNNING;
                        count_out <= load_val;
                        running   <= 1'b1;
                    end
                end

                S_RUNNING: begin
                    running <= 1'b1;
                    if (srst || kick) begin
                        // kick 또는 소프트 리셋: 카운터 재적재, 타임아웃 클리어
                        count_out   <= load_val;
                        timeout_lat <= 1'b0;
                        if (!enable) begin
                            state   <= S_IDLE;
                            running <= 1'b0;
                        end
                    end else if (!enable) begin
                        // enable 내려가면 카운터 정지
                        state   <= S_IDLE;
                        running <= 1'b0;
                    end else if (count_out == {CNT_W{1'b0}}) begin
                        // 카운터가 이미 0: 타임아웃 발생
                        state       <= S_TIMEOUT;
                        timeout     <= 1'b1;
                        timeout_lat <= 1'b1;
                        running     <= 1'b0;
                    end else begin
                        // 정상 감소
                        count_out <= count_out - 1'b1;
                    end
                end

                S_TIMEOUT: begin
                    running <= 1'b0;
                    if (srst || kick) begin
                        // kick/소프트 리셋으로 타임아웃 해제
                        count_out   <= load_val;
                        timeout_lat <= 1'b0;
                        if (enable) begin
                            state   <= S_RUNNING;
                            running <= 1'b1;
                        end else begin
                            state   <= S_IDLE;
                        end
                    end else if (!enable) begin
                        // enable이 내려오면 IDLE (timeout_lat은 유지)
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

`default_nettype wire
