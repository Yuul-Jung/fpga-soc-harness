// argmax_10.v — 10-클래스 INT32 argmax (조합 논리)
// capstone: mmio-mlp-axil-ip
// 2026-11-08
`default_nettype none

module argmax_10 #(
    parameter N_CLASS = 10,
    parameter ACC_W   = 32
)(
    input  wire [N_CLASS*ACC_W-1:0] scores,   // {score[9], score[8], ..., score[0]}
    output wire [3:0]               max_idx,
    output wire signed [ACC_W-1:0]  max_val
);
    wire signed [ACC_W-1:0] s [0:N_CLASS-1];
    genvar i;
    generate
        for (i = 0; i < N_CLASS; i = i + 1) begin : unpack
            assign s[i] = scores[i*ACC_W +: ACC_W];
        end
    endgenerate

    // 순차 비교 (조합 논리)
    wire signed [ACC_W-1:0] cmax [0:N_CLASS-1];
    wire [3:0]               cidx [0:N_CLASS-1];

    assign cmax[0] = s[0];
    assign cidx[0] = 4'd0;

    generate
        for (i = 1; i < N_CLASS; i = i + 1) begin : compare
            assign cmax[i] = (s[i] > cmax[i-1]) ? s[i]        : cmax[i-1];
            assign cidx[i] = (s[i] > cmax[i-1]) ? i[3:0]      : cidx[i-1];
        end
    endgenerate

    assign max_idx = cidx[N_CLASS-1];
    assign max_val = cmax[N_CLASS-1];
endmodule
`default_nettype wire
