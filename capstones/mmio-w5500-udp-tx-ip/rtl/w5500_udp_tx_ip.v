/* w5500_udp_tx_ip.v — W5500 SPI UDP 텔레메트리 TX MMIO IP
 * Origin: capstones/mmio-w5500-udp-tx-ip/rtl/w5500_udp_tx_ip.v
 * Verilog-2001. iverilog / verilator / yosys 호환.
 *
 * MMIO 레지스터 맵 (32-bit 워드, 바이트 주소):
 *   0x0000  CTRL   [0]=go(W1P) [1]=init(W1P) [10]=busy(RO)
 *                  [11]=err(RO) [13]=init_done(RO)
 *   0x0004  TX_LEN [5:0] = 송신 바이트 수 (1..64)
 *   0x0008  TX_DATA [7:0] = TX 버퍼에 한 바이트씩 적재 (쓰기 전용)
 *   0x000C  TX_PTR  [5:0] = 현재 TX 버퍼 적재 포인터 (읽기 전용)
 *   0xFFF0  IP_ID  = 32'h5735_5544 ("W5UD")
 *   0xFFF4  IP_VER = 32'h0000_0100
 *   0xFFF8  IRQ_STATUS [0]=tx_done (W1C)
 *   0xFFFC  IRQ_ENABLE [0]=tx_done_en
 *
 * go  비트(bit0) 쓰기: UDP 송신 시작 (init_done=1, busy=0일 때만 유효)
 * init 비트(bit1) 쓰기: W5500 초기화 시작 (busy=0일 때만 유효)
 * 초기화: ROM 10개 SPI 단일 바이트 커맨드 순차 송신 → init_done=1
 * 송신: TX 버퍼→W5500 TX 블록→Sn_TX_WR 갱신→SEND 커맨드→SENDOK 폴링
 * 완료: busy=0, irq (tx_done_en=1 시)
 *
 * SPI: MODE=0 (CPOL=0, CPHA=0). CLK_DIV = SCK 반주기 클럭 수.
 * W5500 프레임: [addr_hi, addr_lo, ctrl_byte, data...]
 *   ctrl_byte = {BlockSel[4:0], W/R, LenMode[1:0]}
 *   Common regs write: {5'h00,1,2'b00} = 8'h04
 *   Socket 0 regs write: {5'h01,1,2'b00} = 8'h0C
 *   Socket 0 regs read:  {5'h01,0,2'b00} = 8'h08
 *   Socket 0 TX buf write: {5'h03,1,2'b00} = 8'h1C
 */
