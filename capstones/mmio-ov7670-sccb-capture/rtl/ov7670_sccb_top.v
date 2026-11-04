// ov7670_sccb_top.v — OV7670 SCCB 설정 + 캡처 프런트엔드 SoC 코어
// MMIO 슬레이브(단독 시뮬레이션용 mmio-lite, 0x1004_0000)
// 하위 모듈: sccb_tx, ov7670_capture, sync_pulse
// 설정 ROM: 10개 엔트리 (실제 OV7670 RGB565 초기화 순서 일부)
// Verilog-2001, 외부 IP 없음.
//
// 레지스터 맵 (mmio-lite, word 접근):
//   OFF 0x00  CTRL    WO  bit0=START_CFG, bit1=CAP_EN, bit15=RESET
//   OFF 0x04  STATUS  RO  bit0=CFG_DONE, bit1=FRAME_DONE_LAT, bit2=SCCB_BUSY
//                         bit3=NA_ERR_LAT, bit4=FRAME_START_LAT
//   OFF 0x08  PIXEL   RO  마지막 유효 픽셀 RGB565 [15:0]
//   OFF 0x0C  FRAME   RO  [31:16]=line_cnt, [15:0]=frame_cnt
//   OFF 0xFC  ID_VER  RO  0x0006_0100 (ID=0x06, VER=0x01, REV=0x00)

