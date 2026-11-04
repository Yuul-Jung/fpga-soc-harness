/* i2c_master_ip.v — CTRL/DATA I2C Master MMIO IP
 * Origin: capstones/mmio-i2c-master-ip/rtl/i2c_master_ip.v
 * Verilog-2001. iverilog / verilator / yosys 호환.
 *
 * MMIO 레지스터 맵 (32-bit 워드, 바이트 주소):
 *   0x0000  CTRL  [6:0]=addr  [7]=rnw  [8]=go(W,SC)  [9]=stop  [10]=busy(RO)  [11]=nak(RO)
 *   0x0004  DATA  [7:0]=tx_data(W) / rx_data(R)
 *   0xFFF0  IP_ID      = 32'h4932_434D  ("I2CM")
 *   0xFFF4  IP_VER     = 32'h0000_0100
 *   0xFFF8  IRQ_STATUS [0]=done  (W1C)
 *   0xFFFC  IRQ_ENABLE [0]=done_en
 *
 * go 비트(bit8) 쓰기 → 트랜잭션 시작, 자동 소거(self-clearing)
 * 트랜잭션 완료: busy=0, irq (done_en=1일 때)
 * 한 번 GO에 1바이트 송신(rnw=0) 또는 1바이트 수신(rnw=1)
 */
module i2c_master_ip #(
    parameter CLK_DIV = 1000  /* I2C 비트 주기 (클럭 사이클). 100MHz→100kHz=1000 */
)(
    input  wire        clk,
    input  wire        rst_n,
    /* MMIO (mmio-lite: 단일 사이클, word-addr 호환) */
    input  wire [15:0] mmio_addr,
    input  wire [31:0] mmio_wdata,
    output reg  [31:0] mmio_rdata,
    input  wire        mmio_we,
    input  wire        mmio_cs,
    /* I2C 오픈드레인 (0=로우 구동, 1=릴리즈/Hi-Z) */
    output reg         scl_o,
    output reg         sda_o,
    input  wire        sda_i,
    /* 인터럽트 */
    output wire        irq
);

/* ===== 레지스터 ===== */
reg [6:0] r_addr;    /* I2C 슬레이브 주소 */
reg       r_rnw;     /* 0=쓰기, 1=읽기 */
reg       r_stop;    /* STOP 조건 추가 여부 */
reg       r_busy;
reg       r_nak;
reg [7:0] r_wdat;    /* TX 데이터 */
reg [7:0] r_rdat;    /* RX 데이터 */
reg       r_irq_st;  /* IRQ 상태: done */
reg       r_irq_en;  /* IRQ 활성화 */

/* ===== FSM 상태 ===== */
localparam [3:0]
    S_IDLE    = 4'd0, S_START   = 4'd1,
    S_ADDR    = 4'd2, S_ADDR_AK = 4'd3,
    S_TX      = 4'd4, S_TX_AK   = 4'd5,
    S_RX      = 4'd6, S_RX_NAK  = 4'd7,
    S_STOP    = 4'd8, S_DONE    = 4'd9;

reg  [3:0] state;
reg [11:0] pcnt;    /* 비트 내 위상 카운터 (0 .. CLK_DIV-1) */
reg  [2:0] bcnt;    /* 비트 카운터 (7 .. 0) */
reg  [7:0] shift;   /* 송수신 시프트 레지스터 */

/* 위상 타이밍 */
localparam [11:0] P_END = CLK_DIV - 1;
localparam [11:0] P_Q1  = CLK_DIV / 4;        /* SCL 상승 */
localparam [11:0] P_H   = CLK_DIV / 2;        /* 샘플 / SCL 중간 */
localparam [11:0] P_Q3  = (CLK_DIV * 3) / 4;  /* SCL 하강 */

wire p_end = (pcnt == P_END);
wire p_q1  = (pcnt == P_Q1);
wire p_h   = (pcnt == P_H);
wire p_q3  = (pcnt == P_Q3);