`timescale 1ns/1ps
module w5500_udp_tx_ip #(
    parameter CLK_DIV = 500   /* SCK 반주기 클럭 수 (100MHz→100kHz:500) */
)(
    input  wire        clk,
    input  wire        rst_n,
    /* MMIO (mmio-lite: 단일 사이클) */
    input  wire [15:0] mmio_addr,
    input  wire [31:0] mmio_wdata,
    output reg  [31:0] mmio_rdata,
    input  wire        mmio_we,
    input  wire        mmio_cs,
    /* SPI (W5500) — MODE=0 오픈 드레인 아님 */
    output reg         spi_sck,
    output reg         spi_mosi,
    output reg         spi_csn,
    input  wire        spi_miso,
    /* 인터럽트 */
    output wire        irq
);

/* ===== MMIO 레지스터 ===== */
reg        r_busy, r_err, r_init_done;
reg  [5:0] r_tx_len;
reg  [7:0] r_tx_buf [0:63];   /* 64바이트 TX 버퍼 */
reg  [5:0] r_tx_ptr;           /* TX 버퍼 적재 포인터 */
reg        r_irq_st, r_irq_en;

assign irq = r_irq_st & r_irq_en;

/* ===== 초기화 ROM ===== */
/* {addr[15:0], ctrl[7:0], data[7:0]} — 32비트 엔트리 */
localparam ROM_DEPTH = 10;
reg [31:0] init_rom [0:ROM_DEPTH-1];
initial begin
    init_rom[0] = {16'h0000, 8'h04, 8'h80}; /* MR = RST */
    init_rom[1] = {16'h000F, 8'h04, 8'hC0}; /* SIPR[0]=192 */
    init_rom[2] = {16'h0010, 8'h04, 8'hA8}; /* SIPR[1]=168 */
    init_rom[3] = {16'h0011, 8'h04, 8'h01}; /* SIPR[2]=1   */
    init_rom[4] = {16'h0012, 8'h04, 8'h64}; /* SIPR[3]=100 */
    init_rom[5] = {16'h0001, 8'h04, 8'hC0}; /* GAR[0]=192  */
    init_rom[6] = {16'h0002, 8'h04, 8'hA8}; /* GAR[1]=168  */
    init_rom[7] = {16'h0000, 8'h0C, 8'h02}; /* S0_MR=UDP   */
    init_rom[8] = {16'h0004, 8'h0C, 8'h1F}; /* S0_PORT[0]  */
    init_rom[9] = {16'h0001, 8'h0C, 8'h01}; /* S0_CR=OPEN  */
end

/* ===== SPI 마스터 ===== */
/* MODE=0: SCK 아이들=0. MOSI 세팅→SCK↑(슬레이브 샘플)→SCK↓(다음 비트) */
localparam [11:0] SPI_HALF = CLK_DIV - 1;
reg [11:0] spi_div;    /* 반주기 카운터 */
reg  [2:0] spi_bst;    /* 현재 비트 (7→0) */
reg        spi_phase;  /* 0=SCK 로우, 1=SCK 하이 */
reg        spi_bsy;    /* 바이트 송수신 중 */
reg  [7:0] spi_sreg;   /* 송신 시프트 레지스터 */
reg  [7:0] spi_rx;     /* 수신 완료 바이트 */
reg        spi_kick;   /* 1클럭 펄스 → 바이트 송신 시작 */
reg        spi_done;   /* 1클럭 펄스 → 바이트 완료 */

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_sck  <= 1'b0; spi_mosi <= 1'b0;
        spi_div  <= 12'd0; spi_bst  <= 3'd7; spi_phase <= 1'b0;
        spi_bsy  <= 1'b0; spi_sreg <= 8'd0; spi_rx <= 8'd0;
        spi_done <= 1'b0;
    end else begin
        spi_done <= 1'b0;
        if (spi_kick && !spi_bsy) begin
            spi_bsy   <= 1'b1;
            spi_bst   <= 3'd7;
            spi_phase <= 1'b0;
            spi_div   <= 12'd0;
            spi_mosi  <= spi_sreg[7];  /* 첫 비트 출력 */
            spi_sck   <= 1'b0;
        end else if (spi_bsy) begin
            if (spi_div == SPI_HALF) begin
                spi_div <= 12'd0;
                if (spi_phase == 1'b0) begin
                    /* SCK 상승: 슬레이브가 MOSI 샘플, 마스터가 MISO 샘플 */
                    spi_sck   <= 1'b1;
                    spi_rx    <= {spi_rx[6:0], spi_miso};
                    spi_phase <= 1'b1;
                end else begin
                    /* SCK 하강: 다음 비트 출력 */
                    spi_sck   <= 1'b0;
                    spi_phase <= 1'b0;
                    if (spi_bst == 3'd0) begin
                        spi_bsy  <= 1'b0;
                        spi_done <= 1'b1;
                    end else begin
                        spi_bst  <= spi_bst - 3'd1;
                        spi_mosi <= spi_sreg[spi_bst - 3'd1];
                    end
                end
            end else begin
                spi_div <= spi_div + 12'd1;
            end
        end
    end
end

/* ===== 메인 FSM ===== */
localparam [3:0]
    S_IDLE      = 4'd0,
    S_ROM_FRAME = 4'd1,  /* 초기화 ROM 프레임 송신 */
    S_TX_BH     = 4'd2,  /* TX 버퍼 헤더 (3바이트) */
    S_TX_BD     = 4'd3,  /* TX 버퍼 데이터 */
    S_TX_WH     = 4'd4,  /* Sn_TX_WR 갱신 헤더 (3바이트) */
    S_TX_WD     = 4'd5,  /* Sn_TX_WR 갱신 데이터 (2바이트) */
    S_TX_SC     = 4'd6,  /* SEND 커맨드 (4바이트) */
    S_TX_PH     = 4'd7,  /* POLL Sn_IR 헤더 (3바이트) */
    S_TX_PD     = 4'd8,  /* POLL Sn_IR 데이터 (1바이트 수신) */
    S_DONE      = 4'd9,
    S_ERROR     = 4'd10;

reg  [3:0] state;
reg  [3:0] rom_idx;    /* ROM 항목 인덱스 (0..9) */
reg  [5:0] data_idx;   /* TX 데이터 인덱스 */
reg  [2:0] byte_idx;   /* 현재 프레임 내 바이트 인덱스 */
reg [15:0] tx_wr_ptr;  /* W5500 TX 쓰기 포인터 추적 */
reg [15:0] poll_cnt;   /* 폴링 타임아웃 카운터 */

/* go/init 펄스: CTRL 레지스터 bit0/bit1 쓰기, IDLE+!busy 시 유효 */
wire go_pulse   = mmio_cs && mmio_we &&
                  (mmio_addr[15:0] == 16'h0000) &&
                  mmio_wdata[0] && !r_busy && r_init_done;
wire init_pulse = mmio_cs && mmio_we &&
                  (mmio_addr[15:0] == 16'h0000) &&
                  mmio_wdata[1] && !r_busy;

always @(posedge clk or negedge rst_n) begin : main_fsm
    integer i;
    if (!rst_n) begin
        r_busy      <= 1'b0; r_err  <= 1'b0; r_init_done <= 1'b0;
        r_tx_len    <= 6'd0; r_tx_ptr <= 6'd0;
        r_irq_st    <= 1'b0; r_irq_en <= 1'b0;
        for (i = 0; i < 64; i = i + 1) r_tx_buf[i] <= 8'd0;
        state       <= S_IDLE;
        rom_idx     <= 4'd0; data_idx <= 6'd0; byte_idx <= 3'd0;
        tx_wr_ptr   <= 16'd0; poll_cnt <= 16'd0;
        spi_csn     <= 1'b1;  spi_kick  <= 1'b0; spi_sreg  <= 8'd0;
    end else begin
        spi_kick <= 1'b0;  /* default */

        /* ---- MMIO 쓰기 ---- */
        if (mmio_cs && mmio_we) begin
            case (mmio_addr[15:0])
                16'h0004: r_tx_len <= mmio_wdata[5:0];
                16'h0008: begin
                    r_tx_buf[r_tx_ptr] <= mmio_wdata[7:0];
                    if (r_tx_ptr != 6'd63) r_tx_ptr <= r_tx_ptr + 6'd1;
                end
                16'hFFF8: r_irq_st <= r_irq_st & ~mmio_wdata[0]; /* W1C */
                16'hFFFC: r_irq_en <= mmio_wdata[0];
                default: ;
            endcase
        end

        /* ---- FSM ---- */
        case (state)

            /* 유휴 */
            S_IDLE: begin
                spi_csn <= 1'b1;
                if (init_pulse) begin
                    r_busy   <= 1'b1; r_err <= 1'b0;
                    r_irq_st <= 1'b0;
                    rom_idx  <= 4'd0; byte_idx <= 3'd0;
                    tx_wr_ptr <= 16'd0;
                    state    <= S_ROM_FRAME;
                end else if (go_pulse) begin
                    r_busy   <= 1'b1; r_err <= 1'b0;
                    r_irq_st <= 1'b0;
                    r_tx_ptr <= 6'd0;  /* TX 버퍼 포인터 초기화 */
                    data_idx <= 6'd0; byte_idx <= 3'd0;
                    state    <= S_TX_BH;
                end
            end

            /* ---- 초기화 ROM 순회 ---- */
            /* 각 엔트리: CSn=0 → addr_hi → addr_lo → ctrl → data → CSn=1 */
            S_ROM_FRAME: begin
                if (!spi_bsy && !spi_kick) begin
                    case (byte_idx)
                        3'd0: begin  /* addr_hi */
                            spi_csn  <= 1'b0;
                            spi_sreg <= init_rom[rom_idx][31:24];
                            spi_kick <= 1'b1;
                            byte_idx <= 3'd1;
                        end
                        3'd1: begin  /* addr_lo */
                            if (spi_done) begin
                                spi_sreg <= init_rom[rom_idx][23:16];
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd2;
                            end
                        end
                        3'd2: begin  /* ctrl */
                            if (spi_done) begin
                                spi_sreg <= init_rom[rom_idx][15:8];
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd3;
                            end
                        end
                        3'd3: begin  /* data */
                            if (spi_done) begin
                                spi_sreg <= init_rom[rom_idx][7:0];
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd4;
                            end
                        end
                        3'd4: begin  /* 프레임 종료 대기 */
                            if (spi_done) begin
                                spi_csn <= 1'b1;
                                byte_idx <= 3'd0;
                                if (rom_idx == ROM_DEPTH - 1) begin
                                    /* 모든 ROM 완료 */
                                    r_init_done <= 1'b1;
                                    r_busy      <= 1'b0;
                                    state       <= S_IDLE;
                                end else begin
                                    rom_idx <= rom_idx + 4'd1;
                                end
                            end
                        end
                        default: byte_idx <= 3'd0;
                    endcase
                end
            end

            /* ---- TX 버퍼 → W5500 TX 블록 헤더 ---- */
            /* 3바이트: 0x00(addr_hi), 0x00(addr_lo), 0x1C(s0 TX buf write) */
            S_TX_BH: begin
                if (!spi_bsy && !spi_kick) begin
                    case (byte_idx)
                        3'd0: begin
                            spi_csn  <= 1'b0;
                            spi_sreg <= 8'h00;  /* TX 버퍼 주소 상위 */
                            spi_kick <= 1'b1;
                            byte_idx <= 3'd1;
                        end
                        3'd1: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h00;  /* TX 버퍼 주소 하위 */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd2;
                            end
                        end
                        3'd2: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h1C;  /* S0 TX buf, write */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd3;
                            end
                        end
                        3'd3: begin
                            if (spi_done) begin
                                byte_idx <= 3'd0;
                                data_idx <= 6'd0;
                                state    <= S_TX_BD;
                            end
                        end
                        default: byte_idx <= 3'd0;
                    endcase
                end
            end

            /* ---- TX 버퍼 데이터 (r_tx_len 바이트) ---- */
            S_TX_BD: begin
                if (!spi_bsy && !spi_kick) begin
                    if (data_idx < r_tx_len) begin
                        if (spi_done || data_idx == 6'd0) begin
                            spi_sreg <= r_tx_buf[data_idx];
                            spi_kick <= 1'b1;
                            data_idx <= data_idx + 6'd1;
                        end
                    end else begin
                        if (spi_done || r_tx_len == 6'd0) begin
                            spi_csn   <= 1'b1;
                            tx_wr_ptr <= tx_wr_ptr + {10'd0, r_tx_len};
                            byte_idx  <= 3'd0;
                            state     <= S_TX_WH;
                        end
                    end
                end
            end

            /* ---- Sn_TX_WR 갱신 헤더 (3바이트) ---- */
            /* Sn_TX_WR = socket 0 reg 0x0022 */
            S_TX_WH: begin
                if (!spi_bsy && !spi_kick) begin
                    case (byte_idx)
                        3'd0: begin
                            spi_csn  <= 1'b0;
                            spi_sreg <= 8'h00;  /* 0x0022 주소 상위 */
                            spi_kick <= 1'b1;
                            byte_idx <= 3'd1;
                        end
                        3'd1: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h22;  /* 0x0022 주소 하위 */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd2;
                            end
                        end
                        3'd2: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h0C;  /* S0 regs, write */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd3;
                            end
                        end
                        3'd3: begin
                            if (spi_done) begin
                                byte_idx <= 3'd0;
                                state    <= S_TX_WD;
                            end
                        end
                        default: byte_idx <= 3'd0;
                    endcase
                end
            end

            /* ---- Sn_TX_WR 갱신 데이터 (2바이트: ptr[15:8], ptr[7:0]) ---- */
            S_TX_WD: begin
                if (!spi_bsy && !spi_kick) begin
                    case (byte_idx)
                        3'd0: begin
                            spi_sreg <= tx_wr_ptr[15:8];
                            spi_kick <= 1'b1;
                            byte_idx <= 3'd1;
                        end
                        3'd1: begin
                            if (spi_done) begin
                                spi_sreg <= tx_wr_ptr[7:0];
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd2;
                            end
                        end
                        3'd2: begin
                            if (spi_done) begin
                                spi_csn  <= 1'b1;
                                byte_idx <= 3'd0;
                                state    <= S_TX_SC;
                            end
                        end
                        default: byte_idx <= 3'd0;
                    endcase
                end
            end

            /* ---- SEND 커맨드 (4바이트: 0x00,0x01,0x0C,0x20) ---- */
            /* Sn_CR at socket 0 reg 0x0001; SEND = 0x20 */
            S_TX_SC: begin
                if (!spi_bsy && !spi_kick) begin
                    case (byte_idx)
                        3'd0: begin
                            spi_csn  <= 1'b0;
                            spi_sreg <= 8'h00;
                            spi_kick <= 1'b1;
                            byte_idx <= 3'd1;
                        end
                        3'd1: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h01;
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd2;
                            end
                        end
                        3'd2: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h0C;  /* S0 regs, write */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd3;
                            end
                        end
                        3'd3: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h20;  /* SEND 커맨드 */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd4;
                            end
                        end
                        3'd4: begin
                            if (spi_done) begin
                                spi_csn  <= 1'b1;
                                byte_idx <= 3'd0;
                                poll_cnt <= 16'd0;
                                state    <= S_TX_PH;
                            end
                        end
                        default: byte_idx <= 3'd0;
                    endcase
                end
            end

            /* ---- Sn_IR 폴링 헤더 (3바이트) ---- */
            /* Sn_IR = socket 0 reg 0x0002, read */
            S_TX_PH: begin
                if (!spi_bsy && !spi_kick) begin
                    case (byte_idx)
                        3'd0: begin
                            spi_csn  <= 1'b0;
                            spi_sreg <= 8'h00;
                            spi_kick <= 1'b1;
                            byte_idx <= 3'd1;
                        end
                        3'd1: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h02;
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd2;
                            end
                        end
                        3'd2: begin
                            if (spi_done) begin
                                spi_sreg <= 8'h08;  /* S0 regs, read */
                                spi_kick <= 1'b1;
                                byte_idx <= 3'd3;
                            end
                        end
                        3'd3: begin
                            if (spi_done) begin
                                byte_idx <= 3'd0;
                                state    <= S_TX_PD;
                            end
                        end
                        default: byte_idx <= 3'd0;
                    endcase
                end
            end

            /* ---- Sn_IR 수신 (더미 TX 1바이트) ---- */
            S_TX_PD: begin
                if (!spi_bsy && !spi_kick) begin
                    if (byte_idx == 3'd0) begin
                        spi_sreg <= 8'h00;  /* 더미 */
                        spi_kick <= 1'b1;
                        byte_idx <= 3'd1;
                    end else if (byte_idx == 3'd1 && spi_done) begin
                        spi_csn  <= 1'b1;
                        byte_idx <= 3'd0;
                        if (spi_rx[4]) begin
                            /* SENDOK (bit4) 확인 */
                            state <= S_DONE;
                        end else if (poll_cnt == 16'hFFFF) begin
                            r_err <= 1'b1;
                            state <= S_ERROR;
                        end else begin
                            poll_cnt <= poll_cnt + 16'd1;
                            state    <= S_TX_PH;  /* 재폴링 */
                        end
                    end
                end
            end

            /* 완료 */
            S_DONE: begin
                r_busy   <= 1'b0;
                r_irq_st <= 1'b1;
                state    <= S_IDLE;
            end

            /* 오류 */
            S_ERROR: begin
                r_busy <= 1'b0;
                state  <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase
    end
end

/* ===== MMIO 읽기 (조합 논리) ===== */
always @(*) begin
    mmio_rdata = 32'd0;
    if (mmio_cs && !mmio_we) begin
        case (mmio_addr[15:0])
            16'h0000: mmio_rdata = {18'd0, r_init_done, 1'b0, r_err, r_busy, 8'd0};
            16'h0004: mmio_rdata = {26'd0, r_tx_len};
            16'h000C: mmio_rdata = {26'd0, r_tx_ptr};
            16'hFFF0: mmio_rdata = 32'h5735_5544; /* "W5UD" */
            16'hFFF4: mmio_rdata = 32'h0000_0100;
            16'hFFF8: mmio_rdata = {31'd0, r_irq_st};
            16'hFFFC: mmio_rdata = {31'd0, r_irq_en};
            default:  mmio_rdata = 32'd0;
        endcase
    end
end

endmodule