`default_nettype none
module ov7670_sccb_top #(
    parameter CLK_HZ   = 100_000_000,
    parameter SCCB_KHZ = 100,
    parameter BASE_ADDR = 32'h1004_0000
)(
    // 시스템 버스
    input  wire        clk,
    input  wire        rst,
    // MMIO 슬레이브 (mmio-lite)
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        wen,
    input  wire        ren,
    output reg  [31:0] rdata,
    // SCCB 핀 (IO 패드에서 오픈 드레인으로 외부화)
    output wire        sio_c,
    output wire        sio_d_out,
    output wire        sio_d_oe,
    input  wire        sio_d_in,
    // 카메라 픽셀 버스
    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_d,
    // 디버그 (선택)
    output wire        dbg_cfg_done,
    output wire        dbg_frame_done
);
    // --- 설정 ROM (10 엔트리, 실제 OV7670 RGB565 최소 초기화) ---
    // {reg_addr[7:0], reg_data[7:0]}: 소프트 리셋 후 RGB565 모드
    localparam ROM_DEPTH = 10;
    reg [15:0] cfg_rom [0:ROM_DEPTH-1];
    initial begin
        cfg_rom[0] = 16'h1280; // COM7: SCCB 리셋
        cfg_rom[1] = 16'h1204; // COM7: RGB565 출력
        cfg_rom[2] = 16'h40D0; // COM15: RGB565 범위 0x00-0xFF
        cfg_rom[3] = 16'h3A04; // TSLB: YUYV 순서 (RGB565에서 무시)
        cfg_rom[4] = 16'h1714; // HSTART: 수평 시작
        cfg_rom[5] = 16'h1802; // HSTOP: 수평 끝
        cfg_rom[6] = 16'h3200; // HREF: 수평 가장자리
        cfg_rom[7] = 16'h1903; // VSTART: 수직 시작
        cfg_rom[8] = 16'h1A7B; // VSTOP: 수직 끝
        cfg_rom[9] = 16'h030A; // VREF: 수직 가장자리
    end

    // --- 제어 레지스터 ---
    reg        ctrl_start;      // 1클럭 펄스 (CTRL bit0)
    reg        ctrl_cap_en;     // 캡처 활성화 (CTRL bit1)
    reg        status_cfg_done;
    reg        status_frame_done_lat;
    reg        status_na_err_lat;
    reg        status_frame_start_lat;
    reg [15:0] last_pixel;
    reg [15:0] frame_cnt;

    // --- ROM 순차 송신 FSM ---
    reg  [3:0]  rom_ptr;
    reg         rom_running;
    wire        sccb_done;
    wire        sccb_na_err;
    reg         sccb_start_r;
    reg  [7:0]  sccb_reg_addr_r;
    reg  [7:0]  sccb_reg_data_r;
    localparam DEV_ADDR = 7'h21; // OV7670 write address

    sccb_tx #(.CLK_HZ(CLK_HZ), .SCCB_KHZ(SCCB_KHZ)) u_sccb (
        .clk(clk), .rst(rst),
        .start(sccb_start_r),
        .dev_addr(DEV_ADDR),
        .reg_addr(sccb_reg_addr_r),
        .reg_data(sccb_reg_data_r),
        .sio_c(sio_c),
        .sio_d_out(sio_d_out),
        .sio_d_oe(sio_d_oe),
        .sio_d_in(sio_d_in),
        .done(sccb_done),
        .na_err(sccb_na_err)
    );

    // ROM FSM
    always @(posedge clk) begin
        if (rst) begin
            rom_ptr         <= 4'd0;
            rom_running     <= 1'b0;
            status_cfg_done <= 1'b0;
            sccb_start_r    <= 1'b0;
            status_na_err_lat <= 1'b0;
        end else begin
            sccb_start_r <= 1'b0;
            if (sccb_na_err) status_na_err_lat <= 1'b1;
            if (ctrl_start && !rom_running && !status_cfg_done) begin
                rom_running     <= 1'b1;
                rom_ptr         <= 4'd0;
                status_cfg_done <= 1'b0;
                status_na_err_lat <= 1'b0;
                sccb_start_r    <= 1'b1;
                sccb_reg_addr_r <= cfg_rom[0][15:8];
                sccb_reg_data_r <= cfg_rom[0][7:0];
            end else if (rom_running && sccb_done) begin
                if (rom_ptr == ROM_DEPTH - 1) begin
                    rom_running     <= 1'b0;
                    status_cfg_done <= 1'b1;
                end else begin
                    rom_ptr         <= rom_ptr + 1;
                    sccb_start_r    <= 1'b1;
                    sccb_reg_addr_r <= cfg_rom[rom_ptr + 1][15:8];
                    sccb_reg_data_r <= cfg_rom[rom_ptr + 1][7:0];
                end
            end
        end
    end

    // --- 캡처 모듈 (PCLK 도메인) ---
    // capture_en을 PCLK 도메인으로 2-FF 동기화
    reg [1:0] cap_en_sync;
    always @(posedge cam_pclk) begin
        if (rst) cap_en_sync <= 2'b00;
        else     cap_en_sync <= {cap_en_sync[0], ctrl_cap_en};
    end

    wire [15:0] cap_pixel;
    wire        cap_pixel_valid;
    wire        cap_frame_start;
    wire        cap_frame_done;
    wire [15:0] cap_line_cnt;
    wire [15:0] cap_pixel_cnt;

    ov7670_capture u_cap (
        .pclk(cam_pclk),    .prst(rst),
        .vsync(cam_vsync),  .href(cam_href),
        .d(cam_d),
        .capture_en(cap_en_sync[1]),
        .pixel_data(cap_pixel),
        .pixel_valid(cap_pixel_valid),
        .frame_start(cap_frame_start),
        .frame_done(cap_frame_done),
        .line_cnt(cap_line_cnt),
        .pixel_cnt(cap_pixel_cnt)
    );

    // PCLK 신호를 시스템 클럭으로 교차
    wire sys_frame_done;
    wire sys_pixel_valid;
    wire sys_frame_start;

    sync_pulse u_sync_fd  (.src_clk(cam_pclk), .src_rst(rst), .src_pulse(cap_frame_done),
                            .dst_clk(clk),      .dst_rst(rst), .dst_pulse(sys_frame_done));
    sync_pulse u_sync_pv  (.src_clk(cam_pclk), .src_rst(rst), .src_pulse(cap_pixel_valid),
                            .dst_clk(clk),      .dst_rst(rst), .dst_pulse(sys_pixel_valid));
    sync_pulse u_sync_fs  (.src_clk(cam_pclk), .src_rst(rst), .src_pulse(cap_frame_start),
                            .dst_clk(clk),      .dst_rst(rst), .dst_pulse(sys_frame_start));

    // 픽셀/프레임 래치 (시스템 클럭 도메인)
    reg [15:0] cap_line_cnt_sys;
    always @(posedge clk) begin
        if (rst) begin
            last_pixel              <= 16'd0;
            frame_cnt               <= 16'd0;
            status_frame_done_lat   <= 1'b0;
            status_frame_start_lat  <= 1'b0;
            cap_line_cnt_sys        <= 16'd0;
        end else begin
            if (sys_pixel_valid) last_pixel <= cap_pixel;
            if (sys_frame_done) begin
                frame_cnt             <= frame_cnt + 1;
                status_frame_done_lat <= 1'b1;
                cap_line_cnt_sys      <= cap_line_cnt;
            end
            if (sys_frame_start) status_frame_start_lat <= 1'b1;
        end
    end

    // --- MMIO 슬레이브 ---
    wire [7:0] local_off = addr[7:0];

    always @(posedge clk) begin
        if (rst) begin
            ctrl_start  <= 1'b0;
            ctrl_cap_en <= 1'b0;
            rdata       <= 32'd0;
        end else begin
            ctrl_start <= 1'b0; // 자동 클리어
            if (wen && (addr[31:8] == BASE_ADDR[31:8])) begin
                case (local_off)
                    8'h00: begin // CTRL
                        ctrl_start  <= wdata[0];
                        ctrl_cap_en <= wdata[1];
                        if (wdata[15]) begin // RESET
                            status_cfg_done       <= 1'b0;
                            status_frame_done_lat <= 1'b0;
                            status_na_err_lat     <= 1'b0;
                        end
                    end
                    default: ;
                endcase
            end
            if (ren && (addr[31:8] == BASE_ADDR[31:8])) begin
                case (local_off)
                    8'h00: rdata <= 32'd0; // CTRL (WO)
                    8'h04: rdata <= {27'd0,
                                     status_frame_start_lat,
                                     status_na_err_lat,
                                     rom_running,
                                     status_frame_done_lat,
                                     status_cfg_done};
                    8'h08: rdata <= {16'd0, last_pixel};
                    8'h0C: rdata <= {cap_line_cnt_sys, frame_cnt};
                    8'hFC: rdata <= 32'h0006_0100; // ID=0x06 VER=0x01
                    default: rdata <= 32'hDEAD_BEEF;
                endcase
                // 상태 비트 클리어 (읽기 클리어)
                if (local_off == 8'h04) begin
                    status_frame_done_lat  <= 1'b0;
                    status_frame_start_lat <= 1'b0;
                end
            end
        end
    end

    assign dbg_cfg_done   = status_cfg_done;
    assign dbg_frame_done = sys_frame_done;
endmodule
`default_nettype wire
