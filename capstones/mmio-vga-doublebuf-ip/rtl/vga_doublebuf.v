// vga_doublebuf.v — BRAM 핑퐁 더블 버퍼 VGA IP (AXI4-Lite 슬레이브)
// 캡스톤: mmio-vga-doublebuf-ip  (Basys3, T2, 2026-11-06)
// 해상도: 160×120 RGB332 → 4× 스케일 → VGA 640×480@60Hz
// BRAM: 16K×8 ×2 버퍼 → word(32비트) 단위 패킹 → 약 15 BRAM36 추정
// AXI4-Lite: 14비트 주소 (슬롯 [0A] 오프셋 기준), 32비트 데이터
// 단일 25MHz 도메인 (실 MicroBlaze V 연결 시 CDC 처리 필요 — risks 참조)
// Verilog-2001 / iverilog / verilator / yosys 호환

`default_nettype none
`timescale 1ns/1ps

module vga_doublebuf #(
    parameter ADDR_WIDTH = 14   // AXI 주소 비트 수
) (
    // 클럭·리셋
    input  wire                  clk,       // 25 MHz
    input  wire                  rst_n,     // 동기 active-low 리셋

    // AXI4-Lite 슬레이브 — 쓰기 채널
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,
    input  wire [31:0]           s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,  // 무시 (32비트 word 단위)
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,
    output wire [1:0]            s_axi_bresp,  // 항상 OKAY

    // AXI4-Lite 슬레이브 — 읽기 채널
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,
    output reg  [31:0]           s_axi_rdata,
    output wire [1:0]            s_axi_rresp,  // 항상 OKAY

    // VGA 출력
    output reg                   vga_hs,
    output reg                   vga_vs,
    output reg  [3:0]            vga_r,
    output reg  [3:0]            vga_g,
    output reg  [3:0]            vga_b
);

// ----------------------------------------------------------------
// 상수
// ----------------------------------------------------------------
assign s_axi_bresp = 2'b00;
assign s_axi_rresp = 2'b00;

// 오프셋 word 주소 (byte_addr[15:2])
// buf0: 0 ~ 4799   (160×120 픽셀 / 4픽셀/word)
// buf1: 4800 ~ 9599
localparam [13:0] BUF1_WSTART = 14'd4800;
localparam [13:0] ADDR_STATUS = 14'h2580; // 0x9600>>2
localparam [13:0] ADDR_CTRL   = 14'h2581; // 0x9604>>2
localparam [13:0] ADDR_FCNT   = 14'h2582; // 0x9608>>2

// ----------------------------------------------------------------
// BRAM: 9600 words (32비트). 양쪽 버퍼 연속 배치
// Xilinx: 별도 always 블록이면 dual-port BRAM 추론
// ----------------------------------------------------------------
reg [31:0] pixbuf [0:9599];

// ----------------------------------------------------------------
// VGA 타이밍 인스턴스
// ----------------------------------------------------------------
wire [9:0] h_count, v_count;
wire       hsync, vsync, active, frame_end;

vga_timing u_timing (
    .clk_25m  (clk),
    .rst      (~rst_n),
    .h_count  (h_count),
    .v_count  (v_count),
    .hsync    (hsync),
    .vsync    (vsync),
    .active   (active),
    .frame_end(frame_end)
);

// ----------------------------------------------------------------
// 픽셀 주소 계산 (4× 스케일: h>>2, v>>2)
// row_off = row * 160 = row*128 + row*32 (shift + add)
// 15비트 필요: 최대 119×160 = 19040
// ----------------------------------------------------------------
wire [7:0]  col_lr   = h_count[9:2];          // 0..159
wire [6:0]  row_lr   = v_count[8:2];          // 0..119
wire [14:0] row_off  = {1'b0, row_lr, 7'b0}   // row_lr * 128
                     + {3'b0, row_lr, 5'b0};  // row_lr * 32  → *160
wire [14:0] pixel_i  = row_off + {7'b0, col_lr}; // 0..19199
wire [12:0] word_idx = pixel_i[14:2];         // 0..4799 (두 버퍼 중 한 쪽)
wire [1:0]  byte_sel = pixel_i[1:0];          // 바이트 선택

// 읽을 버퍼 선택: active_buf=0 → buf0, active_buf=1 → buf1
reg         active_buf;  // 디스플레이 중인 버퍼
wire [13:0] bram_rd  = {1'b0, word_idx}
                     + (active_buf ? BUF1_WSTART : 14'd0);

// ----------------------------------------------------------------
// 상태 레지스터
// ----------------------------------------------------------------
reg         swap_req;
reg         vsync_flag;    // 프레임 끝에 세트, STATUS 읽기에 클리어
reg  [31:0] frame_cnt;

// AXI 쓰기 래치
reg         aw_got;
reg         w_got;
reg  [13:0] awaddr_r;
reg  [31:0] wdata_r;

// BRAM 쓰기 판단 (별도 always 블록)
wire        is_pix_write = aw_got && w_got
                         && ({2'b0, awaddr_r} < {2'b0, BUF1_WSTART} + {2'b0, BUF1_WSTART});
// word 주소 0~9599 (두 버퍼 합쳐서)
wire        pix_write_en = is_pix_write;

// ----------------------------------------------------------------
// 블록 1: 메인 FSM (AXI 채널 + 제어 레지스터)
// ----------------------------------------------------------------
always @(posedge clk) begin
    if (!rst_n) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rdata   <= 32'b0;
        aw_got        <= 1'b0;
        w_got         <= 1'b0;
        awaddr_r      <= 14'b0;
        wdata_r       <= 32'b0;
        active_buf    <= 1'b0;
        swap_req      <= 1'b0;
        vsync_flag    <= 1'b0;
        frame_cnt     <= 32'b0;
    end else begin
        // 기본값
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_arready <= 1'b0;

        // ---- 버퍼 스왑 (frame_end 우선) ----
        if (frame_end) begin
            frame_cnt  <= frame_cnt + 32'd1;
            vsync_flag <= 1'b1;
            if (swap_req) begin
                active_buf <= ~active_buf;
                swap_req   <= 1'b0;
            end
        end

        // ---- AXI 쓰기: AW 래치 ----
        if (s_axi_awvalid && !aw_got) begin
            s_axi_awready <= 1'b1;
            aw_got        <= 1'b1;
            awaddr_r      <= s_axi_awaddr[13:0];
        end

        // ---- AXI 쓰기: W 래치 ----
        if (s_axi_wvalid && !w_got) begin
            s_axi_wready <= 1'b1;
            w_got        <= 1'b1;
            wdata_r      <= s_axi_wdata;
        end

        // ---- AXI 쓰기: 실행 (두 채널 모두 도착 후) ----
        if (aw_got && w_got) begin
            // 제어 레지스터 쓰기
            if (awaddr_r == ADDR_CTRL)
                swap_req <= wdata_r[0];
            // 픽셀 쓰기는 블록 2에서 처리

            // 응답 발행
            s_axi_bvalid <= 1'b1;
            aw_got       <= 1'b0;
            w_got        <= 1'b0;
        end

        // B 핸드셰이크 클리어
        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;

        // ---- AXI 읽기 ----
        if (s_axi_arvalid && !s_axi_rvalid) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b1;
            case (s_axi_araddr[13:0])
                ADDR_STATUS: begin
                    s_axi_rdata <= {30'b0, vsync_flag, active_buf};
                    vsync_flag  <= 1'b0; // 읽으면 클리어 (swap이 같은 사이클이면 1 유지)
                end
                ADDR_CTRL:  s_axi_rdata <= {31'b0, swap_req};
                ADDR_FCNT:  s_axi_rdata <= frame_cnt;
                default:    s_axi_rdata <= 32'hDEAD_BEEF;
            endcase
        end
        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;
    end
end

// ----------------------------------------------------------------
// 블록 2: BRAM 쓰기 (별도 블록 → Xilinx BRAM 추론)
// ----------------------------------------------------------------
always @(posedge clk) begin
    if (pix_write_en)
        pixbuf[awaddr_r] <= wdata_r;
end

// ----------------------------------------------------------------
// 블록 3: BRAM 읽기 + VGA 1클럭 파이프라인
// ----------------------------------------------------------------
reg [31:0] rd_word;
reg [1:0]  byte_sel_r;
reg        active_r, hsync_r, vsync_r;

always @(posedge clk) begin
    rd_word    <= pixbuf[bram_rd];
    byte_sel_r <= byte_sel;
    active_r   <= active;
    hsync_r    <= hsync;
    vsync_r    <= vsync;
end

// 바이트 선택
wire [7:0] pix_byte = (byte_sel_r == 2'd0) ? rd_word[7:0]  :
                      (byte_sel_r == 2'd1) ? rd_word[15:8] :
                      (byte_sel_r == 2'd2) ? rd_word[23:16]:
                                             rd_word[31:24];

// ----------------------------------------------------------------
// 블록 4: VGA 출력 레지스터 (RGB332 → 12비트)
// R[7:5]→4비트, G[4:2]→4비트, B[1:0]→4비트
// ----------------------------------------------------------------
always @(posedge clk) begin
    if (!rst_n) begin
        vga_hs <= 1'b1; vga_vs <= 1'b1;
        vga_r  <= 4'b0; vga_g  <= 4'b0; vga_b  <= 4'b0;
    end else begin
        vga_hs <= hsync_r;
        vga_vs <= vsync_r;
        if (active_r) begin
            vga_r <= {pix_byte[7:5], pix_byte[7]};   // R[7:5] 확장
            vga_g <= {pix_byte[4:2], pix_byte[4]};   // G[4:2] 확장
            vga_b <= {pix_byte[1:0], pix_byte[1:0]}; // B[1:0] 확장
        end else begin
            vga_r <= 4'b0; vga_g <= 4'b0; vga_b <= 4'b0;
        end
    end
end

endmodule
`default_nettype wire
