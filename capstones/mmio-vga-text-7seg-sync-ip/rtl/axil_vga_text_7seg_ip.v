// axil_vga_text_7seg_ip.v
// VGA 텍스트 오버레이 + 7세그 동기화 AXI4-Lite IP
// capstone: mmio-vga-text-7seg-sync-ip  slot free[28]=0x4028_0000
// 언어: Verilog-2001  보드: Basys3 (XC7A35T)
// 클럭: 25MHz (100MHz÷4, 상위에서 분주해 입력)
// 기능:
//   - AXI4-Lite 슬레이브: ID/VER/CTRL/STATUS/CHAR_ADDR/CHAR_DATA/SEG7_DATA/SEG7_CTRL
//   - VGA 640×480@60Hz 텍스트 모드: 80칸 × 30행, 8×16 픽셀 고정 폰트
//   - 문자 버퍼: 2400 항목 × 16비트 [15:12]=bg, [11:8]=fg, [7:0]=ASCII
//   - 폰트 ROM: 128자 × 16행 (상위 128자는 미사용)
//   - 7세그 FSM: VBlank 기간에 dig_sel 순환, 공통양극 세그먼트 디코더
//   - STATUS[0]=vblank 비트, [15:8]=vsync_count
// 검증: S0 (작성됨, CI 통과 전)

`default_nettype none
`timescale 1ns/1ps

