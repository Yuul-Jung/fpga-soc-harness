// axil_i2c3_nmea_hub.v — AXI4-Lite I2C 3장치 순회 + NMEA UART 허브 IP
// 하네스 직접 작성 Verilog-2001 원본. 외부 코드 미포함.
// I2C: MPU-6050(0x68, reg 0x75), BMP280(0x76, reg 0xD0), HMC5883L(0x1E, reg 0x0A) 순회
// UART: 9600baud 8N1, NMEA 문장($ ~ \n) 완료 IRQ
// FIFO: 16엔트리, [31:24]=sensor_id, [23:0]=data, 별도 타임스탬프
// TEST_MODE(CTRL[8]): FIFO_INJ 레지스터로 직접 FIFO 주입 가능

`default_nettype none
module axil_i2c3_nmea_hub #(
    parameter CLK_DIV_I2C  = 1000,   // I2C 비트 분주 (100kHz@100MHz)
    parameter CLK_DIV_UART = 10417   // UART 비트 분주 (9600baud@100MHz)
) (
    input  wire        aclk,
    input  wire        aresetn,

    // AXI4-Lite 슬레이브
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

    // 외부 I/O
    output wire        scl,       // I2C SCL (오픈드레인 Hi-Z=1, Lo=0)
    inout  wire        sda,       // I2C SDA (오픈드레인)
    input  wire        uart_rx,   // UART RX (NMEA)

    // 인터럽트
    output reg         irq_out
);

// ── 레지스터 주소 ─────────────────────────────────────────
localparam [15:0]
    A_CTRL      = 16'h0000,
    A_STATUS    = 16'h0004,
    A_FIFO_DATA = 16'h0008,
    A_FIFO_TS   = 16'h000C,
    A_FIFO_CNT  = 16'h0010,
    A_I2C_DIV   = 16'h0014,
    A_UART_DIV  = 16'h0018,
    A_FIFO_INJ  = 16'h001C,
    A_ID_REG    = 16'hFFF0,
    A_VER_REG   = 16'hFFF4,
    A_IRQ_EN    = 16'hFFF8,
    A_IRQ_PEND  = 16'hFFFC;

// ── 레지스터 ─────────────────────────────────────────────
reg        r_en;         // CTRL[0]
reg        r_uart_en;    // CTRL[1]
reg        r_fifo_clr;   // CTRL[7] (자동클리어)
reg        r_test_mode;  // CTRL[8]
reg [31:0] r_i2c_div;
reg [31:0] r_uart_div;
reg        r_irq_en;
reg        r_irq_pend;

// ── FIFO 16엔트리 ─────────────────────────────────────────
localparam FIFO_DEPTH = 16;
reg [31:0] fifo_data [0:FIFO_DEPTH-1];
reg [31:0] fifo_ts   [0:FIFO_DEPTH-1];
reg [3:0]  fifo_wptr;
reg [3:0]  fifo_rptr;
reg [4:0]  fifo_cnt;

wire fifo_empty = (fifo_cnt == 5'd0);
wire fifo_full  = (fifo_cnt == 5'd16);

// FIFO 쓰기 (내부에서만)
task fifo_push;
    input [7:0]  sid;
    input [23:0] dat;
    input [31:0] ts;
    begin
        if (!fifo_full) begin
            fifo_data[fifo_wptr] <= {sid, dat};
            fifo_ts  [fifo_wptr] <= ts;
            fifo_wptr <= fifo_wptr + 4'd1;
            fifo_cnt  <= fifo_cnt  + 5'd1;
        end
    end
endtask

// ── 타임스탬프 카운터 ─────────────────────────────────────
reg [31:0] ts_cnt;
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) ts_cnt <= 32'd0;
    else          ts_cnt <= ts_cnt + 32'd1;
end

// ── i2c_rd_byte 인스턴스 ─────────────────────────────────
reg        i2c_start;
reg  [6:0] i2c_dev_addr;
reg  [7:0] i2c_reg_addr;
wire       i2c_done;
wire [7:0] i2c_data;
wire       i2c_ack_err;
wire       scl_out_w;
wire       sda_out_w;
wire       sda_in_w = sda;

i2c_rd_byte #(
    .CLK_DIV(CLK_DIV_I2C)
) u_i2c (
    .clk      (aclk),
    .rst_n    (aresetn),
    .start    (i2c_start),
    .dev_addr (i2c_dev_addr),
    .reg_addr (i2c_reg_addr),
    .done     (i2c_done),
    .data_out (i2c_data),
    .ack_err  (i2c_ack_err),
    .scl_out  (scl_out_w),
    .sda_out  (sda_out_w),
    .sda_in   (sda_in_w)
);

// 오픈드레인 출력 (0=drive GND, 1=Hi-Z)
assign scl = scl_out_w ? 1'bz : 1'b0;
assign sda = sda_out_w ? 1'bz : 1'b0;

// ── I2C 순회 FSM ─────────────────────────────────────────
// sensor_id: 0=MPU-6050, 1=BMP280, 2=HMC5883L
localparam [1:0] I_MPU = 2'd0, I_BMP = 2'd1, I_HMC = 2'd2;

// 센서 테이블 (파라미터로 쓰면 더 깔끔하지만 Verilog-2001 호환 간단 버전)
function [6:0] sensor_addr;
    input [1:0] id;
    begin
        case (id)
            I_MPU: sensor_addr = 7'h68;
            I_BMP: sensor_addr = 7'h76;
            I_HMC: sensor_addr = 7'h1E;
            default: sensor_addr = 7'h00;
        endcase
    end
endfunction

function [7:0] sensor_reg;
    input [1:0] id;
    begin
        case (id)
            I_MPU: sensor_reg = 8'h75;  // WHO_AM_I
            I_BMP: sensor_reg = 8'hD0;  // id
            I_HMC: sensor_reg = 8'h0A;  // IRA
            default: sensor_reg = 8'h00;
        endcase
    end
endfunction

localparam [1:0]
    IS_WAIT  = 2'd0,  // 대기 (인터벌 카운터)
    IS_START = 2'd1,  // I2C 시작 펄스
    IS_BUSY  = 2'd2,  // I2C 완료 대기
    IS_PUSH  = 2'd3;  // FIFO 푸시

reg [1:0]  i2c_fsm;
reg [1:0]  i2c_sel;    // 현재 센서 (0~2)
reg [26:0] i2c_timer;  // 대기 카운터 (~100ms @ 100MHz)
reg        i2c_timeout_r;

localparam [26:0] I2C_INTERVAL = 27'd10_000_000;  // 100ms @ 100MHz

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        i2c_fsm      <= IS_WAIT;
        i2c_sel      <= I_MPU;
        i2c_timer    <= 27'd0;
        i2c_start    <= 1'b0;
        i2c_dev_addr <= 7'd0;
        i2c_reg_addr <= 8'd0;
        i2c_timeout_r <= 1'b0;
    end else begin
        i2c_start <= 1'b0;  // 기본 1사이클

        if (!r_en || r_test_mode) begin
            // 비활성 또는 TEST_MODE: IDLE
            i2c_fsm   <= IS_WAIT;
            i2c_timer <= 27'd0;
        end else begin
            case (i2c_fsm)
            IS_WAIT: begin
                i2c_timer <= i2c_timer + 27'd1;
                if (i2c_timer >= I2C_INTERVAL - 27'd1) begin
                    i2c_timer    <= 27'd0;
                    i2c_dev_addr <= sensor_addr(i2c_sel);
                    i2c_reg_addr <= sensor_reg(i2c_sel);
                    i2c_fsm      <= IS_START;
                end
            end
            IS_START: begin
                i2c_start    <= 1'b1;
                i2c_timeout_r <= 1'b0;
                i2c_fsm      <= IS_BUSY;
            end
            IS_BUSY: begin
                if (i2c_done) begin
                    i2c_timeout_r <= i2c_ack_err;
                    i2c_fsm <= IS_PUSH;
                end
            end
            IS_PUSH: begin
                // FIFO 푸시는 별도 always 블록에서 처리 (task는 always 내에서 직접)
                i2c_sel <= (i2c_sel == 2'd2) ? 2'd0 : i2c_sel + 2'd1;
                i2c_fsm <= IS_WAIT;
            end
            endcase
        end
    end
end

// FIFO 푸시 (I2C)
// IS_PUSH 상태에서 1사이클 동안 fifo_push 수행
// 별도 always로 분리하면 task 충돌 없음 → 직접 인라인
reg i2c_push_r;
always @(posedge aclk) i2c_push_r <= (i2c_fsm == IS_PUSH) && r_en && !r_test_mode;

// ── UART 수신기 (NMEA: $ ~ \n) ───────────────────────────
// 완료 조건: '\n'(0x0A) 수신
// sensor_id = 3 (NMEA 완료)
localparam [2:0]
    US_IDLE = 3'd0,   // 시작비트 대기
    US_STX  = 3'd1,   // 시작비트 확인 (중간 샘플)
    US_DATA = 3'd2,   // 8 데이터 비트
    US_STOP = 3'd3,   // 정지비트
    US_DONE = 3'd4;   // 처리

reg [2:0]  uart_fsm;
reg [15:0] uart_timer;
reg [3:0]  uart_bit_cnt;
reg [7:0]  uart_shift;
reg        uart_rx_sync1, uart_rx_sync2, uart_rx_prev;
reg        uart_in_nmea;  // NMEA 문장 수신 중 ('$' 본 적 있음)
reg [7:0]  uart_last_byte;
reg        uart_nmea_done;  // NMEA 완료 1-펄스

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        uart_rx_sync1  <= 1'b1;
        uart_rx_sync2  <= 1'b1;
        uart_rx_prev   <= 1'b1;
        uart_fsm       <= US_IDLE;
        uart_timer     <= 16'd0;
        uart_bit_cnt   <= 4'd0;
        uart_shift     <= 8'd0;
        uart_in_nmea   <= 1'b0;
        uart_last_byte <= 8'd0;
        uart_nmea_done <= 1'b0;
    end else begin
        uart_rx_sync1 <= uart_rx;
        uart_rx_sync2 <= uart_rx_sync1;
        uart_rx_prev  <= uart_rx_sync2;
        uart_nmea_done <= 1'b0;

        if (!r_uart_en || !r_en) begin
            uart_fsm   <= US_IDLE;
            uart_timer <= 16'd0;
        end else begin
            case (uart_fsm)
            US_IDLE: begin
                if (uart_rx_sync2 == 1'b0 && uart_rx_prev == 1'b1) begin
                    // 하강 엣지 감지 → 시작비트
                    uart_timer <= r_uart_div[15:0] >> 1; // 반 비트 오프셋으로 중간 샘플
                    uart_fsm   <= US_STX;
                end
            end
            US_STX: begin
                if (uart_timer == 16'd0) begin
                    if (uart_rx_sync2 == 1'b0) begin
                        uart_timer   <= r_uart_div[15:0] - 16'd1;
                        uart_bit_cnt <= 4'd7;
                        uart_shift   <= 8'd0;
                        uart_fsm     <= US_DATA;
                    end else begin
                        uart_fsm <= US_IDLE;  // 잘못된 시작비트
                    end
                end else begin
                    uart_timer <= uart_timer - 16'd1;
                end
            end
            US_DATA: begin
                if (uart_timer == 16'd0) begin
                    uart_shift   <= {uart_rx_sync2, uart_shift[7:1]};  // LSB 먼저
                    uart_timer   <= r_uart_div[15:0] - 16'd1;
                    if (uart_bit_cnt == 4'd0)
                        uart_fsm <= US_STOP;
                    else
                        uart_bit_cnt <= uart_bit_cnt - 4'd1;
                end else begin
                    uart_timer <= uart_timer - 16'd1;
                end
            end
            US_STOP: begin
                if (uart_timer == 16'd0) begin
                    uart_last_byte <= uart_shift;
                    uart_fsm <= US_DONE;
                end else begin
                    uart_timer <= uart_timer - 16'd1;
                end
            end
            US_DONE: begin
                if (uart_last_byte == 8'h24) uart_in_nmea <= 1'b1; // '$'
                if (uart_last_byte == 8'h0A && uart_in_nmea) begin  // '\n'
                    uart_nmea_done <= 1'b1;
                    uart_in_nmea   <= 1'b0;
                end
                uart_fsm <= US_IDLE;
            end
            default: uart_fsm <= US_IDLE;
            endcase
        end
    end
end

// ── FIFO 통합 쓰기 ───────────────────────────────────────
// I2C push (IS_PUSH → i2c_push_r) 또는 UART NMEA done 또는 TEST_MODE INJ
// 간단하게 순위: TEST_MODE > UART > I2C

// TEST_MODE 주입 신호 (AXI 쓰기에서 1-사이클 펄스)
reg        inj_valid;
reg [31:0] inj_data;
reg        push_done;    // FIFO push 완료 1-펄스 (FIFO write block만 구동)
reg        w1c_irq_pend; // IRQ_PEND W1C 요청 1-펄스 (AXI write block만 구동)

integer i;  // Verilog-2001: 모듈 레벨 선언 (unnamed block 불가)
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        fifo_wptr <= 4'd0;
        fifo_cnt  <= 5'd0;
        push_done <= 1'b0;
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            fifo_data[i] <= 32'd0;
            fifo_ts[i]   <= 32'd0;
        end
    end else begin
        push_done <= 1'b0;  // 기본: 펄스 없음 (매 사이클 클리어)
        if (r_fifo_clr) begin
            fifo_wptr <= 4'd0;
            fifo_cnt  <= 5'd0;
        end else if (r_test_mode && inj_valid) begin
            if (!fifo_full) begin
                fifo_data[fifo_wptr] <= inj_data;
                fifo_ts  [fifo_wptr] <= ts_cnt;
                fifo_wptr <= fifo_wptr + 4'd1;
                fifo_cnt  <= fifo_cnt  + 5'd1;
                push_done <= 1'b1;  // IRQ 이벤트 펄스
            end
        end else if (uart_nmea_done && r_uart_en) begin
            if (!fifo_full) begin
                fifo_data[fifo_wptr] <= {8'd3, 24'h000001};  // sensor_id=3, data=1(완료)
                fifo_ts  [fifo_wptr] <= ts_cnt;
                fifo_wptr <= fifo_wptr + 4'd1;
                fifo_cnt  <= fifo_cnt  + 5'd1;
                push_done <= 1'b1;  // IRQ 이벤트 펄스
            end
        end else if (i2c_push_r) begin
            if (!fifo_full) begin
                fifo_data[fifo_wptr] <= {6'd0, i2c_sel, i2c_timeout_r ? 24'hFF_FFFF : {16'd0, i2c_data}};
                fifo_ts  [fifo_wptr] <= ts_cnt;
                fifo_wptr <= fifo_wptr + 4'd1;
                fifo_cnt  <= fifo_cnt  + 5'd1;
                push_done <= 1'b1;  // IRQ 이벤트 펄스
            end
        end else if (fifo_pop && !fifo_empty) begin
            // 팝은 AXI 읽기 블록이 fifo_pop 펄스로 요청, 여기서 cnt 감소
            fifo_cnt <= fifo_cnt - 5'd1;
        end
    end
end

// ── IRQ 로직 ─────────────────────────────────────────────
// r_irq_pend의 유일한 구동자. W1C 클리어(w1c_irq_pend) 우선, 푸시 이벤트(push_done)로 세트.
// 연속 레벨(!fifo_empty)이 아닌 1-펄스 이벤트 기반 → multi-driver 없음
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        r_irq_pend <= 1'b0;
        irq_out    <= 1'b0;
    end else begin
        if (w1c_irq_pend)
            r_irq_pend <= 1'b0;           // W1C 클리어 (AXI 쓰기 요청 1-펄스)
        else if (push_done || uart_nmea_done)
            r_irq_pend <= 1'b1;           // 이벤트 기반 세트 (레벨이 아닌 펄스)
        irq_out <= r_irq_en & r_irq_pend;
    end
end

// ── AXI4-Lite 슬레이브 ───────────────────────────────────
reg [15:0] wr_addr;
reg [31:0] wr_data;
reg        wr_pending;

// 쓰기 주소 채널
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_awready  <= 1'b0;
        wr_addr    <= 16'd0;
        wr_pending <= 1'b0;
    end else begin
        s_awready <= 1'b0;
        if (s_awvalid && !wr_pending) begin
            s_awready  <= 1'b1;
            wr_addr    <= s_awaddr;
            wr_pending <= 1'b1;
        end
    end
end

// 쓰기 데이터 채널 + 쓰기 처리
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_wready   <= 1'b0;
        s_bvalid   <= 1'b0;
        s_bresp    <= 2'b00;
        wr_data    <= 32'd0;
        r_en       <= 1'b0;
        r_uart_en  <= 1'b0;
        r_fifo_clr <= 1'b0;
        r_test_mode <= 1'b0;
        r_i2c_div  <= CLK_DIV_I2C;
        r_uart_div <= CLK_DIV_UART;
        r_irq_en   <= 1'b0;
        inj_valid     <= 1'b0;
        inj_data      <= 32'd0;
        w1c_irq_pend  <= 1'b0;
    end else begin
        s_wready      <= 1'b0;
        r_fifo_clr    <= 1'b0;  // 자동 클리어
        inj_valid     <= 1'b0;
        w1c_irq_pend  <= 1'b0;  // 자동 클리어 (1-펄스)

        if (s_bvalid && s_bready) s_bvalid <= 1'b0;

        if (s_wvalid && wr_pending) begin
            s_wready   <= 1'b1;
            wr_data    <= s_wdata;
            wr_pending <= 1'b0;
            s_bvalid   <= 1'b1;
            s_bresp    <= 2'b00;

            case (wr_addr)
            A_CTRL: begin
                r_en        <= s_wdata[0];
                r_uart_en   <= s_wdata[1];
                r_fifo_clr  <= s_wdata[7];
                r_test_mode <= s_wdata[8];
            end
            A_I2C_DIV:  r_i2c_div  <= (s_wdata < 32'd8) ? 32'd8 : s_wdata;
            A_UART_DIV: r_uart_div <= s_wdata;
            A_FIFO_INJ: begin
                inj_valid <= 1'b1;
                inj_data  <= s_wdata;
            end
            A_IRQ_EN:   r_irq_en   <= s_wdata[0];
            A_IRQ_PEND: begin
                if (s_wdata[0]) w1c_irq_pend <= 1'b1;  // W1C 요청 → IRQ block이 처리
            end
            default: ;
            endcase
        end
    end
end

// 읽기 채널
// FIFO 팝: FIFO_DATA 읽기 시 팝 (rdata + rptr 갱신)
reg [31:0] popped_data;
reg [31:0] popped_ts;
reg        fifo_pop;

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        s_arready  <= 1'b0;
        s_rvalid   <= 1'b0;
        s_rdata    <= 32'd0;
        s_rresp    <= 2'b00;
        fifo_pop   <= 1'b0;
        fifo_rptr  <= 4'd0;
        popped_data <= 32'd0;
        popped_ts   <= 32'd0;
    end else begin
        s_arready <= 1'b0;
        fifo_pop  <= 1'b0;

        if (s_rvalid && s_rready) s_rvalid <= 1'b0;

        if (s_arvalid && !s_rvalid) begin
            s_arready <= 1'b1;
            s_rvalid  <= 1'b1;
            s_rresp   <= 2'b00;

            case (s_araddr)
            A_CTRL:   s_rdata <= {23'd0, r_test_mode, 6'd0, r_fifo_clr, r_uart_en, r_en};
            A_STATUS: s_rdata <= {29'd0, i2c_timeout_r, fifo_full, fifo_empty};
            A_FIFO_DATA: begin
                if (!fifo_empty) begin
                    popped_data <= fifo_data[fifo_rptr];
                    popped_ts   <= fifo_ts[fifo_rptr];
                    fifo_rptr   <= fifo_rptr + 4'd1;
                    fifo_pop    <= 1'b1;
                    s_rdata     <= fifo_data[fifo_rptr];
                end else begin
                    s_rdata <= 32'd0;
                end
            end
            A_FIFO_TS:  s_rdata <= popped_ts;
            A_FIFO_CNT: s_rdata <= {27'd0, fifo_cnt};
            A_I2C_DIV:  s_rdata <= r_i2c_div;
            A_UART_DIV: s_rdata <= r_uart_div;
            A_ID_REG:   s_rdata <= 32'h48554231;  // HUB1
            A_VER_REG:  s_rdata <= 32'h00010000;  // v1.0.0
            A_IRQ_EN:   s_rdata <= {31'd0, r_irq_en};
            A_IRQ_PEND: s_rdata <= {31'd0, r_irq_pend};
            default:    s_rdata <= 32'd0;
            endcase
        end
    end
end

endmodule
`default_nettype wire
