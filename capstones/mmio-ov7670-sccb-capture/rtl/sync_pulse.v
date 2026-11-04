// sync_pulse.v — 클럭 도메인 교차: 단일 펄스 2-FF 동기화기
// src 도메인의 1클럭 펄스를 dst 도메인으로 안전하게 전달한다.
// 방법: src에서 토글 → dst에서 2-FF → 에지 검출.
// 주의: src 펄스 간격 > 2 dst 클럭 주기여야 한다.
// Verilog-2001, 외부 IP 없음.

`default_nettype none
module sync_pulse (
    input  wire src_clk,
    input  wire src_rst,
    input  wire src_pulse,   // src 도메인 1클럭 펄스 입력
    input  wire dst_clk,
    input  wire dst_rst,
    output wire dst_pulse    // dst 도메인 1클럭 펄스 출력
);
    reg       toggle;        // src 도메인 토글 레지스터
    reg [1:0] sync_ff;       // dst 도메인 2-FF
    reg       prev;          // 에지 검출용

    always @(posedge src_clk) begin
        if (src_rst) toggle <= 1'b0;
        else if (src_pulse) toggle <= ~toggle;
    end

    always @(posedge dst_clk) begin
        if (dst_rst) begin
            sync_ff <= 2'b00;
            prev    <= 1'b0;
        end else begin
            sync_ff <= {sync_ff[0], toggle};
            prev    <= sync_ff[1];
        end
    end

    assign dst_pulse = sync_ff[1] ^ prev;
endmodule
`default_nettype wire