module axil_vga_text_7seg_ip (
    // 클럭·리셋
    input  wire        clk,        // 25MHz 픽셀 클럭
    input  wire        rst_n,      // 비동기 액티브-LOW 리셋

    // AXI4-Lite 슬레이브 — 쓰기 주소
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    // AXI4-Lite 슬레이브 — 쓰기 데이터
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    // AXI4-Lite 슬레이브 — 쓰기 응답
    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    // AXI4-Lite 슬레이브 — 읽기 주소
    input  wire [7:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    // AXI4-Lite 슬레이브 — 읽기 데이터
    output reg  [31:0] s_axil_rdata,
    output reg  [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,

    // VGA 출력
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,

    // 7세그 출력 (공통양극)
    output reg  [6:0]  seg,        // a=6, b=5, c=4, d=3, e=2, f=1, g=0 (LOW=켜짐)
    output reg  [3:0]  an          // 자리 선택 (LOW=활성화)
);

// ─────────────────────────────────────────────
// 1. 상수
// ─────────────────────────────────────────────
localparam ID_VAL  = 32'h56545337; // 'VTS7'
localparam VER_VAL = 32'h00000100; // v1.0

// VGA 타이밍 (640×480@60Hz, 25MHz 픽셀 클럭)
localparam H_VIS  = 640, H_FP = 16, H_SYNC = 96, H_BP = 48; // H_TOTAL=800
localparam V_VIS  = 480, V_FP = 10, V_SYNC = 2,  V_BP = 33; // V_TOTAL=525
localparam H_TOTAL = H_VIS + H_FP + H_SYNC + H_BP; // 800
localparam V_TOTAL = V_VIS + V_FP + V_SYNC + V_BP; // 525

// 텍스트 모드: 8픽셀×16행 문자 셀
localparam COLS = 80, ROWS = 30;
localparam CHAR_BUF_DEPTH = COLS * ROWS; // 2400

// ─────────────────────────────────────────────
// 2. 레지스터
// ─────────────────────────────────────────────
reg        reg_disp_en;    // CTRL[0]
reg        reg_seg_en;     // CTRL[1]
reg [11:0] reg_char_addr;  // CHAR_ADDR[11:0]
reg [15:0] reg_seg7_data;  // SEG7_DATA[15:0]
reg [11:0] reg_seg7_ctrl;  // SEG7_CTRL[11:0]

// ─────────────────────────────────────────────
// 3. VGA 타이밍 카운터
// ─────────────────────────────────────────────
reg [9:0] h_count;
reg [9:0] v_count;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        h_count <= 10'd0;
        v_count <= 10'd0;
    end else begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 10'd0;
            if (v_count == V_TOTAL - 1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 10'd1;
        end else begin
            h_count <= h_count + 10'd1;
        end
    end
end

wire active    = (h_count < H_VIS) && (v_count < V_VIS);
wire hsync_int = ~((h_count >= H_VIS + H_FP) && (h_count < H_VIS + H_FP + H_SYNC));
wire vsync_int = ~((v_count >= V_VIS + V_FP) && (v_count < V_VIS + V_FP + V_SYNC));
wire vblank    = (v_count >= V_VIS);
// frame_end: VBlank 첫 줄 첫 픽셀
wire frame_end = (v_count == V_VIS) && (h_count == 10'd0);

assign vga_hsync = hsync_int;
assign vga_vsync = vsync_int;

// vsync 카운터 (STATUS[15:8])
reg [7:0] vsync_count;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) vsync_count <= 8'd0;
    else if (frame_end) vsync_count <= vsync_count + 8'd1;
end

// ─────────────────────────────────────────────
// 4. 문자 버퍼 BRAM (듀얼 포트 추론)
//    Port A: AXI4-Lite 쓰기
//    Port B: 텍스트 렌더러 읽기
// ─────────────────────────────────────────────
reg [15:0] char_buf [0:CHAR_BUF_DEPTH-1]; // 2400×16bit

// 초기값: 공백(0x20), 전경 흰색(7), 배경 검정(0) => 0x0720
integer ci;
initial begin
    for (ci = 0; ci < CHAR_BUF_DEPTH; ci = ci + 1)
        char_buf[ci] = 16'h0720;
end

// Port A: AXI 쓰기 (clk 동기)
// (쓰기는 AXI 채널에서 직접)

// Port B: 렌더러 읽기
// 한 사이클 지연 허용 (파이프라인)
reg [11:0] bram_b_addr;
reg [15:0] bram_b_dout;
always @(posedge clk) begin
    bram_b_dout <= char_buf[bram_b_addr];
end

// ─────────────────────────────────────────────
// 5. 폰트 ROM (128자 × 16행, 각 행 8비트)
//    총 2048 비트 → Xilinx BRAM 추론 가능
// ─────────────────────────────────────────────
reg [7:0] font_rom [0:2047]; // [char*16 + row]
initial begin
    // 모든 항목을 0으로 초기화
    begin : font_init
        integer fi;
        for (fi = 0; fi < 2048; fi = fi + 1)
            font_rom[fi] = 8'h00;
    end
    // 0x20 SPACE: 공백 (모두 0, 이미 위에서 초기화)
    // 0x41 'A'
    font_rom[8'h41*16+0]  = 8'h18; font_rom[8'h41*16+1]  = 8'h3C;
    font_rom[8'h41*16+2]  = 8'h66; font_rom[8'h41*16+3]  = 8'h7E;
    font_rom[8'h41*16+4]  = 8'h66; font_rom[8'h41*16+5]  = 8'h66;
    font_rom[8'h41*16+6]  = 8'h66; font_rom[8'h41*16+7]  = 8'h00;
    font_rom[8'h41*16+8]  = 8'h00; font_rom[8'h41*16+9]  = 8'h00;
    font_rom[8'h41*16+10] = 8'h00; font_rom[8'h41*16+11] = 8'h00;
    font_rom[8'h41*16+12] = 8'h00; font_rom[8'h41*16+13] = 8'h00;
    font_rom[8'h41*16+14] = 8'h00; font_rom[8'h41*16+15] = 8'h00;
    // 0x50 'P'
    font_rom[8'h50*16+0]  = 8'h7C; font_rom[8'h50*16+1]  = 8'h66;
    font_rom[8'h50*16+2]  = 8'h66; font_rom[8'h50*16+3]  = 8'h7C;
    font_rom[8'h50*16+4]  = 8'h60; font_rom[8'h50*16+5]  = 8'h60;
    font_rom[8'h50*16+6]  = 8'h60; font_rom[8'h50*16+7]  = 8'h00;
    // 0x41~0x5A, 0x61~0x7A 패턴 대신 TB에서 공백과 'A','P' 두 자만 테스트
    // 실제 운용에서는 Vitis 등에서 초기화 데이터를 주입한다
    // 0x30 '0'
    font_rom[8'h30*16+0]  = 8'h3C; font_rom[8'h30*16+1]  = 8'h66;
    font_rom[8'h30*16+2]  = 8'h6E; font_rom[8'h30*16+3]  = 8'h76;
    font_rom[8'h30*16+4]  = 8'h66; font_rom[8'h30*16+5]  = 8'h66;
    font_rom[8'h30*16+6]  = 8'h3C; font_rom[8'h30*16+7]  = 8'h00;
    // 0x31 '1'
    font_rom[8'h31*16+0]  = 8'h18; font_rom[8'h31*16+1]  = 8'h38;
    font_rom[8'h31*16+2]  = 8'h18; font_rom[8'h31*16+3]  = 8'h18;
    font_rom[8'h31*16+4]  = 8'h18; font_rom[8'h31*16+5]  = 8'h18;
    font_rom[8'h31*16+6]  = 8'h7E; font_rom[8'h31*16+7]  = 8'h00;
end

reg [10:0] font_addr_r;
reg [7:0]  font_row_r;
always @(posedge clk) begin
    font_row_r <= font_rom[font_addr_r];
end

// ─────────────────────────────────────────────
// 6. VGA 텍스트 렌더러 파이프라인 (3단계)
//    stage 0: 픽셀→문자 좌표 계산, BRAM B 주소 설정
//    stage 1: BRAM 출력 (bram_b_dout), 폰트 ROM 주소 설정
//    stage 2: 폰트 ROM 출력 → RGB 픽셀
// ─────────────────────────────────────────────

// stage 0
wire [6:0] char_col_s0  = h_count[9:3];   // h / 8 (0~79)
wire [4:0] char_row_s0  = v_count[8:4];   // v / 16 (0~29)
wire [2:0] pixel_col_s0 = h_count[2:0];   // h mod 8
wire [3:0] pixel_row_s0 = v_count[3:0];   // v mod 16
wire active_s0          = active;

always @(posedge clk) begin
    // BRAM B addr: char_row * 80 + char_col
    bram_b_addr <= ({5'd0, char_row_s0} * 7'd80) + {5'd0, char_col_s0};
end

// stage 0 → 1 레지스터
reg [2:0] pixel_col_s1;
reg [3:0] pixel_row_s1;
reg       active_s1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pixel_col_s1 <= 3'd0;
        pixel_row_s1 <= 4'd0;
        active_s1    <= 1'b0;
    end else begin
        pixel_col_s1 <= pixel_col_s0;
        pixel_row_s1 <= pixel_row_s0;
        active_s1    <= active_s0;
    end
end

// stage 1: bram_b_dout 유효. 폰트 ROM 주소 설정
wire [7:0]  char_ascii_s1 = bram_b_dout[7:0];
wire [3:0]  char_fg_s1    = bram_b_dout[11:8];
wire [3:0]  char_bg_s1    = bram_b_dout[15:12];
always @(posedge clk) begin
    font_addr_r <= {char_ascii_s1[6:0], pixel_row_s1}; // 7비트 ASCII + 4비트 행
end

// stage 1 → 2 레지스터
reg [3:0] char_fg_s2;
reg [3:0] char_bg_s2;
reg [2:0] pixel_col_s2;
reg       active_s2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        char_fg_s2  <= 4'd7;
        char_bg_s2  <= 4'd0;
        pixel_col_s2 <= 3'd0;
        active_s2   <= 1'b0;
    end else begin
        char_fg_s2  <= char_fg_s1;
        char_bg_s2  <= char_bg_s1;
        pixel_col_s2 <= pixel_col_s1;
        active_s2   <= active_s1;
    end
end

// stage 2: font_row_r 유효 → pixel_on 계산 → RGB
wire pixel_on_s2 = font_row_r[3'd7 - pixel_col_s2]; // MSB=좌측

// 4비트 컬러 팔레트 → 12비트 RGB
function [11:0] palette;
    input [3:0] c;
    case (c)
        4'h0: palette = 12'h000; // 검정
        4'h1: palette = 12'h00A; // 파랑
        4'h2: palette = 12'h0A0; // 초록
        4'h3: palette = 12'h0AA; // 청록
        4'h4: palette = 12'hA00; // 빨강
        4'h5: palette = 12'hA0A; // 자홍
        4'h6: palette = 12'hAA0; // 갈색/노랑
        4'h7: palette = 12'hAAA; // 밝은 회색
        4'h8: palette = 12'h555; // 어두운 회색
        4'h9: palette = 12'h55F; // 밝은 파랑
        4'hA: palette = 12'h5F5; // 밝은 초록
        4'hB: palette = 12'h5FF; // 밝은 청록
        4'hC: palette = 12'hF55; // 밝은 빨강
        4'hD: palette = 12'hF5F; // 밝은 자홍
        4'hE: palette = 12'hFF5; // 밝은 노랑
        4'hF: palette = 12'hFFF; // 흰색
        default: palette = 12'h000;
    endcase
endfunction

wire [11:0] color_fg_rgb = palette(char_fg_s2);
wire [11:0] color_bg_rgb = palette(char_bg_s2);
wire [11:0] pixel_rgb    = pixel_on_s2 ? color_fg_rgb : color_bg_rgb;

assign vga_r = (active_s2 && reg_disp_en) ? pixel_rgb[11:8] : 4'h0;
assign vga_g = (active_s2 && reg_disp_en) ? pixel_rgb[7:4]  : 4'h0;
assign vga_b = (active_s2 && reg_disp_en) ? pixel_rgb[3:0]  : 4'h0;

// ─────────────────────────────────────────────
// 7. 7세그 FSM (VBlank 기간 dig_sel 순환)
// ─────────────────────────────────────────────
reg [1:0] dig_sel;   // 현재 표시 자리 (0~3)
reg [3:0] cur_digit; // 현재 선택된 BCD 값

// VBlank 상승 엣지에서 dig_sel 증가
reg vblank_r;
wire vblank_rise = vblank && !vblank_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vblank_r <= 1'b0;
        dig_sel  <= 2'd0;
    end else begin
        vblank_r <= vblank;
        if (vblank_rise)
            dig_sel <= dig_sel + 2'd1;
    end
end

// 선택된 자리의 BCD 값
always @(*) begin
    case (dig_sel)
        2'd0: cur_digit = reg_seg7_data[3:0];
        2'd1: cur_digit = reg_seg7_data[7:4];
        2'd2: cur_digit = reg_seg7_data[11:8];
        2'd3: cur_digit = reg_seg7_data[15:12];
        default: cur_digit = 4'h0;
    endcase
end

// 7세그 디코더 (공통양극: LOW=켜짐)
// 세그먼트: seg[6]=a, [5]=b, [4]=c, [3]=d, [2]=e, [1]=f, [0]=g
function [6:0] seg_decode;
    input [3:0] d;
    case (d)
        4'h0: seg_decode = 7'b1000000;
        4'h1: seg_decode = 7'b1111001;
        4'h2: seg_decode = 7'b0100100;
        4'h3: seg_decode = 7'b0110000;
        4'h4: seg_decode = 7'b0011001;
        4'h5: seg_decode = 7'b0010010;
        4'h6: seg_decode = 7'b0000010;
        4'h7: seg_decode = 7'b1111000;
        4'h8: seg_decode = 7'b0000000;
        4'h9: seg_decode = 7'b0010000;
        4'hA: seg_decode = 7'b0001000;
        4'hB: seg_decode = 7'b0000011;
        4'hC: seg_decode = 7'b1000110;
        4'hD: seg_decode = 7'b0100001;
        4'hE: seg_decode = 7'b0000110;
        4'hF: seg_decode = 7'b0001110;
        default: seg_decode = 7'b1111111;
    endcase
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        seg <= 7'b1111111; // 소등
        an  <= 4'b1111;   // 모두 비활성
    end else if (!reg_seg_en) begin
        seg <= 7'b1111111;
        an  <= 4'b1111;
    end else begin
        // 블랭크 비트 확인
        if (reg_seg7_ctrl[dig_sel]) begin
            seg <= 7'b1111111;
            an  <= 4'b1111;
        end else begin
            seg <= seg_decode(cur_digit);
            an  <= ~(4'b0001 << dig_sel); // 해당 자리만 LOW
        end
    end
end

// ─────────────────────────────────────────────
// 8. AXI4-Lite 슬레이브
// ─────────────────────────────────────────────
// 쓰기 채널 (write address + data 래치 후 처리)
reg [7:0]  wr_addr;
reg [31:0] wr_data;
reg        wr_pending;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        s_axil_bresp   <= 2'b00;
        wr_pending     <= 1'b0;
        wr_addr        <= 8'd0;
        wr_data        <= 32'd0;
        reg_disp_en    <= 1'b1;
        reg_seg_en     <= 1'b1;
        reg_char_addr  <= 12'd0;
        reg_seg7_data  <= 16'd0;
        reg_seg7_ctrl  <= 12'd0;
    end else begin
        // 주소와 데이터를 각각 래치
        if (s_axil_awvalid && !wr_pending) begin
            s_axil_awready <= 1'b1;
            wr_addr        <= s_axil_awaddr;
        end else begin
            s_axil_awready <= 1'b0;
        end

        if (s_axil_wvalid && !wr_pending) begin
            s_axil_wready <= 1'b1;
            wr_data       <= s_axil_wdata;
        end else begin
            s_axil_wready <= 1'b0;
        end

        // 주소와 데이터가 모두 받아지면 처리
        if (s_axil_awvalid && s_axil_wvalid && !wr_pending) begin
            wr_pending <= 1'b1;
        end

        if (wr_pending) begin
            // 레지스터 디코드
            case (wr_addr[5:2]) // 32비트 정렬 (wr_addr >> 2)
                3'd2: begin // 0x08 CTRL
                    reg_disp_en <= wr_data[0];
                    reg_seg_en  <= wr_data[1];
                end
                // 0x0C STATUS: 읽기 전용
                3'd4: begin // 0x10 CHAR_ADDR
                    reg_char_addr <= wr_data[11:0];
                end
                3'd5: begin // 0x14 CHAR_DATA → BRAM 쓰기
                    if (reg_char_addr < CHAR_BUF_DEPTH)
                        char_buf[reg_char_addr] <= wr_data[15:0];
                end
                3'd6: begin // 0x18 SEG7_DATA
                    reg_seg7_data <= wr_data[15:0];
                end
                3'd7: begin // 0x1C SEG7_CTRL
                    reg_seg7_ctrl <= wr_data[11:0];
                end
                default: ; // ID, VER 쓰기 무시
            endcase

            // 응답
            s_axil_bvalid <= 1'b1;
            s_axil_bresp  <= 2'b00; // OKAY
            wr_pending    <= 1'b0;
        end

        if (s_axil_bvalid && s_axil_bready)
            s_axil_bvalid <= 1'b0;
    end
end

// 읽기 채널
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= 32'd0;
        s_axil_rresp   <= 2'b00;
    end else begin
        if (s_axil_arvalid && !s_axil_rvalid) begin
            s_axil_arready <= 1'b1;
            s_axil_rvalid  <= 1'b1;
            s_axil_rresp   <= 2'b00;
            case (s_axil_araddr[5:2])
                3'd0: s_axil_rdata <= ID_VAL;
                3'd1: s_axil_rdata <= VER_VAL;
                3'd2: s_axil_rdata <= {30'd0, reg_seg_en, reg_disp_en};
                3'd3: s_axil_rdata <= {16'd0, vsync_count, 7'd0, vblank};
                3'd4: s_axil_rdata <= {20'd0, reg_char_addr};
                3'd5: s_axil_rdata <= {16'd0, char_buf[reg_char_addr]};
                3'd6: s_axil_rdata <= {16'd0, reg_seg7_data};
                3'd7: s_axil_rdata <= {20'd0, reg_seg7_ctrl};
                default: s_axil_rdata <= 32'hDEADBEEF;
            endcase
        end else begin
            s_axil_arready <= 1'b0;
        end

        if (s_axil_rvalid && s_axil_rready)
            s_axil_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire
