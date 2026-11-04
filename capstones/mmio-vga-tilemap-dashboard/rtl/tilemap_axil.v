// tilemap_axil.v — AXI4-Lite 슬레이브 + 2단 스캔라인 VGA 렌더러
//
// 역할: 80×60 타일맵(256 타일, 16색 팔레트)을 AXI4-Lite 레지스터로 프로그래밍하고
//       VGA h/v 카운터에 맞춰 화소를 1클럭 지연으로 출력한다.
//
// 클럭: 단일 clk(25 MHz). 프로덕션에서는 AXI 버스(100 MHz)와 CDC 추가 권장.
//
// 메모리 모델:
//   tilemap[4800]  : tile_id[7:0] — row*80+col로 접근
//   attr[4800]     : {bg[3:0], fg[3:0]} — 같은 인덱스
//   font[2048]     : 8비트 비트맵 한 줄 — tile_id*8+row
//   palette[16]    : {R[3:0],G[3:0],B[3:0]}
//
// 렌더 파이프라인 (1 사이클):
//   입력 h_count,v_count → 타일 주소 계산 → 메모리 읽기(reg) → 화소 출력
//   출력은 h/v 입력보다 1사이클 늦으므로 h_count=1 위치의 화소가 h=0에 나옴.
//   테스트벤치가 이 오프셋을 감안한다.

