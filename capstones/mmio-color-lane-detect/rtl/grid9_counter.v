// grid9_counter.v — 3×3 그리드 녹색 화소 카운터
// 프레임 단위로 9개 셀의 녹색 화소 수를 집계한 뒤
// frame_done에 스냅샷을 출력한다.
//
// 그리드 인덱스 (row*3 + col, 0-based):
//   [0]=TL [1]=TC [2]=TR
//   [3]=ML [4]=MC [5]=MR
//   [6]=BL [7]=BC [8]=BR
//
// 스냅샷 출력: grid_snap[(i+1)*16-1:i*16] = cell i 카운트 (i=0~8)
// Verilog-2001, 외부 IP 없음.

`default_nettype none
module grid9_counter #(
    parameter PXCNT_W  = 16,
    parameter LNCNT_W  = 16,
    parameter CELLCNT_W = 16
) (
    input  wire                        clk,
    input  wire                        rst,
    // 픽셀 스트림 (SYS 도메인, CDC 완료 후)
    input  wire                        pixel_valid,  // 1 클럭 펄스, 유효 픽셀
    input  wire                        is_green,     // 녹색 여부
    input  wire                        frame_start,  // 1 클럭 펄스, 프레임 시작
    input  wire                        frame_done,   // 1 클럭 펄스, 프레임 완료
    input  wire                        line_done,    // 1 클럭 펄스, 라인 완료(HREF 하강)
    // 임계선 설정
    input  wire [PXCNT_W-1:0]         col_thr1,     // 열 경계 1 (기본=3)
    input  wire [PXCNT_W-1:0]         col_thr2,     // 열 경계 2 (기본=6)
    input  wire [LNCNT_W-1:0]         row_thr1,     // 행 경계 1 (기본=3)
    input  wire [LNCNT_W-1:0]         row_thr2,     // 행 경계 2 (기본=6)
    // 스냅샷 출력 — 9×CELLCNT_W 비트 패킹
    output reg  [9*16-1:0]            grid_snap,    // bits[i*16+15:i*16] = cell i
    output reg                         snap_valid    // 스냅샷 유효 (1 클럭)
);
    // 내부 누산기 — Verilog-2001 메모리 배열 (포트 불가, 내부 사용)
    reg [CELLCNT_W-1:0] grid_acc [0:8];
    reg [PXCNT_W-1:0]   col_cnt;
    reg [LNCNT_W-1:0]   row_cnt;
    reg                  in_frame;

    // 그리드 위치 (조합)
    wire [1:0] grid_col = (col_cnt < col_thr1) ? 2'd0 :
                          (col_cnt < col_thr2) ? 2'd1 : 2'd2;
    wire [1:0] grid_row = (row_cnt < row_thr1) ? 2'd0 :
                          (row_cnt < row_thr2) ? 2'd1 : 2'd2;
    wire [3:0] cell_idx = {2'b00, grid_row} * 4'd3 + {2'b00, grid_col};

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            col_cnt    <= {PXCNT_W{1'b0}};
            row_cnt    <= {LNCNT_W{1'b0}};
            in_frame   <= 1'b0;
            snap_valid <= 1'b0;
            grid_snap  <= {(9*16){1'b0}};
            for (i = 0; i < 9; i = i + 1)
                grid_acc[i] <= {CELLCNT_W{1'b0}};
        end else begin
            snap_valid <= 1'b0;

            if (frame_start) begin
                in_frame <= 1'b1;
                col_cnt  <= {PXCNT_W{1'b0}};
                row_cnt  <= {LNCNT_W{1'b0}};
                for (i = 0; i < 9; i = i + 1)
                    grid_acc[i] <= {CELLCNT_W{1'b0}};
            end

            if (in_frame && line_done) begin
                col_cnt <= {PXCNT_W{1'b0}};
                row_cnt <= row_cnt + 1'b1;
            end else if (in_frame && pixel_valid) begin
                col_cnt <= col_cnt + 1'b1;
            end

            if (in_frame && pixel_valid && is_green) begin
                if (cell_idx <= 4'd8)
                    grid_acc[cell_idx] <= grid_acc[cell_idx] + 1'b1;
            end

            if (frame_done) begin
                in_frame <= 1'b0;
                // 스냅샷 복사 — 패킹
                for (i = 0; i < 9; i = i + 1)
                    grid_snap[i*16 +: 16] <= grid_acc[i];
                snap_valid <= 1'b1;
            end
        end
    end
endmodule
`default_nettype wire