/* go 펄스: CTRL 레지스터 bit8 쓰기 (IDLE 상태에서만 유효) */
wire go_pulse = mmio_cs && mmio_we &&
                (mmio_addr[15:0] == 16'h0000) &&
                mmio_wdata[8] && !r_busy;

/* IRQ 출력 */
assign irq = r_irq_st & r_irq_en;

/* ===== 통합 always 블록 ===== */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_addr <= 7'd0; r_rnw <= 1'b0; r_stop <= 1'b0;
        r_busy <= 1'b0; r_nak <= 1'b0;
        r_wdat <= 8'd0; r_rdat <= 8'd0;
        r_irq_st <= 1'b0; r_irq_en <= 1'b0;
        state <= S_IDLE; pcnt <= 12'd0; bcnt <= 3'd7; shift <= 8'd0;
        scl_o <= 1'b1; sda_o <= 1'b1;
    end else begin
        /* --- MMIO 쓰기 --- */
        if (mmio_cs && mmio_we) begin
            case (mmio_addr[15:0])
                16'h0000: begin
                    r_addr <= mmio_wdata[6:0];
                    r_rnw  <= mmio_wdata[7];
                    r_stop <= mmio_wdata[9];
                    /* bit8 (go)는 FSM에서 처리 */
                end
                16'h0004: r_wdat  <= mmio_wdata[7:0];
                16'hFFF8: r_irq_st <= r_irq_st & ~mmio_wdata[0]; /* W1C */
                16'hFFFC: r_irq_en <= mmio_wdata[0];
                default: ;
            endcase
        end

        /* --- FSM --- */
        case (state)
            /* 유휴 */
            S_IDLE: begin
                scl_o <= 1'b1; sda_o <= 1'b1;
                if (go_pulse) begin
                    r_busy <= 1'b1; r_nak <= 1'b0; r_irq_st <= 1'b0;
                    state <= S_START; pcnt <= 12'd0;
                end
            end

            /* START 조건: SDA 하강 (SCL=1) → SCL 하강 */
            S_START: begin
                if (pcnt == 12'd0) begin
                    sda_o <= 1'b0;                   /* SDA 하강 → START */
                    shift <= {r_addr, r_rnw};        /* 주소+RnW 래치 */
                    bcnt  <= 3'd7;
                end else if (p_h) scl_o <= 1'b0;    /* SCL 하강, 첫 비트 준비 */
                if (p_end) begin state <= S_ADDR; pcnt <= 12'd0; end
                else        pcnt <= pcnt + 12'd1;
            end

            /* 주소 + RnW 송신 (8비트) */
            S_ADDR: begin
                if (pcnt == 12'd0) sda_o <= shift[7];   /* SDA 세팅 */
                if (p_q1) scl_o <= 1'b1;                /* SCL 상승 */
                if (p_q3) scl_o <= 1'b0;                /* SCL 하강 */
                if (p_end) begin
                    if (bcnt == 3'd0) begin
                        state <= S_ADDR_AK; pcnt <= 12'd0;
                    end else begin
                        bcnt  <= bcnt - 3'd1;
                        shift <= {shift[6:0], 1'b0};
                        pcnt  <= 12'd0;
                    end
                end else pcnt <= pcnt + 12'd1;
            end

            /* 주소 ACK 수신 */
            S_ADDR_AK: begin
                if (pcnt == 12'd0) sda_o <= 1'b1;   /* SDA 릴리즈 (슬레이브 ACK) */
                if (p_q1) scl_o <= 1'b1;
                if (p_h)  r_nak <= sda_i;            /* 0=ACK, 1=NAK */
                if (p_q3) scl_o <= 1'b0;
                if (p_end) begin
                    pcnt <= 12'd0;
                    if (r_nak)       state <= r_stop ? S_STOP : S_DONE;
                    else if (!r_rnw) begin state <= S_TX; shift <= r_wdat; bcnt <= 3'd7; end
                    else             begin state <= S_RX; bcnt <= 3'd7; end
                end else pcnt <= pcnt + 12'd1;
            end

            /* 데이터 송신 (8비트, 쓰기 모드) */
            S_TX: begin
                if (pcnt == 12'd0) sda_o <= shift[7];
                if (p_q1) scl_o <= 1'b1;
                if (p_q3) scl_o <= 1'b0;
                if (p_end) begin
                    if (bcnt == 3'd0) begin
                        state <= S_TX_AK; pcnt <= 12'd0;
                    end else begin
                        bcnt  <= bcnt - 3'd1;
                        shift <= {shift[6:0], 1'b0};
                        pcnt  <= 12'd0;
                    end
                end else pcnt <= pcnt + 12'd1;
            end

            /* 데이터 ACK 수신 (쓰기 모드) */
            S_TX_AK: begin
                if (pcnt == 12'd0) sda_o <= 1'b1;
                if (p_q1) scl_o <= 1'b1;
                if (p_h)  r_nak <= sda_i;
                if (p_q3) scl_o <= 1'b0;
                if (p_end) begin
                    state <= r_stop ? S_STOP : S_DONE; pcnt <= 12'd0;
                end else pcnt <= pcnt + 12'd1;
            end

            /* 데이터 수신 (8비트, 읽기 모드) */
            S_RX: begin
                if (pcnt == 12'd0) sda_o <= 1'b1;   /* SDA 릴리즈 */
                if (p_q1) scl_o <= 1'b1;
                if (p_h)  shift <= {shift[6:0], sda_i}; /* 샘플 */
                if (p_q3) scl_o <= 1'b0;
                if (p_end) begin
                    if (bcnt == 3'd0) begin
                        r_rdat <= shift;
                        state  <= S_RX_NAK; pcnt <= 12'd0;
                    end else begin
                        bcnt <= bcnt - 3'd1; pcnt <= 12'd0;
                    end
                end else pcnt <= pcnt + 12'd1;
            end

            /* 마스터 NAK 송신 (읽기 1바이트 완료) */
            S_RX_NAK: begin
                if (pcnt == 12'd0) sda_o <= 1'b1;   /* NAK: SDA 하이 */
                if (p_q1) scl_o <= 1'b1;
                if (p_q3) scl_o <= 1'b0;
                if (p_end) begin
                    state <= r_stop ? S_STOP : S_DONE; pcnt <= 12'd0;
                end else pcnt <= pcnt + 12'd1;
            end

            /* STOP 조건: SCL 상승 → SDA 상승 */
            S_STOP: begin
                if (pcnt == 12'd0) sda_o <= 1'b0;   /* SDA 로우 확보 */
                if (p_q1) scl_o <= 1'b1;            /* SCL 상승 */
                if (p_h)  sda_o <= 1'b1;            /* SDA 상승 → STOP */
                if (p_end) begin state <= S_DONE; pcnt <= 12'd0; end
                else        pcnt <= pcnt + 12'd1;
            end

            /* 완료 */
            S_DONE: begin
                r_busy <= 1'b0; r_irq_st <= 1'b1;
                state <= S_IDLE;
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
            16'h0000: mmio_rdata = {20'd0, r_nak, r_busy, r_stop, 1'b0, r_rnw, r_addr};
            16'h0004: mmio_rdata = {24'd0, r_rdat};
            16'hFFF0: mmio_rdata = 32'h4932_434D; /* "I2CM" */
            16'hFFF4: mmio_rdata = 32'h0000_0100;
            16'hFFF8: mmio_rdata = {31'd0, r_irq_st};
            16'hFFFC: mmio_rdata = {31'd0, r_irq_en};
            default:  mmio_rdata = 32'd0;
        endcase
    end
end

endmodule
