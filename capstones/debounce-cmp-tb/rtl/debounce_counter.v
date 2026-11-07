// debounce_counter.v — 카운터 기반 버튼 디바운스
// 원본: capstones/debounce-cmp-tb/rtl/debounce_counter.v
// STABLE_COUNT 클럭 사이클 동안 btn_in이 일정하면 clean_out을 변경한다.
// Verilog-2001, iverilog/verilator/yosys 호환.

`default_nettype none

module debounce_counter #(
    parameter STABLE_COUNT = 20   // 안정 판정 사이클 수
) (
    input  wire clk,
    input  wire rst,       // 동기 리셋, 활성 High
    input  wire btn_in,    // 미처리 버튼 입력 (글리치 포함 가능)
    output reg  clean_out  // 디바운스 처리된 출력
);

    // 카운터 비트 폭: STABLE_COUNT를 커버할 수 있도록 설정
    // 최대 STABLE_COUNT=255 → 8비트면 충분
    reg [7:0] cnt;
    reg       btn_sync;  // 입력 동기화

    always @(posedge clk) begin
        if (rst) begin
            cnt       <= 8'd0;
            btn_sync  <= 1'b0;
            clean_out <= 1'b0;
        end else begin
            btn_sync <= btn_in;

            if (btn_sync == clean_out) begin
                // 입력이 현재 출력과 같으면 카운터 리셋
                cnt <= 8'd0;
            end else begin
                // 입력이 출력과 다를 때 카운터 증가
                if (cnt == STABLE_COUNT - 1) begin
                    // 충분히 안정됨 → 출력 변경
                    clean_out <= btn_sync;
                    cnt       <= 8'd0;
                end else begin
                    cnt <= cnt + 8'd1;
                end
            end
        end
    end

endmodule

`default_nettype wire
