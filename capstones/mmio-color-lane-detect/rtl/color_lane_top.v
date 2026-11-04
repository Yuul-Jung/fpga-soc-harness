// color_lane_top.v — SoC 코어: MMIO 레지스터 + CDC + 서브모듈
// mmio-lite 버스 (AXI4-Lite 비호환, 시뮬 전용)
//
// BASE_ADDR 파라미터로 주소 베이스 설정.
// 시뮬 기본값: 0x1005_0000
// 프로젝트 통합 시: 0x4018_0000 (제안 슬롯 [18])
//
// 레지스터 맵 (BASE_ADDR 기준 오프셋):
//   0x00  CTRL      WO   bit0=ENABLE, bit1=INT_EN, bit15=RESET
//   0x04  STATUS    RC   bit0=FRAME_DONE, bit2:1=LANE[1:0], bit3=JUMP
//   0x08  THRESH    RW   bit5:0=green_thresh (기본=20)
//   0x0C  COL_CFG   RW   bit9:0=col_thr1, bit25:16=col_thr2 (기본=3,6)
//   0x10  ROW_CFG   RW   bit8:0=row_thr1, bit24:16=row_thr2 (기본=3,6)
//   0x14  FRAME_CNT RO   bit7:0=프레임 카운터
//   0xFC  ID_VER    RO   0x0007_0100
//
// Verilog-2001, 외부 IP 없음.

