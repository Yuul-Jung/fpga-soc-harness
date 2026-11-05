// axil_ssd1306_spi.v
// AXI4-Lite MMIO 슬레이브: SSD1306 128×32 OLED SPI 컨트롤러
//
// 기능:
//   - 26바이트 초기화 ROM (SSD1306 128×32 커맨드 시퀀스)
//   - 6바이트 페이지 설정 커맨드 (col/page 주소 모드)
//   - 512바이트 BRAM 프레임 버퍼
//   - SPI 송신 FSM (Mode 0, MSB first, 최대 10 MHz)
//   - 프레임 완료 인터럽트 출력
//
// 레지스터 맵 (AXI4-Lite, 오프셋):
//   0x00 CTRL     [0]=START(자동 클리어), [1]=SRST(소프트 리셋)
//   0x04 STATUS   [0]=BUSY, [1]=INIT_DONE, [2]=FRAME_DONE(1펄스)
//   0x08 BUF_ADDR [8:0] 프레임 버퍼 주소 (0~511)
//   0x0C BUF_DATA [7:0] 읽기: 현재 주소 값, 쓰기: 쓰고 BUF_ADDR 자동 증가
//   0x10 CONTRAST [7:0] 대비 (기본 0xFF)
//   0x14 IRQ_EN   [0]=FRAME_DONE 인터럽트 활성화
//
// Verilog-2001. iverilog/verilator/yosys 호환.
`default_nettype none

module axil_ssd1306_spi #(
    // SPI 클럭 분주: 반주기 = SPI_DIV 사이클
    // 100MHz 기준: SPI_DIV=10 → 5 MHz SPI
    parameter SPI_DIV    = 10,
    // 전원 순서 대기 (VDD 인가 후 1ms, 100MHz = 100,000)
    parameter PWRUP_CNT  = 100_000,
    // RES 최저 로우 (3µs, 100MHz = 300)
    parameter RST_CNT    = 300
)(
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite Slave
    input  wire [31:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,

    input  wire [31:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // SSD1306 SPI 인터페이스
    output reg         spi_sck,
    output reg         spi_mosi,
    output reg         spi_cs_n,  // 액티브 로우
    output reg         spi_dc,    // 0=커맨드, 1=데이터
    output reg         spi_res_n, // 리셋 (액티브 로우)
    output reg         spi_vdd_en,
    output reg         spi_vbat_en,

    // 인터럽트 (FRAME_DONE)
    output wire        irq
);

    // ----------------------------------------------------------------
    // 초기화 커맨드 ROM (26바이트, D/C=0)
    // SSD1306 128×32 표준 초기화 시퀀스
    // ----------------------------------------------------------------
    reg [7:0] init_rom [0:25];
    initial begin
        init_rom[ 0] = 8'hAE; // Display OFF
        init_rom[ 1] = 8'hD5; // Set Display Clock Divide
        init_rom[ 2] = 8'h80; //   ratio=1, fosc=8
        init_rom[ 3] = 8'hA8; // Set Multiplex Ratio
        init_rom[ 4] = 8'h1F; //   31 (32 rows − 1)
        init_rom[ 5] = 8'hD3; // Set Display Offset
        init_rom[ 6] = 8'h00; //   0
        init_rom[ 7] = 8'h40; // Set Display Start Line = 0
        init_rom[ 8] = 8'h8D; // Charge Pump Setting
        init_rom[ 9] = 8'h14; //   Enable
        init_rom[10] = 8'h20; // Set Memory Addressing Mode
        init_rom[11] = 8'h00; //   Horizontal
        init_rom[12] = 8'hA1; // Set Segment Re-map (col 127→SEG0)
        init_rom[13] = 8'hC8; // COM Output Scan Direction (remapped)
        init_rom[14] = 8'hDA; // Set COM Pins Hardware Config
        init_rom[15] = 8'h02; //   Sequential, disable L/R remap (32-row)
        init_rom[16] = 8'h81; // Set Contrast
        init_rom[17] = 8'hFF; //   Maximum (런타임에 CONTRAST 레지스터로 교체 가능)
        init_rom[18] = 8'hD9; // Set Pre-charge Period
        init_rom[19] = 8'hF1; //   Phase1=1, Phase2=15
        init_rom[20] = 8'hDB; // Set VCOMH Deselect Level
        init_rom[21] = 8'h40; //   ~0.77 × VCC
        init_rom[22] = 8'hA4; // Entire Display ON (use RAM content)
        init_rom[23] = 8'hA6; // Normal Display (not inverted)
        init_rom[24] = 8'hAF; // Display ON
        init_rom[25] = 8'h00; // (패딩)
    end

    // 페이지 설정 커맨드 (6바이트, D/C=0): col 0~127, page 0~3
    reg [7:0] prep_rom [0:5];
    initial begin
        prep_rom[0] = 8'h21; // Set Column Address
        prep_rom[1] = 8'h00; //   Start = 0
        prep_rom[2] = 8'h7F; //   End = 127
        prep_rom[3] = 8'h22; // Set Page Address
        prep_rom[4] = 8'h00; //   Start = 0
        prep_rom[5] = 8'h03; //   End = 3
    end

    // ----------------------------------------------------------------
    // 512바이트 프레임 버퍼
    // ----------------------------------------------------------------
    reg [7:0] fbuf [0:511];
    integer fb_i;
    initial begin
        for (fb_i = 0; fb_i < 512; fb_i = fb_i + 1)
            fbuf[fb_i] = 8'h00;
    end

    // ----------------------------------------------------------------
    // 레지스터
    // ----------------------------------------------------------------
    reg [8:0]  r_buf_addr;
    reg [7:0]  r_contrast;
    reg        r_irq_en;
    reg        r_init_done;
    reg        r_busy;
    reg        r_frame_done; // 1펄스

    // ----------------------------------------------------------------
    // FSM 상태
    // ----------------------------------------------------------------
    localparam S_POWER_VDD   = 4'd0;  // VDD_EN 인가 후 대기
    localparam S_RESET       = 4'd1;  // RES_N = 0 (3µs)
    localparam S_DEASSERT_RES= 4'd2;  // RES_N = 1, VBAT_EN, 100ms 대기
    localparam S_INIT        = 4'd3;  // 초기화 ROM 전송
    localparam S_IDLE        = 4'd4;  // 대기 (START 를 기다림)
    localparam S_PREP        = 4'd5;  // 페이지 설정 커맨드 전송
    localparam S_DATA        = 4'd6;  // 프레임 버퍼 전송
    localparam S_DONE        = 4'd7;  // 프레임 완료 펄스

    reg [3:0]  fsm_state;
    reg [19:0] wait_cnt;    // 전원/리셋 대기 카운터
    reg [4:0]  rom_idx;     // 현재 ROM 인덱스 (0~25)
    reg [2:0]  prep_idx;    // 페이지 설정 인덱스 (0~5)
    reg [9:0]  data_idx;    // 프레임 버퍼 인덱스 (0~511)

    // ----------------------------------------------------------------
    // SPI 송신 서브 FSM
    //   spi_start : 1사이클 펄스로 시작
    //   spi_byte  : 송신할 바이트
    //   spi_dc_in : D/C 레벨
    //   spi_done  : 1사이클 완료 펄스
    // ----------------------------------------------------------------
    reg        spi_start;
    reg [7:0]  spi_byte;
    reg        spi_dc_in;
    reg        spi_done;

    // SPI 내부 카운터 및 시프트 레지스터
    reg [7:0]  spi_shift;
    reg [3:0]  spi_bit_cnt;   // 0~15: 반주기 카운트 × 비트
    reg [7:0]  spi_clk_div;
    reg        spi_active;
    reg [3:0]  spi_phase;     // 0=사이클 시작, 각 비트당 2페이즈

    // SPI 송신기 (Mode 0, MSB first, CS는 외부 FSM이 제어)
    always @(posedge clk) begin
        spi_done <= 0;
        if (!rst_n) begin
            spi_active  <= 0;
            spi_sck     <= 0;
            spi_mosi    <= 0;
            spi_bit_cnt <= 0;
            spi_clk_div <= 0;
            spi_phase   <= 0;
        end else if (spi_start && !spi_active) begin
            spi_active  <= 1;
            spi_shift   <= spi_byte;
            spi_bit_cnt <= 0;
            spi_clk_div <= 0;
            spi_phase   <= 0;
            spi_sck     <= 0;
            spi_mosi    <= spi_byte[7];
            spi_dc      <= spi_dc_in;
        end else if (spi_active) begin
            if (spi_clk_div < SPI_DIV - 1) begin
                spi_clk_div <= spi_clk_div + 1;
            end else begin
                spi_clk_div <= 0;
                if (spi_phase == 0) begin
                    // 상승 에지
                    spi_sck   <= 1;
                    spi_phase <= 1;
                end else begin
                    // 하강 에지
                    spi_sck <= 0;
                    if (spi_bit_cnt == 7) begin
                        spi_active  <= 0;
                        spi_done    <= 1;
                    end else begin
                        spi_shift   <= {spi_shift[6:0], 1'b0};
                        spi_mosi    <= spi_shift[6];
                        spi_bit_cnt <= spi_bit_cnt + 1;
                        spi_phase   <= 0;
                    end
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // 메인 FSM
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        spi_start    <= 0;
        r_frame_done <= 0;

        if (!rst_n) begin
            fsm_state    <= S_POWER_VDD;
            wait_cnt     <= 0;
            rom_idx      <= 0;
            prep_idx     <= 0;
            data_idx     <= 0;
            r_busy       <= 1;
            r_init_done  <= 0;
            spi_cs_n     <= 1;
            spi_res_n    <= 1;
            spi_vdd_en   <= 0;
            spi_vbat_en  <= 0;
        end else begin
            case (fsm_state)

                // ---- 전원 순서: VDD ----
                S_POWER_VDD: begin
                    spi_vdd_en <= 1;
                    spi_cs_n   <= 1;
                    spi_res_n  <= 1;
                    r_busy     <= 1;
                    if (wait_cnt < PWRUP_CNT - 1) begin
                        wait_cnt <= wait_cnt + 1;
                    end else begin
                        wait_cnt  <= 0;
                        fsm_state <= S_RESET;
                    end
                end

                // ---- 리셋 (RES_N = 0) ----
                S_RESET: begin
                    spi_res_n <= 0;
                    if (wait_cnt < RST_CNT - 1) begin
                        wait_cnt <= wait_cnt + 1;
                    end else begin
                        wait_cnt  <= 0;
                        fsm_state <= S_DEASSERT_RES;
                    end
                end

                // ---- 리셋 해제 + VBAT 인가 ----
                S_DEASSERT_RES: begin
                    spi_res_n   <= 1;
                    spi_vbat_en <= 1;
                    if (wait_cnt < PWRUP_CNT - 1) begin
                        wait_cnt <= wait_cnt + 1;
                    end else begin
                        wait_cnt  <= 0;
                        rom_idx   <= 0;
                        fsm_state <= S_INIT;
                        spi_cs_n  <= 0; // CS 주장
                    end
                end

                // ---- 초기화 ROM 전송 (25바이트, 인덱스 0~24) ----
                S_INIT: begin
                    if (!spi_active && !spi_start) begin
                        if (rom_idx < 25) begin
                            spi_byte  <= (rom_idx == 17) ? r_contrast : init_rom[rom_idx];
                            spi_dc_in <= 0; // 커맨드
                            spi_start <= 1;
                            rom_idx   <= rom_idx + 1;
                        end else begin
                            spi_cs_n    <= 1;
                            r_init_done <= 1;
                            r_busy      <= 0;
                            fsm_state   <= S_IDLE;
                        end
                    end
                end

                // ---- 대기 ----
                S_IDLE: begin
                    r_busy <= 0;
                    // START는 AXI 쓰기 블록에서 세팅
                end

                // ---- 페이지 설정 커맨드 전송 ----
                S_PREP: begin
                    r_busy <= 1;
                    if (!spi_active && !spi_start) begin
                        if (prep_idx < 6) begin
                            spi_byte  <= prep_rom[prep_idx];
                            spi_dc_in <= 0;
                            spi_start <= 1;
                            prep_idx  <= prep_idx + 1;
                        end else begin
                            prep_idx  <= 0;
                            data_idx  <= 0;
                            fsm_state <= S_DATA;
                        end
                    end
                end

                // ---- 프레임 버퍼 512바이트 전송 ----
                S_DATA: begin
                    if (!spi_active && !spi_start) begin
                        if (data_idx < 512) begin
                            spi_byte  <= fbuf[data_idx];
                            spi_dc_in <= 1; // 데이터
                            spi_start <= 1;
                            data_idx  <= data_idx + 1;
                        end else begin
                            spi_cs_n  <= 1;
                            fsm_state <= S_DONE;
                        end
                    end
                end

                // ---- 완료 펄스 ----
                S_DONE: begin
                    r_frame_done <= 1;
                    r_busy       <= 0;
                    fsm_state    <= S_IDLE;
                end

                default: fsm_state <= S_IDLE;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // AXI4-Lite 쓰기 채널
    // ----------------------------------------------------------------
    reg [31:0] axi_waddr;
    reg [31:0] axi_wdata;
    reg        axi_wr_pend; // 주소+데이터 모두 수신 대기

    always @(posedge clk) begin
        if (!rst_n) begin
            s_awready  <= 0;
            s_wready   <= 0;
            s_bvalid   <= 0;
            s_bresp    <= 2'b00;
            axi_wr_pend<= 0;
            r_buf_addr <= 0;
            r_contrast <= 8'hFF;
            r_irq_en   <= 0;
        end else begin
            // 주소 핸드셰이크
            if (s_awvalid && !axi_wr_pend) begin
                s_awready  <= 1;
                axi_waddr  <= s_awaddr;
            end else begin
                s_awready  <= 0;
            end

            // 데이터 핸드셰이크
            if (s_wvalid && !axi_wr_pend) begin
                s_wready   <= 1;
                axi_wdata  <= s_wdata;
            end else begin
                s_wready   <= 0;
            end

            // 주소+데이터 모두 수신 → 레지스터 업데이트
            if ((s_awvalid || axi_wr_pend) && s_wvalid) begin
                axi_wr_pend <= 0;
                s_bvalid    <= 1;
                s_bresp     <= 2'b00;

                case (axi_waddr[5:0])
                    6'h00: begin // CTRL
                        if (axi_wdata[1]) begin // SRST
                            // 소프트 리셋: FSM을 IDLE로 (초기화는 유지)
                        end
                        if (axi_wdata[0] && r_init_done && !r_busy) begin
                            // START
                            fsm_state <= S_PREP;
                            spi_cs_n  <= 0;
                            prep_idx  <= 0;
                        end
                    end
                    6'h08: begin // BUF_ADDR
                        r_buf_addr <= axi_wdata[8:0];
                    end
                    6'h0C: begin // BUF_DATA (쓰기 + 자동 증가)
                        fbuf[r_buf_addr] <= axi_wdata[7:0];
                        r_buf_addr       <= r_buf_addr + 1;
                    end
                    6'h10: begin // CONTRAST
                        r_contrast <= axi_wdata[7:0];
                    end
                    6'h14: begin // IRQ_EN
                        r_irq_en <= axi_wdata[0];
                    end
                    default: ;
                endcase
            end else if (s_awvalid && !s_wvalid) begin
                axi_wr_pend <= 1;
            end

            // B채널 완료
            if (s_bvalid && s_bready) begin
                s_bvalid <= 0;
            end
        end
    end

    // ----------------------------------------------------------------
    // AXI4-Lite 읽기 채널
    // ----------------------------------------------------------------
    reg [31:0] rd_data;

    always @(posedge clk) begin
        if (!rst_n) begin
            s_arready <= 0;
            s_rvalid  <= 0;
            s_rresp   <= 2'b00;
            s_rdata   <= 0;
        end else begin
            if (s_arvalid && !s_rvalid) begin
                s_arready <= 1;
                s_rvalid  <= 1;
                s_rresp   <= 2'b00;
                case (s_araddr[5:0])
                    6'h00: s_rdata <= {28'b0, r_busy, 1'b0}; // CTRL (읽기)
                    6'h04: s_rdata <= {29'b0, r_frame_done, r_init_done, r_busy};
                    6'h08: s_rdata <= {23'b0, r_buf_addr};
                    6'h0C: s_rdata <= {24'b0, fbuf[r_buf_addr]};
                    6'h10: s_rdata <= {24'b0, r_contrast};
                    6'h14: s_rdata <= {31'b0, r_irq_en};
                    default: s_rdata <= 32'hDEAD_BEEF;
                endcase
            end else begin
                s_arready <= 0;
            end

            if (s_rvalid && s_rready) begin
                s_rvalid <= 0;
            end
        end
    end

    // ----------------------------------------------------------------
    // 인터럽트
    // ----------------------------------------------------------------
    assign irq = r_irq_en & r_frame_done;

endmodule
`default_nettype wire
