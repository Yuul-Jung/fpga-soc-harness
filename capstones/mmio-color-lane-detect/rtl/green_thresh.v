// green_thresh.v — RGB565 녹색 화소 판별기
// RGB565에서 G채널이 R, B보다 크고 임계값 초과이면 is_green=1 출력.
// 조합 논리만 사용(레지스터 없음). Verilog-2001.
//
// RGB565 비트 배치:
//   pixel[15:11] = R[4:0]
//   pixel[10:5]  = G[5:0]
//   pixel[4:0]   = B[4:0]
//
// 비교를 위해 R, B를 6비트로 스케일:
//   r6 = {R[4:0], 1'b0}  — 최하위 비트 패딩
//   g6 = G[5:0]
//   b6 = {B[4:0], 1'b0}

`default_nettype none
module green_thresh (
    input  wire [15:0] pixel,     // RGB565 픽셀
    input  wire [5:0]  thresh,    // 녹색 임계값 (6비트, 기본=20)
    output wire        is_green   // 1 = 녹색 화소
);
    wire [5:0] r6 = {pixel[15:11], 1'b0};
    wire [5:0] g6 =  pixel[10:5];
    wire [5:0] b6 = {pixel[4:0],   1'b0};

    assign is_green = (g6 > thresh) && (g6 > r6) && (g6 > b6);
endmodule
`default_nettype wire
