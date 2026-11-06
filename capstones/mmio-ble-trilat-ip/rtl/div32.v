`timescale 1ns/1ps
// div32.v — 32비트 무부호 복원 나눗셈기
// 32 클럭 사이클. start 펄스(1클럭)로 시작, done 펄스(1클럭)로 완료.
// quotient = dividend / divisor, remainder = dividend % divisor
// divisor = 0 이면 quotient = 0xFFFFFFFF, remainder = dividend 반환.
//
// 알고리즘: acc = {partial_rem[31:0], quotient_so_far[31:0]}
//   매 사이클: acc 전체를 1비트 왼쪽 시프트 (암묵적으로 수행)
//   시프트된 PR = {acc[62:32], acc[31]}  (32비트)
//   trial = shifted_PR - divisor
//   성공(trial >= 0): new_PR = trial[31:0], acc = {trial[31:0], acc[31:0]<<1 | 1}
//   실패(trial <  0): acc = {acc[62:0], 1'b0}  (전체 시프트만)
`default_nettype none
module div32 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    input  wire        start,
    output reg  [31:0] quotient,
    output reg  [31:0] remainder,
    output reg         done,
    output reg         busy
);
    reg [5:0]  cnt;
    reg [63:0] acc;
    reg [31:0] dvsr;

    // 조합 논리: 시프트된 partial remainder 후보
    // shifted_PR = {acc[62:32], acc[31]} (32비트)
    wire [32:0] trial = {1'b0, acc[62:32], acc[31]} - {1'b0, dvsr};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 6'd0;
            acc       <= 64'd0;
            dvsr      <= 32'd0;
            quotient  <= 32'd0;
            remainder <= 32'd0;
            done      <= 1'b0;
            busy      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!busy && start) begin
                if (divisor == 32'd0) begin
                    // 0으로 나누기: 즉시 반환
                    quotient  <= 32'hFFFFFFFF;
                    remainder <= dividend;
                    done      <= 1'b1;
                end else begin
                    // acc 초기화: partial_remainder=0, dividend in lower 32
                    acc  <= {32'd0, dividend};
                    dvsr <= divisor;
                    cnt  <= 6'd0;
                    busy <= 1'b1;
                end
            end else if (busy) begin
                // 복원 나눗셈 한 단계 (shifted_PR = {acc[62:32], acc[31]})
                if (!trial[32]) begin
                    // shifted_PR >= divisor → 성공, Q-bit = 1
                    acc <= {trial[31:0], acc[31:0] << 1 | 1'b1};
                end else begin
                    // shifted_PR < divisor → 실패, acc 전체를 1비트 시프트
                    acc <= {acc[62:0], 1'b0};
                end
                cnt <= cnt + 6'd1;

                if (cnt == 6'd31) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    // 마지막 단계 결과를 직접 등록
                    if (!trial[32]) begin
                        quotient  <= acc[31:0] << 1 | 1'b1;
                        remainder <= trial[31:0];
                    end else begin
                        quotient  <= acc[31:0] << 1;
                        remainder <= {acc[62:32], acc[31]};
                    end
                end
            end
        end
    end
endmodule
`default_nettype wire