module tilemap_axil (
    // ---- 공통 클럭/리셋 ----
    input  wire        clk,       // 25 MHz
    input  wire        rst_n,     // 활성 로우 리셋

    // ---- AXI4-Lite 슬레이브 ----
    input  wire [15:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [15:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output reg  [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,

    // ---- VGA 타이밍 입력 ----
    input  wire [9:0]  h_count,
    input  wire [9:0]  v_count,
    input  wire        active,
    input  wire        frame_end, // 1사이클 펄스

    // ---- VGA 화소 출력 (1사이클 지연) ----
    output reg  [3:0]  pix_r,
    output reg  [3:0]  pix_g,
    output reg  [3:0]  pix_b,

    // ---- 인터럽트 (level, 활성 하이) ----
    output wire        irq
);

// ================================================================
// 메모리
// ================================================================
reg [7:0] tilemap [0:4799];  // tile_id
reg [7:0] attr    [0:4799];  // {bg[3:0], fg[3:0]}
reg [7:0] font_rom[0:2047];  // tile_id*8+row → 8비트 비트맵
reg [11:0] palette[0:15];    // {R[3:0],G[3:0],B[3:0]}

// ================================================================
// 제어 레지스터
// ================================================================
reg [31:0] ctrl_reg;        // bit0=disp_en
reg [0:0]  irq_status;      // bit0=frame_end
reg [0:0]  irq_enable;      // bit0=enable
reg [12:0] tile_addr_reg;   // 간접 쓰기 주소
reg [10:0] font_addr_reg;   // 간접 쓰기 주소

// ================================================================
// AXI4-Lite 슬레이브 — AWVALID+WVALID 동시 수용
// ================================================================
assign s_axil_awready = 1'b1;
assign s_axil_wready  = 1'b1;
assign s_axil_arready = 1'b1;
assign s_axil_rresp   = 2'b00;

wire do_write = s_axil_awvalid && s_axil_wvalid;
wire [15:0] waddr = s_axil_awaddr;
wire [31:0] wdata = s_axil_wdata;

// BVALID 응답
always @(posedge clk) begin
    if (!rst_n) begin
        s_axil_bvalid <= 1'b0;
        s_axil_bresp  <= 2'b00;
    end else begin
        if (do_write)
            s_axil_bvalid <= 1'b1;
        else if (s_axil_bready)
            s_axil_bvalid <= 1'b0;
    end
end

// 레지스터 쓰기
always @(posedge clk) begin
    if (!rst_n) begin
        ctrl_reg      <= 32'h0000_0001; // disp_en 기본 1
        irq_enable    <= 1'b0;
        irq_status    <= 1'b0;
        tile_addr_reg <= 13'd0;
        font_addr_reg <= 11'd0;
        // 기본 팔레트: EGA 16색
        palette[ 0] <= 12'h000; // 검정
        palette[ 1] <= 12'h00A; // 파랑
        palette[ 2] <= 12'h0A0; // 초록
        palette[ 3] <= 12'h0AA; // 청록
        palette[ 4] <= 12'hA00; // 빨강
        palette[ 5] <= 12'hA0A; // 자홍
        palette[ 6] <= 12'hA50; // 갈색
        palette[ 7] <= 12'hAAA; // 밝은 회색
        palette[ 8] <= 12'h555; // 어두운 회색
        palette[ 9] <= 12'h55F; // 밝은 파랑
        palette[10] <= 12'h5F5; // 밝은 초록
        palette[11] <= 12'h5FF; // 밝은 청록
        palette[12] <= 12'hF55; // 밝은 빨강
        palette[13] <= 12'hF5F; // 밝은 자홍
        palette[14] <= 12'hFF5; // 밝은 노랑
        palette[15] <= 12'hFFF; // 흰색
    end else begin
        // IRQ_STATUS W1C
        if (frame_end)
            irq_status <= 1'b1;
        if (do_write && waddr == 16'h0008)
            irq_status <= irq_status & ~wdata[0:0];

        if (do_write) begin
            case (waddr)
                16'h000C: irq_enable    <= wdata[0:0];
                16'h0010: ctrl_reg      <= wdata;
                16'h0018: tile_addr_reg <= wdata[12:0];
                16'h001C: begin
                    if (tile_addr_reg < 13'd4800) begin
                        tilemap[tile_addr_reg] <= wdata[7:0];
                        attr   [tile_addr_reg] <= wdata[15:8];
                    end
                end
                16'h0020: font_addr_reg <= wdata[10:0];
                16'h0024: begin
                    font_rom[font_addr_reg] <= wdata[7:0];
                end
                default: begin
                    // 팔레트 0x0028..0x0064
                    if (waddr >= 16'h0028 && waddr <= 16'h0064) begin
                        palette[(waddr - 16'h0028) >> 2] <= wdata[11:0];
                    end
                end
            endcase
        end
    end
end

// 레지스터 읽기
always @(posedge clk) begin
    if (!rst_n) begin
        s_axil_rvalid <= 1'b0;
        s_axil_rdata  <= 32'd0;
    end else begin
        if (s_axil_arvalid && !s_axil_rvalid) begin
            s_axil_rvalid <= 1'b1;
            case (s_axil_araddr)
                16'h0000: s_axil_rdata <= 32'h544D_4150; // "TMAP"
                16'h0004: s_axil_rdata <= 32'h0001_0000; // VER 1.0
                16'h0008: s_axil_rdata <= {31'd0, irq_status};
                16'h000C: s_axil_rdata <= {31'd0, irq_enable};
                16'h0010: s_axil_rdata <= ctrl_reg;
                16'h0014: s_axil_rdata <= {31'd0, (v_count >= 10'd480) ? 1'b1 : 1'b0};
                default: begin
                    if (s_axil_araddr >= 16'h0028 && s_axil_araddr <= 16'h0064)
                        s_axil_rdata <= {20'd0, palette[(s_axil_araddr - 16'h0028) >> 2]};
                    else
                        s_axil_rdata <= 32'hDEAD_BEEF;
                end
            endcase
        end else if (s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
        end
    end
end

// ================================================================
// 렌더 파이프라인 (1 사이클)
// ================================================================
// 타일 열/행 계산: tile_col = h_count[2:0+3..9] = h_count>>3, tile_row = v_count>>3
// tile_row*80 = tile_row*64 + tile_row*16 = (tile_row<<6)+(tile_row<<4)
wire [5:0] tile_col_w = h_count[8:3];  // 0..79 (h_count < 640)
wire [5:0] tile_row_w = v_count[8:3];  // 0..59 (v_count < 480)
wire [2:0] pixel_x_w  = h_count[2:0];
wire [2:0] pixel_y_w  = v_count[2:0];
wire [12:0] tile_base_w = {tile_row_w, 6'b0} + {2'b0, tile_row_w, 4'b0}; // *80
wire [12:0] tile_idx_w  = tile_base_w + {7'b0, tile_col_w};

wire disp_en = ctrl_reg[0];

// 1사이클 파이프라인: 등록된 메모리 읽기
reg [7:0] tile_id_q, tile_attr_q;
reg [2:0] pixel_x_q, pixel_y_q;
reg       active_q;

always @(posedge clk) begin
    if (!rst_n) begin
        tile_id_q   <= 8'd0;
        tile_attr_q <= 8'd0;
        pixel_x_q   <= 3'd0;
        pixel_y_q   <= 3'd0;
        active_q    <= 1'b0;
    end else begin
        tile_id_q   <= (tile_idx_w < 13'd4800) ? tilemap[tile_idx_w] : 8'd0;
        tile_attr_q <= (tile_idx_w < 13'd4800) ? attr   [tile_idx_w] : 8'd0;
        pixel_x_q   <= pixel_x_w;
        pixel_y_q   <= pixel_y_w;
        active_q    <= active && disp_en;
    end
end

// 화소 계산: font_rom[tile_id * 8 + pixel_y]의 MSB-first 비트
wire [10:0] font_idx_w = {tile_id_q, pixel_y_q};
wire [7:0]  font_row_w = font_rom[font_idx_w];
wire        pix_bit    = font_row_w[3'd7 - pixel_x_q]; // MSB가 좌측

wire [3:0] fg_color = tile_attr_q[3:0];
wire [3:0] bg_color = tile_attr_q[7:4];
wire [3:0] color_idx = pix_bit ? fg_color : bg_color;
wire [11:0] rgb     = active_q ? palette[color_idx] : 12'd0;

always @(posedge clk) begin
    if (!rst_n) begin
        pix_r <= 4'd0;
        pix_g <= 4'd0;
        pix_b <= 4'd0;
    end else begin
        pix_r <= rgb[11:8];
        pix_g <= rgb[7:4];
        pix_b <= rgb[3:0];
    end
end

// ================================================================
// 인터럽트
// ================================================================
assign irq = irq_status & irq_enable;

endmodule
