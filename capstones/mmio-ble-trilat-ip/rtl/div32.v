`timescale 1ns/1ps
// div32.v — 32비트 무부호 복원 나눗셈기
// 32 클럭 사이클. start 펄스(1클럭)로 시작, done 펄스(1클럭)로 완료.
// quotient = dividend / divisor, remainder = dividend % divisor
// divisor = 0 이면 quotient = 0xFFFFFFFF, remainder = dividend 반환.
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
    // acc = {partial_remainder[31:0], shifted_quotient[31:0]}
    // 반복마다 acc 전체를 왼쪽으로 1비트 시프트하고 MSB 위치에서 빼기를 시도한다.
    reg [63:0] acc;
    reg [31:0] dvsr;

    // 조합 논리: 현재 단계에서 partial remainder 후보
    wire [32:0] trial = {1'b0, acc[62:32]} - {1'b0, dvsr};

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
                    // acc 초기화: partial_remainder=0, shifted_dividend in lower 32
                    acc  <= {32'd0, dividend};
                    dvsr <= divisor;
                    cnt  <= 6'd0;
                    busy <= 1'b1;
                end
            end else if (busy) begin
                // 복원 나눗셈 한 단계:
                // partial_rem = acc[62:32] (1비트 왼쪽 시프트된 상위 비트)
                // 빼기 성공이면 Q-bit=1, 아니면 Q-bit=0
                if (!trial[32]) begin
                    // partial_rem >= divisor → 성공, Q-bit = 1
                    acc <= {trial[31:0], acc[31:0] << 1 | 1'b1};
                end else begin
                    // partial_rem < divisor → 실패, Q-bit = 0
                    acc <= {acc[62:32], acc[31:0] << 1};
                end
                cnt <= cnt + 6'd1;

                if (cnt == 6'd31) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    // 마지막 단계 결과는 다음 클럭에 반영되므로
                    // combinatorial 결과를 직접 등록
                    if (!trial[32]) begin
                        quotient  <= acc[31:0] << 1 | 1'b1;
                        remainder <= trial[31:0];
                    end else begin
                        quotient  <= acc[31:0] << 1;
                        remainder <= acc[62:32];
                    end
                end
            end
        end
    end
endmodule
`default_nettype wire
