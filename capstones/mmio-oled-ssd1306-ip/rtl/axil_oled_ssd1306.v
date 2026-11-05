// axil_oled_ssd1306.v — AXI4-Lite 슬레이브 + SSD1306 OLED 컨트롤러
// 하네스 원본. 외부 코드 복사 아님.
//
// 레지스터맵 (베이스: 외부 설정, 오프셋만):
//   0x00 CTRL   RW  [0]=en_refresh  [1]=force_init(펄스) [2]=soft_rst(펄스)
//   0x04 STATUS RO  [0]=init_done   [1]=busy [3:2]=fsm_state[1:0] [4]=refresh_done_pulse
//   0x08 BUF_ADDR RW [9:0]={page[1:0], col[6:0]}
//   0x0C BUF_DATA WO [7:0] 한 바이트. 쓰기마다 BUF_ADDR 위치에 저장.
//
// SPI 초기화 순서: 24바이트 ROM (SSD1306 128×32, SPI 4선 모드)
// 프레임 버퍼: 512바이트 분산 RAM (4 page × 128 col)
// 갱신 FSM: 4페이지 연속 전송 → irq_refresh_done 펄스
`default_nettype none
`timescale 1ns/1ps

module axil_oled_ssd1306 #(
    parameter integer CLK_DIV  = 10,   // SPI SCK = clk / (2*CLK_DIV)
    parameter integer INIT_LEN = 24    // 초기화 명령 ROM 길이
) (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite 슬레이브
    input  wire [7:0]  s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,
    input  wire [7:0]  s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // SPI → Pmod
    output wire        oled_sck,
    output wire        oled_mosi,
    output reg         oled_cs_n,
    output reg         oled_dc,     // 0=명령, 1=데이터
    output reg         oled_res_n,  // 0=리셋

    // IRQ
    output reg         irq_refresh_done
);

    // ═══════════════════════════════════════════════════
    // 1. SPI 초기화 ROM (24바이트)
    // ═══════════════════════════════════════════════════
    // SSD1306 128×32 SPI 초기화 순서 (전원 인가 후 100ms 대기는 소프트웨어 담당)
    reg [7:0] init_rom [0:INIT_LEN-1];
    initial begin
        init_rom[ 0] = 8'hAE; // Display OFF
        init_rom[ 1] = 8'hD5; // Set Display Clock
        init_rom[ 2] = 8'h80; //   ratio=0x80
        init_rom[ 3] = 8'hA8; // Set Multiplex Ratio
        init_rom[ 4] = 8'h1F; //   31 (128×32)
        init_rom[ 5] = 8'hD3; // Set Display Offset
        init_rom[ 6] = 8'h00; //   0
        init_rom[ 7] = 8'h40; // Set Start Line = 0
        init_rom[ 8] = 8'h8D; // Charge Pump Setting
        init_rom[ 9] = 8'h14; //   Enable
        init_rom[10] = 8'h20; // Memory Addressing Mode
        init_rom[11] = 8'h00; //   Horizontal
        init_rom[12] = 8'hA1; // Segment Re-map (mirror)
        init_rom[13] = 8'hC8; // COM Output Scan Dir (flip)
        init_rom[14] = 8'hDA; // COM Pins Hardware
        init_rom[15] = 8'h02; //   Sequential, no remap (128×32)
        init_rom[16] = 8'h81; // Set Contrast
        init_rom[17] = 8'hCF; //   0xCF
        init_rom[18] = 8'hD9; // Pre-charge Period
        init_rom[19] = 8'hF1; //   0xF1
        init_rom[20] = 8'hDB; // VCOMH Deselect
        init_rom[21] = 8'h40; //   0x40
        init_rom[22] = 8'hA4; // Entire Display ON (RAM)
        init_rom[23] = 8'hAF; // Display ON
    end

    // ═══════════════════════════════════════════════════
    // 2. 프레임 버퍼 (512바이트 분산 RAM)
    // ═══════════════════════════════════════════════════
    reg [7:0] fbuf [0:511]; // [page*128 + col]
    integer fb_i;
    initial begin
        for (fb_i = 0; fb_i < 512; fb_i = fb_i + 1)
            fbuf[fb_i] = 8'h00;
    end

    // ═══════════════════════════════════════════════════
    // 3. 내부 레지스터
    // ═══════════════════════════════════════════════════
    reg        reg_en_refresh;
    reg        init_done;
    reg [1:0]  fsm_state;
    reg        refresh_done_pulse;
    reg [9:0]  buf_addr_reg;   // {page[1:0], col[6:0]}

    // ═══════════════════════════════════════════════════
    // 4. SPI 마스터 인스턴스
    // ═══════════════════════════════════════════════════
    reg        spi_start;
    reg  [7:0] spi_byte;
    wire       spi_busy;
    wire       spi_done;

    spi_master_8b #(.CLK_DIV(CLK_DIV)) u_spi (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (spi_start),
        .byte_data (spi_byte),
        .busy      (spi_busy),
        .done      (spi_done),
        .sck       (oled_sck),
        .mosi      (oled_mosi)
    );

    // ═══════════════════════════════════════════════════
    // 5. 초기화 + 갱신 FSM
    // ═══════════════════════════════════════════════════
    // fsm_state: 00=RESET, 01=INIT, 10=IDLE, 11=REFRESH
    localparam ST_RESET   = 2'd0;
    localparam ST_INIT    = 2'd1;
    localparam ST_IDLE    = 2'd2;
    localparam ST_REFRESH = 2'd3;

    reg [4:0]  init_idx;    // 초기화 ROM 인덱스 (0..23)
    reg [8:0]  col_cnt;     // 갱신 열 카운터 (0..127)
    reg [1:0]  page_cnt;    // 갱신 페이지 카운터 (0..3)
    reg        force_init_r;
    reg        send_pending; // SPI 전송 대기

    // 페이지 주소 설정 명령 (갱신 전 각 페이지마다)
    // 명령: B0+page, 00(Lower Col), 10(Higher Col)
    reg [1:0]  hdr_idx;     // 페이지 헤더 명령 인덱스 (0..2)
    reg        in_header;   // 헤더 전송 중

    // 갱신 완료 IRQ
    reg  refresh_irq_r;

    // 리셋 카운터 (10 사이클)
    reg [3:0] rst_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state       <= ST_RESET;
            init_done       <= 1'b0;
            init_idx        <= 5'd0;
            col_cnt         <= 9'd0;
            page_cnt        <= 2'd0;
            hdr_idx         <= 2'd0;
            in_header       <= 1'b0;
            send_pending    <= 1'b0;
            spi_start       <= 1'b0;
            spi_byte        <= 8'd0;
            oled_cs_n       <= 1'b1;
            oled_dc         <= 1'b0;
            oled_res_n      <= 1'b0;
            force_init_r    <= 1'b0;
            refresh_done_pulse <= 1'b0;
            irq_refresh_done   <= 1'b0;
            rst_cnt         <= 4'd0;
        end else begin
            spi_start          <= 1'b0;
            refresh_done_pulse <= 1'b0;
            irq_refresh_done   <= 1'b0;

            case (fsm_state)
                // ── RESET: 하드웨어 리셋 10사이클 ──────────
                ST_RESET: begin
                    oled_res_n <= 1'b0;
                    oled_cs_n  <= 1'b1;
                    if (rst_cnt < 4'd10) begin
                        rst_cnt <= rst_cnt + 4'd1;
                    end else begin
                        oled_res_n <= 1'b1;
                        rst_cnt    <= 4'd0;
                        init_idx   <= 5'd0;
                        fsm_state  <= ST_INIT;
                    end
                end

                // ── INIT: 24바이트 ROM 순차 전송 ───────────
                ST_INIT: begin
                    oled_dc   <= 1'b0;  // 명령 모드
                    oled_cs_n <= 1'b0;
                    if (!spi_busy && !send_pending) begin
                        if (init_idx < INIT_LEN) begin
                            spi_byte     <= init_rom[init_idx];
                            spi_start    <= 1'b1;
                            send_pending <= 1'b1;
                        end else begin
                            // 초기화 완료
                            oled_cs_n  <= 1'b1;
                            init_done  <= 1'b1;
                            fsm_state  <= ST_IDLE;
                        end
                    end
                    if (spi_done) begin
                        send_pending <= 1'b0;
                        init_idx     <= init_idx + 5'd1;
                    end
                end

                // ── IDLE: 갱신 요청 대기 ────────────────────
                ST_IDLE: begin
                    oled_cs_n <= 1'b1;
                    if (force_init_r) begin
                        force_init_r <= 1'b0;
                        init_done    <= 1'b0;
                        init_idx     <= 5'd0;
                        rst_cnt      <= 4'd0;
                        fsm_state    <= ST_RESET;
                    end else if (reg_en_refresh) begin
                        // 갱신 시작
                        page_cnt  <= 2'd0;
                        col_cnt   <= 9'd0;
                        hdr_idx   <= 2'd0;
                        in_header <= 1'b1;
                        oled_dc   <= 1'b0;
                        oled_cs_n <= 1'b0;
                        fsm_state <= ST_REFRESH;
                    end
                end

                // ── REFRESH: 4페이지 × 128열 전송 ──────────
                ST_REFRESH: begin
                    if (force_init_r) begin
                        // 갱신 중 force_init: 즉시 중단
                        force_init_r <= 1'b0;
                        oled_cs_n    <= 1'b1;
                        init_done    <= 1'b0;
                        init_idx     <= 5'd0;
                        rst_cnt      <= 4'd0;
                        fsm_state    <= ST_RESET;
                    end else if (!spi_busy && !send_pending) begin
                        if (in_header) begin
                            // 페이지 헤더 명령 3개: B0+page, 0x00, 0x10
                            oled_dc <= 1'b0;
                            case (hdr_idx)
                                2'd0: spi_byte <= 8'hB0 | {6'd0, page_cnt};
                                2'd1: spi_byte <= 8'h00;
                                2'd2: spi_byte <= 8'h10;
                                default: spi_byte <= 8'h00;
                            endcase
                            spi_start    <= 1'b1;
                            send_pending <= 1'b1;
                        end else begin
                            // 데이터 전송
                            oled_dc   <= 1'b1;
                            spi_byte  <= fbuf[{page_cnt, col_cnt[6:0]}];
                            spi_start    <= 1'b1;
                            send_pending <= 1'b1;
                        end
                    end

                    if (spi_done) begin
                        send_pending <= 1'b0;
                        if (in_header) begin
                            if (hdr_idx < 2'd2) begin
                                hdr_idx <= hdr_idx + 2'd1;
                            end else begin
                                hdr_idx   <= 2'd0;
                                in_header <= 1'b0;
                                col_cnt   <= 9'd0;
                            end
                        end else begin
                            if (col_cnt < 9'd127) begin
                                col_cnt <= col_cnt + 9'd1;
                            end else begin
                                // 한 페이지 완료
                                col_cnt <= 9'd0;
                                if (page_cnt < 2'd3) begin
                                    page_cnt  <= page_cnt + 2'd1;
                                    hdr_idx   <= 2'd0;
                                    in_header <= 1'b1;
                                    oled_dc   <= 1'b0;
                                end else begin
                                    // 4페이지 모두 완료
                                    oled_cs_n          <= 1'b1;
                                    refresh_done_pulse <= 1'b1;
                                    irq_refresh_done   <= 1'b1;
                                    fsm_state          <= ST_IDLE;
                                end
                            end
                        end
                    end
                end

                default: fsm_state <= ST_RESET;
            endcase
        end
    end

    // ═══════════════════════════════════════════════════
    // 6. AXI4-Lite 슬레이브
    // ═══════════════════════════════════════════════════
    // 쓰기 주소 래치
    reg [7:0] aw_addr_lat;
    reg       aw_lat_v;

    // 단일 사이클 비동기 슬레이브 — 쓰기
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_awready      <= 1'b0;
            s_wready       <= 1'b0;
            s_bresp        <= 2'b00;
            s_bvalid       <= 1'b0;
            aw_addr_lat    <= 8'd0;
            aw_lat_v       <= 1'b0;
            reg_en_refresh <= 1'b0;
        end else begin
            s_awready <= 1'b0;
            s_wready  <= 1'b0;

            // 주소 채널
            if (s_awvalid && !aw_lat_v) begin
                s_awready   <= 1'b1;
                aw_addr_lat <= s_awaddr;
                aw_lat_v    <= 1'b1;
            end

            // 데이터 채널
            if (s_wvalid && aw_lat_v) begin
                s_wready <= 1'b1;
                aw_lat_v <= 1'b0;
                case (aw_addr_lat[3:2])
                    2'd0: begin // CTRL
                        reg_en_refresh <= s_wdata[0];
                        if (s_wdata[1]) force_init_r <= 1'b1; // force_init 펄스
                        // soft_rst [2]: force_init과 동일하게 처리
                        if (s_wdata[2]) force_init_r <= 1'b1;
                    end
                    2'd2: begin // BUF_ADDR
                        buf_addr_reg <= s_wdata[9:0];
                    end
                    2'd3: begin // BUF_DATA
                        fbuf[buf_addr_reg] <= s_wdata[7:0];
                    end
                    default:; // STATUS는 RO
                endcase
                s_bresp  <= 2'b00;
                s_bvalid <= 1'b1;
            end

            // 응답 채널
            if (s_bvalid && s_bready) begin
                s_bvalid <= 1'b0;
            end
        end
    end

    // 읽기
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_arready <= 1'b0;
            s_rdata   <= 32'd0;
            s_rresp   <= 2'b00;
            s_rvalid  <= 1'b0;
        end else begin
            s_arready <= 1'b0;
            if (s_arvalid && !s_rvalid) begin
                s_arready <= 1'b1;
                s_rresp   <= 2'b00;
                s_rvalid  <= 1'b1;
                case (s_araddr[3:2])
                    2'd0: s_rdata <= {31'd0, reg_en_refresh};
                    2'd1: s_rdata <= {27'd0, refresh_done_pulse,
                                      fsm_state,
                                      (fsm_state != ST_IDLE),
                                      init_done};
                    2'd2: s_rdata <= {22'd0, buf_addr_reg};
                    default: s_rdata <= 32'd0;
                endcase
            end
            if (s_rvalid && s_rready) begin
                s_rvalid <= 1'b0;
            end
        end
    end

endmodule
`default_nettype wire
