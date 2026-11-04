`timescale 1ns/1ps
//=============================================================================
// sensor_hub_top.v — I2C 3장치 순회 + NMEA UART 수신 센서 허브 IP
// AXI4-Lite 슬레이브 (32-bit, 16-bit 주소)
//   - I2C 마스터: MPU-6050(0x68), BMP280(0x76), HMC5883L(0x1E) 순회, 1바이트씩
//   - NMEA UART RX: 9600-N-8-1, '$'~'\n' 까지 최대 90바이트 캡처
//   - 64비트 자유 주행 타임스탬프 + 16단계 샘플 FIFO
// Verilog-2001  iverilog/verilator/yosys 호환
//=============================================================================
module sensor_hub_top #(
    parameter integer CLK_HZ     = 100_000_000,
    parameter integer I2C_HZ     = 100_000,    // 100 kHz
    parameter integer BAUD       = 9600,
    parameter integer FIFO_DEPTH = 16           // 2의 거듭제곱
)(
    // AXI4-Lite 슬레이브
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [15:0] s_awaddr,
    input  wire        s_awvalid,
    output reg         s_awready,
    input  wire [31:0] s_wdata,
    input  wire [3:0]  s_wstrb,
    input  wire        s_wvalid,
    output reg         s_wready,
    output reg  [1:0]  s_bresp,
    output reg         s_bvalid,
    input  wire        s_bready,
    input  wire [15:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,
    // I2C 오픈드레인 (t=1: 릴리즈/풀업 위임)
    output reg         i2c_scl_o,
    output reg         i2c_scl_t,
    output reg         i2c_sda_o,
    output reg         i2c_sda_t,
    input  wire        i2c_sda_i,
    // NMEA UART RX 9600-N-8-1
    input  wire        uart_rx,
    // 인터럽트 (레벨, 액티브-하이)
    output wire        irq
);
    //=========================================================
    // 로컬 파라미터
    //=========================================================
    localparam integer I2C_HALF = (CLK_HZ / (2 * I2C_HZ)) - 1;
    localparam integer BAUD_CNT = (CLK_HZ / BAUD) - 1;
    localparam integer BAUD_MID = (CLK_HZ / BAUD) / 2 - 1;
    localparam integer FIFO_AW  = (FIFO_DEPTH == 2)  ? 1 :
                                   (FIFO_DEPTH == 4)  ? 2 :
                                   (FIFO_DEPTH == 8)  ? 3 :
                                   (FIFO_DEPTH == 16) ? 4 : 4;
    localparam integer NMEA_MAX = 89; // 90바이트, 인덱스 0-89

    // I2C 장치 주소 / 레지스터
    localparam [6:0] D0_ADDR = 7'h68; localparam [7:0] D0_REG = 8'h3B; // MPU-6050
    localparam [6:0] D1_ADDR = 7'h76; localparam [7:0] D1_REG = 8'hF7; // BMP280
    localparam [6:0] D2_ADDR = 7'h1E; localparam [7:0] D2_REG = 8'h03; // HMC5883L

    // AXI4-Lite 레지스터 오프셋
    localparam [15:0] A_CTRL   = 16'h0000, A_STAT   = 16'h0004,
                      A_FDATA  = 16'h0008, A_FMETA  = 16'h000C,
                      A_NLEN   = 16'h0010, A_NBYTE  = 16'h0014,
                      A_TSHI   = 16'h0018, A_TSLO   = 16'h001C,
                      A_IP_ID  = 16'hFFF0, A_IP_VER = 16'hFFF4,
                      A_IRQS   = 16'hFFF8, A_IRQEN  = 16'hFFFC;

    // AXI4-Lite: WSTRB=0xF 전용(§bus_protocol), s_wdata 상위비트 미사용 — lint 억제
    /* verilator lint_off UNUSEDSIGNAL */
    wire _unused_ok = &{1'b0, s_wstrb, s_wdata[31:3]};
    /* verilator lint_on UNUSEDSIGNAL */

    //=========================================================
    // 제어 / 인터럽트 레지스터
    //=========================================================
    reg        ctrl_scan_en, ctrl_fifo_rst, ctrl_nmea_en;
    reg  [1:0] irq_en, irq_stat;

    //=========================================================
    // 64비트 타임스탬프
    //=========================================================
    reg [63:0] ts_ctr;
    reg [31:0] ts_latch;   // TS_HI 읽을 때 ts_ctr[31:0] 래치; ts_ctr[63:32]는 직접 반환
    always @(posedge aclk) begin
        if (!aresetn) ts_ctr <= 64'd0;
        else          ts_ctr <= ts_ctr + 64'd1;
    end

    //=========================================================
    // 샘플 FIFO (16단계 × 32비트)
    //=========================================================
    reg [31:0] fifo_d [0:FIFO_DEPTH-1];
    reg [31:0] fifo_m [0:FIFO_DEPTH-1];
    reg [FIFO_AW:0] fifo_wp, fifo_rp;
    wire fifo_empty = (fifo_wp == fifo_rp);
    wire fifo_full  = (fifo_wp[FIFO_AW-1:0] == fifo_rp[FIFO_AW-1:0]) &&
                      (fifo_wp[FIFO_AW]     != fifo_rp[FIFO_AW]);
    reg [31:0] rd_meta_lat;

    always @(posedge aclk) begin
        if (!aresetn || ctrl_fifo_rst) begin
            fifo_wp <= 0; fifo_rp <= 0;
        end
    end

    //=========================================================
    // NMEA 버퍼 (90바이트)
    //=========================================================
    reg [7:0]  nmea_buf [0:NMEA_MAX];
    reg [6:0]  nmea_wp, nmea_rp, nmea_len;
    reg        nmea_cap, nmea_line_rdy;

    //=========================================================
    // UART RX (9600-N-8-1)
    //=========================================================
    reg [20:0] uart_div;
    reg [3:0]  uart_bcnt;
    reg [7:0]  uart_shift;
    reg        uart_rx1, uart_rx2;
    reg        uart_active, uart_byte_rdy;
    reg [7:0]  uart_byte;

    always @(posedge aclk) begin  // 2단 플립플롭 동기화
        uart_rx1 <= uart_rx;
        uart_rx2 <= uart_rx1;
    end

    always @(posedge aclk) begin
        uart_byte_rdy <= 1'b0;
        if (!aresetn) begin
            uart_active <= 1'b0; uart_div <= 21'd0; uart_bcnt <= 4'd0;
        end else if (!uart_active) begin
            if (!uart_rx2) begin           // 스타트 비트 하강 엣지
                uart_active <= 1'b1;
                uart_div    <= BAUD_MID + BAUD_CNT + 1; // 스타트 비트 중간을 건너뛰어 데이터 비트0 중간부터 샘플링
                uart_bcnt   <= 4'd0;
            end
        end else begin
            if (uart_div == 21'd0) begin
                uart_div <= BAUD_CNT;
                if (uart_bcnt < 4'd8) begin
                    uart_shift <= {uart_rx2, uart_shift[7:1]};
                    uart_bcnt  <= uart_bcnt + 4'd1;
                end else begin
                    uart_active   <= 1'b0;
                    uart_byte_rdy <= uart_rx2; // 스톱 비트 확인
                    uart_byte     <= uart_shift;
                end
            end else begin
                uart_div <= uart_div - 21'd1;
            end
        end
    end

    // NMEA 캡처
    always @(posedge aclk) begin
        if (!aresetn || !ctrl_nmea_en) begin
            nmea_wp <= 7'd0; nmea_rp <= 7'd0; nmea_len <= 7'd0;
            nmea_cap <= 1'b0; nmea_line_rdy <= 1'b0;
        end else begin
            if (uart_byte_rdy) begin
                if (uart_byte == 8'h24) begin          // '$' : 시작
                    nmea_cap <= 1'b1; nmea_wp <= 7'd0; nmea_line_rdy <= 1'b0;
                end else if (nmea_cap) begin
                    if (uart_byte == 8'h0A) begin      // '\n' : 완성
                        nmea_len       <= nmea_wp;
                        nmea_cap       <= 1'b0;
                        nmea_line_rdy  <= 1'b1;
                        irq_stat[1]    <= 1'b1;
                    end else if (nmea_wp <= NMEA_MAX) begin
                        nmea_buf[nmea_wp] <= uart_byte;
                        nmea_wp           <= nmea_wp + 7'd1;
                    end
                end
            end else if (!irq_stat[1]) begin
                // irq_stat[1] cleared by W1C → lower nmea_line_rdy
                // must be else-if so the '\n'-receive set is not overridden
                // by this clear in the same clock (NBA last-wins anti-pattern)
                nmea_line_rdy <= 1'b0;
            end
        end
    end

    //=========================================================
    // I2C 마스터 — 단계(step) 기반 상태 기계
    // 한 장치당 82 step (각 step = I2C_HALF 사이클)
    //  0     : IDLE
    //  1     : START (SDA LOW while SCL HIGH)
    //  2     : SCL LOW (START 후 첫 SCL↓)
    //  3-20  : ADDR+W 8비트 (짝=SCL↓+SDA, 홀=SCL↑) + ACK(20=SCL↓, 21=SCL↑)
    //  22-39 : REG 8비트 + ACK(38=SCL↓, 39=SCL↑)
    //  40-43 : RPSTART (40=SCL↑, 41=SDA↑, 42=SDA↓, 43=SCL↓)
    //  44-61 : ADDR+R 8비트 + ACK(60=SCL↓, 61=SCL↑)
    //  62-79 : DATA 8비트 + NACK(78=SCL↓, 79=SCL↑)
    //  80    : STOP (SCL↑)
    //  81    : STOP2 (SDA↑ while SCL↑ → STOP 완성)
    //  82+   : GAP (장치 간 대기, 별도 카운터)
    //=========================================================
    localparam [6:0] STEP_MAX = 7'd81;

    reg [6:0]  i2c_step;    // 현재 단계 (0-81)
    reg [20:0] i2c_div;     // 반주기 카운터
    reg        i2c_busy;
    reg [1:0]  i2c_dev;     // 현재 장치 (0,1,2)
    reg [7:0]  i2c_snd;     // 송신 시프트
    reg [7:0]  i2c_rcv;     // 수신 시프트
    reg [6:0]  i2c_cur_addr;
    reg [7:0]  i2c_cur_reg;

    // 장치 선택
    function [6:0] dev_addr;
        input [1:0] d;
        case (d) 2'd0: dev_addr=D0_ADDR; 2'd1: dev_addr=D1_ADDR;
                 default: dev_addr=D2_ADDR; endcase
    endfunction
    function [7:0] dev_reg;
        input [1:0] d;
        case (d) 2'd0: dev_reg=D0_REG; 2'd1: dev_reg=D1_REG;
                 default: dev_reg=D2_REG; endcase
    endfunction

    // 단계 경계 플래그
    wire i2c_tick = (i2c_div == 21'd0);

    // 단계 내 bit 위치 (3-20, 22-39, 44-61, 62-79) — bit[0]만 사용
    /* verilator lint_off UNUSEDSIGNAL */
    wire [4:0] bit_in_snd1 = (i2c_step - 7'd3);   // ADDR+W  비트 위치
    wire [4:0] bit_in_snd2 = (i2c_step - 7'd22);  // REG     비트 위치
    wire [4:0] bit_in_snd3 = (i2c_step - 7'd44);  // ADDR+R  비트 위치
    wire [4:0] bit_in_rcv  = (i2c_step - 7'd62);  // DATA    비트 위치
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge aclk) begin
        if (!aresetn || !ctrl_scan_en) begin
            i2c_step  <= 7'd0; i2c_div  <= I2C_HALF[20:0];
            i2c_scl_o <= 1'b1; i2c_scl_t <= 1'b1;
            i2c_sda_o <= 1'b1; i2c_sda_t <= 1'b1;
            i2c_busy  <= 1'b0; i2c_dev   <= 2'd0;
        end else begin
            // 반주기 카운터
            if (i2c_div == 21'd0) i2c_div <= I2C_HALF[20:0];
            else                  i2c_div  <= i2c_div - 21'd1;

            if (i2c_step == 7'd0) begin
                // ---- IDLE ----
                i2c_scl_o <= 1'b1; i2c_scl_t <= 1'b1;
                i2c_sda_o <= 1'b1; i2c_sda_t <= 1'b1;
                i2c_busy  <= 1'b0;
                if (i2c_tick) begin
                    i2c_cur_addr <= dev_addr(i2c_dev);
                    i2c_cur_reg  <= dev_reg(i2c_dev);
                    i2c_snd      <= {dev_addr(i2c_dev), 1'b0}; // ADDR+W
                    i2c_busy     <= 1'b1;
                    i2c_step     <= 7'd1;
                end
            end else if (i2c_step == 7'd1) begin
                // ---- START: SDA↓ (SCL HIGH 중) ----
                i2c_scl_o <= 1'b1; i2c_scl_t <= 1'b0;
                i2c_sda_o <= 1'b0; i2c_sda_t <= 1'b0;
                if (i2c_tick) i2c_step <= 7'd2;
            end else if (i2c_step == 7'd2) begin
                // ---- SCL↓ (START 완성 후) ----
                i2c_scl_o <= 1'b0; i2c_scl_t <= 1'b0;
                if (i2c_tick) begin
                    i2c_step <= 7'd3;
                    i2c_snd  <= {i2c_cur_addr, 1'b0}; // ADDR+W 준비
                end

            // ---- ADDR+W: 단계 3-20 ----
            // step 3,5,7,...,17 (짝수 오프셋): SCL↓, SDA=bit
            // step 4,6,8,...,18 (홀수 오프셋): SCL↑
            // step 19: SCL↓ + SDA 릴리즈 (ACK 대기)
            // step 20: SCL↑ (ACK 샘플)
            end else if (i2c_step >= 7'd3 && i2c_step <= 7'd20 && i2c_tick) begin
                if (i2c_step <= 7'd18 && !bit_in_snd1[0]) begin
                    // 짝수: SCL↓, 비트 출력
                    i2c_scl_o <= 1'b0;
                    i2c_sda_o <= i2c_snd[7]; i2c_sda_t <= 1'b0;
                    i2c_snd   <= {i2c_snd[6:0], 1'b0};
                end else if (i2c_step <= 7'd19 && bit_in_snd1[0]) begin
                    // 홀수: SCL↑
                    i2c_scl_o <= 1'b1;
                end else if (i2c_step == 7'd19) begin
                    // ACK 준비: SCL↓, 릴리즈 SDA
                    i2c_scl_o <= 1'b0; i2c_sda_t <= 1'b1;
                end else begin
                    // step 20: SCL↑ (ACK 샘플)
                    i2c_scl_o <= 1'b1;
                end
                if (i2c_tick) i2c_step <= i2c_step + 7'd1;

            // ---- REG: 단계 21-39 ----
            end else if (i2c_step >= 7'd21 && i2c_step <= 7'd39 && i2c_tick) begin
                if (i2c_step == 7'd21) begin
                    i2c_scl_o <= 1'b0;
                    i2c_snd   <= i2c_cur_reg;  // REG 주소 준비
                end else if (i2c_step <= 7'd37 && !bit_in_snd2[0]) begin
                    i2c_scl_o <= 1'b0;
                    i2c_sda_o <= i2c_snd[7]; i2c_sda_t <= 1'b0;
                    i2c_snd   <= {i2c_snd[6:0], 1'b0};
                end else if (i2c_step <= 7'd37 && bit_in_snd2[0]) begin
                    i2c_scl_o <= 1'b1;
                end else if (i2c_step == 7'd38) begin
                    i2c_scl_o <= 1'b0; i2c_sda_t <= 1'b1; // ACK 대기
                end else begin // 39
                    i2c_scl_o <= 1'b1;
                end
                i2c_step <= i2c_step + 7'd1;

            // ---- RPSTART: 단계 40-43 ----
            end else if (i2c_step >= 7'd40 && i2c_step <= 7'd43 && i2c_tick) begin
                case (i2c_step)
                    7'd40: begin i2c_scl_o<=1'b0; end                    // SCL↓
                    7'd41: begin i2c_scl_o<=1'b1; i2c_sda_o<=1'b1; end  // SCL↑, SDA↑
                    7'd42: begin i2c_sda_o<=1'b0; i2c_sda_t<=1'b0;     // SDA↓ (RPSTART)
                                 i2c_snd<={i2c_cur_addr,1'b1}; end       // ADDR+R 준비
                    7'd43: begin i2c_scl_o<=1'b0; end                    // SCL↓
                    default: ;
                endcase
                i2c_step <= i2c_step + 7'd1;

            // ---- ADDR+R: 단계 44-61 ----
            end else if (i2c_step >= 7'd44 && i2c_step <= 7'd61 && i2c_tick) begin
                if (i2c_step <= 7'd59 && !bit_in_snd3[0]) begin
                    i2c_scl_o <= 1'b0;
                    i2c_sda_o <= i2c_snd[7]; i2c_sda_t <= 1'b0;
                    i2c_snd   <= {i2c_snd[6:0], 1'b0};
                end else if (i2c_step <= 7'd59 && bit_in_snd3[0]) begin
                    i2c_scl_o <= 1'b1;
                end else if (i2c_step == 7'd60) begin
                    i2c_scl_o <= 1'b0; i2c_sda_t <= 1'b1;
                end else begin // 61
                    i2c_scl_o <= 1'b1;
                end
                i2c_step <= i2c_step + 7'd1;

            // ---- DATA 수신: 단계 62-79 ----
            end else if (i2c_step >= 7'd62 && i2c_step <= 7'd79 && i2c_tick) begin
                if (i2c_step <= 7'd77 && !bit_in_rcv[0]) begin
                    i2c_scl_o <= 1'b0; i2c_sda_t <= 1'b1; // 릴리즈
                end else if (i2c_step <= 7'd77 && bit_in_rcv[0]) begin
                    i2c_scl_o <= 1'b1;
                    i2c_rcv   <= {i2c_rcv[6:0], i2c_sda_i}; // 수신
                end else if (i2c_step == 7'd78) begin
                    i2c_scl_o <= 1'b0;
                    i2c_sda_o <= 1'b1; i2c_sda_t <= 1'b0; // NACK
                end else begin // 79
                    i2c_scl_o <= 1'b1;
                end
                i2c_step <= i2c_step + 7'd1;

            // ---- STOP: 단계 80-81 ----
            end else if (i2c_step == 7'd80 && i2c_tick) begin
                i2c_scl_o <= 1'b1; i2c_sda_o <= 1'b0; i2c_sda_t <= 1'b0;
                i2c_step  <= 7'd81;
            end else if (i2c_step == 7'd81 && i2c_tick) begin
                i2c_sda_o <= 1'b1; i2c_sda_t <= 1'b1; // STOP 완성
                // FIFO 쓰기
                if (!fifo_full) begin
                    fifo_d[fifo_wp[FIFO_AW-1:0]] <= {24'd0, i2c_rcv};
                    fifo_m[fifo_wp[FIFO_AW-1:0]] <=
                        {ts_ctr[15:0], 5'd0, i2c_dev, i2c_cur_reg, i2c_rcv};
                    fifo_wp    <= fifo_wp + 1;
                    irq_stat[0]<= 1'b1;
                end
                i2c_dev  <= (i2c_dev == 2'd2) ? 2'd0 : i2c_dev + 2'd1;
                i2c_step <= 7'd0;
            end else if (i2c_step > STEP_MAX) begin
                i2c_step <= 7'd0; // 안전 복귀
            end
        end
    end

    assign irq = |(irq_stat & irq_en);

    //=========================================================
    // AXI4-Lite 슬레이브
    //=========================================================
    reg [15:0] wr_addr_lat, rd_addr_lat;

    // 쓰기
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_awready <= 0; s_wready <= 0; s_bvalid <= 0; s_bresp <= 0;
            ctrl_scan_en <= 0; ctrl_fifo_rst <= 0; ctrl_nmea_en <= 0;
            irq_en <= 2'b00;
        end else begin
            ctrl_fifo_rst <= 1'b0;
            s_awready <= 0; s_wready <= 0;
            if (!s_awready && s_awvalid) begin
                s_awready <= 1'b1; wr_addr_lat <= s_awaddr;
            end
            if (!s_wready && s_wvalid) s_wready <= 1'b1;
            if (s_awready && s_awvalid && s_wready && s_wvalid) begin
                case (wr_addr_lat)
                    A_CTRL:  begin ctrl_scan_en<=s_wdata[0]; ctrl_fifo_rst<=s_wdata[1];
                                   ctrl_nmea_en<=s_wdata[2]; end
                    A_IRQS:  irq_stat <= irq_stat & ~s_wdata[1:0];
                    A_IRQEN: irq_en   <= s_wdata[1:0];
                    default: ;
                endcase
                s_bvalid <= 1'b1; s_bresp <= 2'b00;
            end
            if (s_bvalid && s_bready) s_bvalid <= 1'b0;
        end
    end

    // 읽기
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_arready <= 0; s_rvalid <= 0; s_rdata <= 0; s_rresp <= 0;
            nmea_rp <= 7'd0;
        end else begin
            s_arready <= 0;
            if (!s_arready && s_arvalid) begin
                s_arready <= 1'b1; rd_addr_lat <= s_araddr;
            end
            if (s_arready && s_arvalid && !s_rvalid) begin
                s_rvalid <= 1'b1; s_rresp <= 2'b00;
                case (rd_addr_lat)
                    A_CTRL:  s_rdata <= {29'd0,ctrl_nmea_en,ctrl_fifo_rst,ctrl_scan_en};
                    A_STAT:  s_rdata <= {28'd0,nmea_line_rdy,i2c_busy,fifo_full,fifo_empty};
                    A_FDATA: begin
                        if (!fifo_empty) begin
                            s_rdata     <= fifo_d[fifo_rp[FIFO_AW-1:0]];
                            rd_meta_lat <= fifo_m[fifo_rp[FIFO_AW-1:0]];
                            fifo_rp <= fifo_rp + 1;
                        end else begin
                            s_rdata <= 32'd0;
                        end
                    end
                    A_FMETA: s_rdata <= rd_meta_lat;
                    A_NLEN:  s_rdata <= {25'd0, nmea_len};
                    A_NBYTE: begin
                        s_rdata <= {24'd0, nmea_buf[nmea_rp]};
                        if (nmea_rp < nmea_len) nmea_rp <= nmea_rp + 7'd1;
                    end
                    A_TSHI:  begin ts_latch <= ts_ctr[31:0]; s_rdata <= ts_ctr[63:32]; end
                    A_TSLO:  s_rdata <= ts_latch[31:0];
                    A_IP_ID: s_rdata <= 32'h534E5348;
                    A_IP_VER:s_rdata <= 32'h0000_0100;
                    A_IRQS:  s_rdata <= {30'd0, irq_stat};
                    A_IRQEN: s_rdata <= {30'd0, irq_en};
                    default: s_rdata <= 32'hDEAD_BEEF;
                endcase
            end
            if (s_rvalid && s_rready) s_rvalid <= 1'b0;
        end
    end

endmodule
