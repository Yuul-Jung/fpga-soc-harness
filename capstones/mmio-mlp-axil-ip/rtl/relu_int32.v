// relu_int32.v — INT32 ReLU 활성화 함수 (조합 논리)
// capstone: mmio-mlp-axil-ip
// 2026-11-08
`default_nettype none

module relu_int32 #(
    parameter WIDTH = 32
)(
    input  wire signed [WIDTH-1:0] in,
    output wire signed [WIDTH-1:0] out
);
    assign out = (in[WIDTH-1]) ? {WIDTH{1'b0}} : in;
endmodule
`default_nettype wire
