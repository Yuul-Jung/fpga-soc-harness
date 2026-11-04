// lane_decode.v — 그리드 스냅샷 → 레인·점프 디코더
// 열 합산 argmax로 레인(0=없음,1=좌,2=중앙,3=우)을,
// 행 최상위(TOP행) 밀도로 점프 신호를 결정한다.
//
// 입력: grid_snap[9*16-1:0] (cell i = bits[i*16+15:i*16])
//   셀 배치:
//     [0]=TL [1]=TC [2]=TR  (row=0, TOP)
//     [3]=ML [4]=MC [5]=MR  (row=1)
//     [6]=BL [7]=BC [8]=BR  (row=2)
//
// 열 합산: col_sum[j] = sum(grid_snap[row*3+j]) for row=0,1,2
// JUMP: (TL+TC+TR) > jump_thr (내부 고정=0, 최소 1이면 점프)
// 조합 논리만, Verilog-2001.

`default_nettype none
module lane_decode (
    input  wire [9*16-1:0] grid_snap,  // 그리드 스냅샷 패킹
    input  wire             snap_valid, // 1 클럭 펄스, 연산 트리거
    output reg  [1:0]       lane,       // 0=없음,1=좌,2=중앙,3=우
    output reg              jump        // 1=점프(TOP행 녹색 존재)
);
    // 셀 추출
    wire [15:0] c0 = grid_snap[0*16 +: 16]; // TL
    wire [15:0] c1 = grid_snap[1*16 +: 16]; // TC
    wire [15:0] c2 = grid_snap[2*16 +: 16]; // TR
    wire [15:0] c3 = grid_snap[3*16 +: 16]; // ML
    wire [15:0] c4 = grid_snap[4*16 +: 16]; // MC
    wire [15:0] c5 = grid_snap[5*16 +: 16]; // MR
    wire [15:0] c6 = grid_snap[6*16 +: 16]; // BL
    wire [15:0] c7 = grid_snap[7*16 +: 16]; // BC
    wire [15:0] c8 = grid_snap[8*16 +: 16]; // BR

    // 열 합산 (오버플로 방지: 17비트)
    wire [17:0] col_L = {2'b0,c0} + {2'b0,c3} + {2'b0,c6};
    wire [17:0] col_C = {2'b0,c1} + {2'b0,c4} + {2'b0,c7};
    wire [17:0] col_R = {2'b0,c2} + {2'b0,c5} + {2'b0,c8};

    // TOP행 합 (점프 판단)
    wire [17:0] top_sum = {2'b0,c0} + {2'b0,c1} + {2'b0,c2};

    // argmax (동점이면 L > C > R 우선)
    wire L_wins = (col_L >= col_C) && (col_L >= col_R);
    wire C_wins = (col_C >  col_L) && (col_C >= col_R);
    // R_wins = !L_wins && !C_wins

    wire any_green = (col_L != 0) || (col_C != 0) || (col_R != 0);

    always @(*) begin
        // 기본값
        lane = 2'd0;
        jump = 1'b0;
        if (snap_valid) begin
            if (any_green) begin
                if      (L_wins) lane = 2'd1;
                else if (C_wins) lane = 2'd2;
                else             lane = 2'd3;
            end
            jump = (top_sum > 18'd0) ? 1'b1 : 1'b0;
        end
    end
endmodule
`default_nettype wire
