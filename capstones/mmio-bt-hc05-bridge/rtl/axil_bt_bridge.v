`timescale 1ns/1ps
// axil_bt_bridge.v — HC-05 블루투스 텔레메트리 브리지 IP
// base: 0x4013_0000 (uart_bt 슬롯 [13], mbv-frozen-v2), intc 10
// 9600 bps 8N1, TX 프레임: 0xAA speed[15:0] angle[15:0] 0x55 (6바이트)
// RX: 1바이트 → RX_DATA + rx_done IRQ, STATE/EN GPIO
//
// 레지스터 맵 (오프셋):
//   0x00  CTRL     [0] bt_en  (HC-05 EN GPIO 출력, 1=AT 모드 진입)
//   0x04  STATUS   [0] bt_state(STATE GPIO 입력), [1] tx_busy, [2] rx_valid
//   0x08  TX_DATA  [15:0] speed, [31:16] angle
//   0x0C  TX_SEND  [0] write-1-to-start (자동 소거)
//   0x10  RX_DATA  [7:0] 마지막 수신 바이트
//   0x14  IRQ_EN   [0] rx_done IRQ 활성화
//   0x18  IRQ_STAT [0] rx_done (W1C)
//
// clk 100 MHz, rst_n active-low 동기
// CLKS_PER_BIT 파라미터: 기본 10417 (100 MHz / 9600)
`default_nettype none
module axil_bt_bridge #(
    parameter CLKS_PER_BIT = 10417
) (
    // AXI4-Lite 슬레이브
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // 외부 핀 (Pmod JA)
    output wire        bt_tx,      // → HC-05 RX (FPGA TX)
    input  wire        bt_rx,      // ← HC-05 TX (FPGA RX)
    input  wire        bt_state,   // ← HC-05 STATE (High=연결됨)
    output reg         bt_en,      // → HC-05 EN (High=AT 모드)
    // 인터럽트
    output wire        irq
);

    // ── AXI4-Lite 핸드셰이크 (AW+W 동시 처리) ─────────────────────────
    reg aw_active, w_active;
    reg [4:0] wr_addr_lat;   // 오프셋 [7:3]→[4:0] (32비트 정렬 주소 >> 2 = [6:2])
    reg [31:0] wr_data_lat;

    wire wr_fire = s_axi_awvalid && s_axi_wvalid && !aw_active;
    assign s_axi_awready = !aw_active;
    assign s_axi_wready  = !w_active;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_active    <= 1'b0;
            w_active     <= 1'b0;
            wr_addr_lat  <= 5'd0;
            wr_data_lat  <= 32'd0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            if (wr_fire) begin
                aw_active   <= 1'b1;
                w_active    <= 1'b1;
                wr_addr_lat <= s_axi_awaddr[6:2];
                wr_data_lat <= s_axi_wdata;
            end

            if (aw_active && w_active) begin
                aw_active    <= 1'b0;
                w_active     <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end
        end
    end

    // ── AXI4-Lite 읽기 채널 ───────────────────────────────────────────
    reg ar_active;
    reg [4:0] rd_addr_lat;

    assign s_axi_arready = !ar_active;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            ar_active    <= 1'b0;
            rd_addr_lat  <= 5'd0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= 2'b00;
            s_axi_rdata  <= 32'd0;
        end else begin
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            if (s_axi_arvalid && !ar_active) begin
                ar_active   <= 1'b1;
                rd_addr_lat <= s_axi_araddr[6:2];
            end

            if (ar_active && !s_axi_rvalid) begin
                ar_active    <= 1'b0;
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;
                // 레지스터 읽기
                case (rd_addr_lat)
                    5'd0: s_axi_rdata <= {31'd0, bt_en};
                    5'd1: s_axi_rdata <= {29'd0, rx_valid, tx_busy, bt_state};
                    5'd2: s_axi_rdata <= tx_data_reg;
                    5'd3: s_axi_rdata <= 32'd0;        // TX_SEND: 항상 0 읽힘
                    5'd4: s_axi_rdata <= {24'd0, rx_data_reg};
                    5'd5: s_axi_rdata <= {31'd0, irq_en};
                    5'd6: s_axi_rdata <= {31'd0, irq_stat};
                    default: s_axi_rdata <= 32'd0;
                endcase
            end
        end
    end

    // ── 내부 레지스터 ─────────────────────────────────────────────────
    reg [31:0] tx_data_reg;   // TX_DATA: [15:0]=speed, [31:16]=angle
    reg [7:0]  rx_data_reg;   // RX_DATA: 마지막 수신 바이트
    reg        irq_en;        // IRQ_EN[0]
    reg        irq_stat;      // IRQ_STAT[0] W1C
    reg        rx_valid;      // STATUS[2]: 미읽은 RX 데이터 있음

    wire       tx_busy;       // STATUS[1]: uart_tx 모듈에서
    assign irq = irq_stat && irq_en;

    // ── 레지스터 쓰기 처리 ────────────────────────────────────────────
    reg  tx_send_pulse;       // TX_SEND W1S: 프레임 전송 트리거
    wire do_write = aw_active && w_active;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            bt_en        <= 1'b0;
            tx_data_reg  <= 32'd0;
            irq_en       <= 1'b0;
            irq_stat     <= 1'b0;
            tx_send_pulse<= 1'b0;
            rx_valid     <= 1'b0;
        end else begin
            tx_send_pulse <= 1'b0;  // 기본: 소거

            // RX 완료 처리
            if (rx_done_w) begin
                rx_data_reg <= rx_data_w;
                rx_valid    <= 1'b1;
                irq_stat    <= 1'b1;
            end

            // 레지스터 쓰기
            if (do_write) begin
                case (wr_addr_lat)
                    5'd0: bt_en        <= wr_data_lat[0];           // CTRL
                    5'd2: tx_data_reg  <= wr_data_lat;              // TX_DATA
                    5'd3: begin
                        if (wr_data_lat[0] && !tx_busy)
                            tx_send_pulse <= 1'b1;                  // TX_SEND W1S
                    end
                    5'd4: rx_valid     <= 1'b0;                     // RX_DATA 읽으면 rx_valid 소거
                    5'd5: irq_en       <= wr_data_lat[0];           // IRQ_EN
                    5'd6: irq_stat     <= irq_stat & ~wr_data_lat[0]; // IRQ_STAT W1C
                    default: ;
                endcase
            end
        end
    end

    // ── UART TX 프레임 FSM ────────────────────────────────────────────
    // 프레임: 0xAA speed[15:8] speed[7:0] angle[15:8] angle[7:0] 0x55 (6바이트)
    localparam FS_IDLE = 3'd0;
    localparam FS_B0   = 3'd1;   // 0xAA
    localparam FS_B1   = 3'd2;   // speed[15:8]
    localparam FS_B2   = 3'd3;   // speed[7:0]
    localparam FS_B3   = 3'd4;   // angle[15:8]
    localparam FS_B4   = 3'd5;   // angle[7:0]
    localparam FS_B5   = 3'd6;   // 0x55

    reg [2:0]  fsm_state;
    reg [7:0]  tx_byte;
    reg        tx_start;
    reg [31:0] frame_data_latch;  // 전송 중 TX_DATA 고정

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            fsm_state       <= FS_IDLE;
            tx_byte         <= 8'd0;
            tx_start        <= 1'b0;
            frame_data_latch<= 32'd0;
        end else begin
            tx_start <= 1'b0;  // 기본: 소거

            case (fsm_state)
                FS_IDLE: begin
                    if (tx_send_pulse) begin
                        frame_data_latch <= tx_data_reg;
                        tx_byte          <= 8'hAA;
                        tx_start         <= 1'b1;
                        fsm_state        <= FS_B0;
                    end
                end
                FS_B0: begin
                    if (tx_done_w) begin
                        tx_byte   <= frame_data_latch[15:8];  // speed[15:8]
                        tx_start  <= 1'b1;
                        fsm_state <= FS_B1;
                    end
                end
                FS_B1: begin
                    if (tx_done_w) begin
                        tx_byte   <= frame_data_latch[7:0];   // speed[7:0]
                        tx_start  <= 1'b1;
                        fsm_state <= FS_B2;
                    end
                end
                FS_B2: begin
                    if (tx_done_w) begin
                        tx_byte   <= frame_data_latch[31:24]; // angle[15:8]
                        tx_start  <= 1'b1;
                        fsm_state <= FS_B3;
                    end
                end
                FS_B3: begin
                    if (tx_done_w) begin
                        tx_byte   <= frame_data_latch[23:16]; // angle[7:0]
                        tx_start  <= 1'b1;
                        fsm_state <= FS_B4;
                    end
                end
                FS_B4: begin
                    if (tx_done_w) begin
                        tx_byte   <= 8'h55;
                        tx_start  <= 1'b1;
                        fsm_state <= FS_B5;
                    end
                end
                FS_B5: begin
                    if (tx_done_w)
                        fsm_state <= FS_IDLE;
                end
                default: fsm_state <= FS_IDLE;
            endcase
        end
    end

    // ── UART TX 인스턴스 ──────────────────────────────────────────────
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk   (s_axi_aclk),
        .rst_n (s_axi_aresetn),
        .data  (tx_byte),
        .start (tx_start),
        .tx    (bt_tx),
        .busy  (tx_busy)
    );

    // tx_done_w: tx_busy의 하강 엣지 (바이트 전송 완료 신호)
    // FSM이 tx_start=1을 보낸 직후 tx_busy는 아직 0이다(uart_tx가 다음 클럭에 1로 올린다).
    // 따라서 !tx_busy 조건만으로는 FSM이 연속 2상태를 한 클럭에 건너뛰는 오류가 생긴다.
    // 직전 클럭에 tx_busy=1이었다가 현재 0인 순간만 써야 올바른 완료 감지가 된다.
    reg tx_busy_d;
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) tx_busy_d <= 1'b0;
        else                 tx_busy_d <= tx_busy;
    end
    wire tx_done_w = tx_busy_d & ~tx_busy;

    // ── UART RX 인스턴스 ──────────────────────────────────────────────
    wire [7:0] rx_data_w;
    wire       rx_done_w;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk    (s_axi_aclk),
        .rst_n  (s_axi_aresetn),
        .rx     (bt_rx),
        .data   (rx_data_w),
        .rx_done(rx_done_w)
    );

endmodule
`default_nettype wire