`default_nettype none
module color_lane_top #(
    parameter BASE_ADDR = 32'h1005_0000
) (
    input  wire        clk,
    input  wire        rst,
    // mmio-lite
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        wen,
    input  wire        ren,
    output reg  [31:0] rdata,
    // 인터럽트
    output wire        irq,
    // OV7670 (PCLK 도메인 — ov7670_capture_stub 경유)
    input  wire        pclk,
    input  wire        prst,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  cam_d,
    // 상태 표시
    output wire [1:0]  o_lane,
    output wire        o_jump
);
    // ---- MMIO 레지스터 ----
    reg        enable_r;
    reg        int_en_r;
    reg [5:0]  thresh_r;
    reg [9:0]  col_thr1_r;
    reg [9:0]  col_thr2_r;
    reg [8:0]  row_thr1_r;
    reg [8:0]  row_thr2_r;
    // 상태 레지스터 (SYS 도메인)
    reg        status_fd;    // FRAME_DONE
    reg [1:0]  status_lane;
    reg        status_jump;
    reg [7:0]  frame_cnt;

    // ---- PCLK 도메인 → SYS 도메인 CDC (2-FF sync) ----
    // pixel_valid, pixel_data, frame_start, frame_done, line_done
    wire [15:0] pclk_pixel_data;
    wire        pclk_pixel_valid;
    wire        pclk_frame_start;
    wire        pclk_frame_done;
    wire        pclk_line_done;

    // CDC: 2-FF 동기화 (펄스 신호 — 단일 클럭 폭 가정)
    // SYS 클럭이 PCLK보다 훨씬 빠르므로 단일 FF 메타안정성 가능성 있음.
    // 실제 보드 통합 시 handshake 또는 FIFO 고려.
    reg px_valid_s1,  px_valid_s2;
    reg px_fstart_s1, px_fstart_s2;
    reg px_fdone_s1,  px_fdone_s2;
    reg px_ldone_s1,  px_ldone_s2;
    reg [15:0] px_data_s1, px_data_s2;

    always @(posedge clk) begin
        if (rst) begin
            px_valid_s1  <= 1'b0; px_valid_s2  <= 1'b0;
            px_fstart_s1 <= 1'b0; px_fstart_s2 <= 1'b0;
            px_fdone_s1  <= 1'b0; px_fdone_s2  <= 1'b0;
            px_ldone_s1  <= 1'b0; px_ldone_s2  <= 1'b0;
            px_data_s1   <= 16'd0; px_data_s2  <= 16'd0;
        end else begin
            px_valid_s1  <= pclk_pixel_valid;  px_valid_s2  <= px_valid_s1;
            px_fstart_s1 <= pclk_frame_start;  px_fstart_s2 <= px_fstart_s1;
            px_fdone_s1  <= pclk_frame_done;   px_fdone_s2  <= px_fdone_s1;
            px_ldone_s1  <= pclk_line_done;    px_ldone_s2  <= px_ldone_s1;
            px_data_s1   <= pclk_pixel_data;   px_data_s2   <= px_data_s1;
        end
    end

    // ---- 서브모듈 ----
    wire        is_green;
    wire [9*16-1:0] grid_snap;
    wire        snap_valid;
    wire [1:0]  lane_out;
    wire        jump_out;

    ov7670_capture_stub u_cap (
        .pclk        (pclk),
        .prst        (prst),
        .vsync       (vsync),
        .href        (href),
        .d           (cam_d),
        .capture_en  (enable_r),
        .pixel_data  (pclk_pixel_data),
        .pixel_valid (pclk_pixel_valid),
        .frame_start (pclk_frame_start),
        .frame_done  (pclk_frame_done),
        .line_done   (pclk_line_done)
    );

    green_thresh u_gt (
        .pixel    (px_data_s2),
        .thresh   (thresh_r),
        .is_green (is_green)
    );

    grid9_counter #(.PXCNT_W(16), .LNCNT_W(16), .CELLCNT_W(16)) u_g9 (
        .clk         (clk),
        .rst         (rst),
        .pixel_valid (px_valid_s2),
        .is_green    (is_green & px_valid_s2),
        .frame_start (px_fstart_s2),
        .frame_done  (px_fdone_s2),
        .line_done   (px_ldone_s2),
        .col_thr1    ({6'd0, col_thr1_r}),
        .col_thr2    ({6'd0, col_thr2_r}),
        .row_thr1    ({7'd0, row_thr1_r}),
        .row_thr2    ({7'd0, row_thr2_r}),
        .grid_snap   (grid_snap),
        .snap_valid  (snap_valid)
    );

    lane_decode u_ld (
        .grid_snap  (grid_snap),
        .snap_valid (snap_valid),
        .lane       (lane_out),
        .jump       (jump_out)
    );

    // ---- 상태 레지스터 갱신 ----
    always @(posedge clk) begin
        if (rst) begin
            status_fd   <= 1'b0;
            status_lane <= 2'd0;
            status_jump <= 1'b0;
            frame_cnt   <= 8'd0;
        end else begin
            if (snap_valid) begin
                status_fd   <= 1'b1;
                status_lane <= lane_out;
                status_jump <= jump_out;
                frame_cnt   <= frame_cnt + 1'b1;
            end
        end
    end

    // ---- MMIO 레지스터 쓰기 ----
    wire        addr_hit = (addr[31:16] == BASE_ADDR[31:16]);
    wire [7:0]  reg_off  = addr[7:0];

    always @(posedge clk) begin
        if (rst) begin
            enable_r   <= 1'b0;
            int_en_r   <= 1'b0;
            thresh_r   <= 6'd20;
            col_thr1_r <= 10'd3;
            col_thr2_r <= 10'd6;
            row_thr1_r <= 9'd3;
            row_thr2_r <= 9'd6;
        end else if (wen && addr_hit) begin
            case (reg_off)
                8'h00: begin
                    if (wdata[15]) begin  // RESET
                        enable_r <= 1'b0;
                        int_en_r <= 1'b0;
                    end else begin
                        enable_r <= wdata[0];
                        int_en_r <= wdata[1];
                    end
                end
                8'h08: thresh_r   <= wdata[5:0];
                8'h0C: begin col_thr1_r <= wdata[9:0]; col_thr2_r <= wdata[25:16]; end
                8'h10: begin row_thr1_r <= wdata[8:0]; row_thr2_r <= wdata[24:16]; end
                default: ;
            endcase
        end
    end

    // ---- MMIO 레지스터 읽기 ----
    always @(posedge clk) begin
        if (rst) begin
            rdata <= 32'd0;
        end else if (ren && addr_hit) begin
            case (reg_off)
                8'h04: begin
                    rdata     <= {28'd0, status_jump, status_lane, status_fd};
                    // RC: 읽으면 클리어
                    // (status_fd 클리어는 다음 사이클에서 처리 — 단순화)
                end
                8'h08: rdata <= {26'd0, thresh_r};
                8'h0C: rdata <= {6'd0, col_thr2_r, 6'd0, col_thr1_r};
                8'h10: rdata <= {7'd0, row_thr2_r, 7'd0, row_thr1_r};
                8'h14: rdata <= {24'd0, frame_cnt};
                8'hFC: rdata <= 32'h0007_0100;
                default: rdata <= 32'hDEAD_BEEF;
            endcase
        end
    end

    // STATUS RC 클리어 (읽기 다음 사이클)
    reg ren_d;
    always @(posedge clk) begin
        ren_d <= ren && addr_hit && (reg_off == 8'h04);
        if (ren_d) status_fd <= 1'b0;
    end

    assign irq    = status_fd & int_en_r;
    assign o_lane = status_lane;
    assign o_jump = status_jump;
endmodule
`default_nettype wire
