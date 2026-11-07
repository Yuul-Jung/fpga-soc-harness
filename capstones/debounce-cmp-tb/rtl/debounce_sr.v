// debounce_sr.v — 시프트레지스터 기반 버튼 디바운스
// 원본: capstones/debounce-cmp-tb/rtl/debounce_sr.v
// SR_WIDTH 사이클 분량의 이동 창(shift register)이 모두 같은 값일 때 출력을 변경한다.
// Verilog-2001, iverilog/verilator/yosys 호환.

`default_nettype none

module debounce_sr #(
    parameter SR_WIDTH = 20   // 시프트레지스터 비트 수 (안정 판정 창 크기)
) (
    input  wire clk,
    input  wire rst,       // 동기 리셋, 활성 High
    input  wire btn_in,    // 미처리 버튼 입력
    output reg  clean_out  // 디바운스 처리된 출력
);

    // SR_WIDTH비트 시프트레지스터
    // Verilog-2001: parameter를 로컬에서 쓸 때 localparam으로 재선언
    localparam W = SR_WIDTH;

    reg [W-1:0] sr;

    // 모두 1이면 버튼 눌림 안정, 모두 0이면 해제 안정
    wire all_ones  = (sr == {W{1'b1}});
    wire all_zeros = (sr == {W{1'b0}});

    always @(posedge clk) begin
        if (rst) begin
            sr        <= {W{1'b0}};
            clean_out <= 1'b0;
        end else begin
            // 왼쪽으로 시프트하고 최하위에 새 입력 삽입
            sr <= {sr[W-2:0], btn_in};

            if (all_ones) begin
                clean_out <= 1'b1;
            end else if (all_zeros) begin
                clean_out <= 1'b0;
            end
            // 중간 상태(글리치)에서는 clean_out 유지
        end
    end

endmodule

`default_nettype wire
