// debounce_fsm.v — 4상태 FSM 기반 버튼 디바운스
// 원본: capstones/debounce-cmp-tb/rtl/debounce_fsm.v
// IDLE → PRESS_WAIT → PRESSED → RELEASE_WAIT → IDLE 전이.
// WAIT 상태에서 WAIT_COUNT 사이클 동안 입력이 유지되어야 전이한다.
// Verilog-2001, iverilog/verilator/yosys 호환.

`default_nettype none

module debounce_fsm #(
    parameter WAIT_COUNT = 20   // 대기 판정 사이클 수
) (
    input  wire clk,
    input  wire rst,       // 동기 리셋, 활성 High
    input  wire btn_in,    // 미처리 버튼 입력
    output reg  clean_out  // 디바운스 처리된 출력
);

    // 상태 인코딩
    localparam IDLE         = 2'd0;
    localparam PRESS_WAIT   = 2'd1;
    localparam PRESSED      = 2'd2;
    localparam RELEASE_WAIT = 2'd3;

    reg [1:0] state;
    reg [7:0] cnt;
    reg       btn_sync;

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            cnt       <= 8'd0;
            clean_out <= 1'b0;
            btn_sync  <= 1'b0;
        end else begin
            btn_sync <= btn_in;

            case (state)
                IDLE: begin
                    if (btn_sync == 1'b1) begin
                        // 버튼 눌림 감지 → 대기 시작
                        state <= PRESS_WAIT;
                        cnt   <= 8'd0;
                    end
                end

                PRESS_WAIT: begin
                    if (btn_sync == 1'b0) begin
                        // 대기 중 글리치 → 다시 IDLE
                        state <= IDLE;
                        cnt   <= 8'd0;
                    end else if (cnt == WAIT_COUNT - 1) begin
                        // 충분히 안정 → 눌린 상태 확정
                        state     <= PRESSED;
                        clean_out <= 1'b1;
                        cnt       <= 8'd0;
                    end else begin
                        cnt <= cnt + 8'd1;
                    end
                end

                PRESSED: begin
                    if (btn_sync == 1'b0) begin
                        // 버튼 놓임 감지 → 해제 대기
                        state <= RELEASE_WAIT;
                        cnt   <= 8'd0;
                    end
                end

                RELEASE_WAIT: begin
                    if (btn_sync == 1'b1) begin
                        // 대기 중 글리치 → 다시 PRESSED
                        state <= PRESSED;
                        cnt   <= 8'd0;
                    end else if (cnt == WAIT_COUNT - 1) begin
                        // 충분히 안정 → 해제 상태 확정
                        state     <= IDLE;
                        clean_out <= 1'b0;
                        cnt       <= 8'd0;
                    end else begin
                        cnt <= cnt + 8'd1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire
