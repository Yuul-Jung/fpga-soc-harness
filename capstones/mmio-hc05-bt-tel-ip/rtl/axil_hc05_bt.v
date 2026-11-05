`timescale 1ns/1ps
// axil_hc05_bt.v — AXI4-Lite HC-05 블루투스 텔레메트리 브리지
// 슬레이브 레지스터:
//   0x00 CTRL     [0]=TX_GO(W1S) [1]=EN_OUT(RW) [8]=BUSY(RO) [9]=STATE_IN(RO)
//   0x04 TX_SPD   [7:0] 속도 바이트
//   0x08 TX_ANG   [7:0] 조향 바이트
//   0x0C RX_DAT   [7:0] 수신 데이터 (RO)
//   0x10 IRQ_EN   [0]=RX_EN
//   0x14 IRQ_STAT [0]=RX_DONE (W1C)
// TX FSM: TS_IDLE → TS_B0(속도 전송) → TS_B1(조향 전송 대기+전송) → TS_IDLE
// 9600 bps @ 100 MHz → BAUD_DIV=10417
`default_nettype none
module axil_hc05_bt #(
    parameter BAUD_DIV = 10417
) (
    // AXI4-Lite 슬레이브
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write address
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // Write data
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // Write response
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read address
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // Read data
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // 외부 핀
    output wire        uart_tx_pin,  // → HC-05 RX
    input  wire        uart_rx_pin,  // ← HC-05 TX
    output reg         bt_en,        // → HC-05 EN
    input  wire        bt_state,     // ← HC-05 STATE
    // IRQ
    output wire        irq
);
    // ── TX FSM 상태 ───────────────────────────────────────────
    localparam TS_IDLE = 2'd0;
    localparam TS_B0   = 2'd1;  // 속도 바이트 전송 중 (uart_tx 완료 대기)
    localparam TS_B1   = 2'd2;  // 조향 바이트 로드 후 전송 완료 대기

    // ── 슬레이브 레지스터 ─────────────────────────────────────
    reg [7:0]  tx_spd_r;
    reg [7:0]  tx_ang_r;
    reg [7:0]  rx_dat_r;
    reg        irq_en_r;
    reg        irq_stat_r;

    // ── AXI 쓰기 채널 — AW ────────────────────────────────────
    reg [31:0] aw_addr_r;
    reg        aw_pend;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b1;
            aw_pend       <= 1'b0;
            aw_addr_r     <= 32'd0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_addr_r     <= s_axi_awaddr;
                aw_pend       <= 1'b1;
                s_axi_awready <= 1'b0;
            end else if (aw_pend && w_pend) begin
                aw_pend       <= 1'b0;
                s_axi_awready <= 1'b1;
            end
        end
    end

    // ── AXI 쓰기 채널 — W ─────────────────────────────────────
    reg [31:0] w_data_r;
    reg        w_pend;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b1;
            w_pend       <= 1'b0;
            w_data_r     <= 32'd0;
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin
                w_data_r     <= s_axi_wdata;
                w_pend       <= 1'b1;
                s_axi_wready <= 1'b0;
            end else if (aw_pend && w_pend) begin
                w_pend       <= 1'b0;
                s_axi_wready <= 1'b1;
            end
        end
    end

    wire do_write = aw_pend && w_pend;

    // ── 쓰기 응답 ─────────────────────────────────────────────
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= 2'b00;
        end else begin
            if (do_write) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ── UART 서브모듈 ─────────────────────────────────────────
    reg  [7:0]  tx_data_r;
    reg         tx_valid_r;
    wire        tx_ready_w;
    wire        rx_valid_w;
    wire [7:0]  rx_data_w;

    uart_tx #(.BAUD_DIV(BAUD_DIV)) u_tx (
        .clk   (s_axi_aclk),
        .rst   (~s_axi_aresetn),
        .data  (tx_data_r),
        .valid (tx_valid_r),
        .ready (tx_ready_w),
        .tx    (uart_tx_pin)
    );

    uart_rx #(.BAUD_DIV(BAUD_DIV)) u_rx (
        .clk   (s_axi_aclk),
        .rst   (~s_axi_aresetn),
        .rx    (uart_rx_pin),
        .data  (rx_data_w),
        .valid (rx_valid_w)
    );

    // ── TX FSM ────────────────────────────────────────────────
    // TX_GO 펄스: CTRL 주소 쓰기 + bit[0] 세트 + FSM idle
    wire tx_go_pulse = do_write && (aw_addr_r[5:2] == 4'd0) &&
                       w_data_r[0] && (tx_st == TS_IDLE);

    reg [1:0] tx_st;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            tx_st      <= TS_IDLE;
            tx_valid_r <= 1'b0;
            tx_data_r  <= 8'd0;
        end else begin
            case (tx_st)
                TS_IDLE: begin
                    tx_valid_r <= 1'b0;
                    if (tx_go_pulse) begin
                        tx_data_r  <= tx_spd_r;
                        tx_valid_r <= 1'b1;
                        tx_st      <= TS_B0;
                    end
                end
                TS_B0: begin
                    // tx_valid=1 주장 중. uart_tx가 수락하면(ready=1→0), valid 해제 후 TS_B1
                    // 첫 사이클에 tx_ready_w=1(idle): 이 때 uart_tx가 속도 바이트 수락
                    if (tx_ready_w) begin
                        tx_valid_r <= 1'b0;
                        tx_st      <= TS_B1;
                    end
                end
                TS_B1: begin
                    if (!tx_valid_r) begin
                        // uart_tx 완료 대기: ready가 다시 1이 되면 조향 바이트 로드
                        if (tx_ready_w) begin
                            tx_data_r  <= tx_ang_r;
                            tx_valid_r <= 1'b1;
                        end
                    end else begin
                        // 조향 바이트 valid 주장 중: 수락되면(ready=1→0) 완료
                        if (tx_ready_w) begin
                            tx_valid_r <= 1'b0;
                            tx_st      <= TS_IDLE;
                        end
                    end
                end
                default: tx_st <= TS_IDLE;
            endcase
        end
    end

    // ── 슬레이브 레지스터 쓰기 + RX 수신 처리 ──────────────────
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            tx_spd_r   <= 8'd0;
            tx_ang_r   <= 8'd0;
            rx_dat_r   <= 8'd0;
            bt_en      <= 1'b0;
            irq_en_r   <= 1'b0;
            irq_stat_r <= 1'b0;
        end else begin
            if (rx_valid_w) begin
                rx_dat_r   <= rx_data_w;
                irq_stat_r <= irq_stat_r | irq_en_r;
            end
            if (do_write) begin
                case (aw_addr_r[5:2])
                    4'd0: bt_en      <= w_data_r[1];          // CTRL[1]=EN_OUT
                    4'd1: tx_spd_r   <= w_data_r[7:0];        // TX_SPD
                    4'd2: tx_ang_r   <= w_data_r[7:0];        // TX_ANG
                    // 4'd3: RX_DAT RO
                    4'd4: irq_en_r   <= w_data_r[0];          // IRQ_EN
                    4'd5: irq_stat_r <= irq_stat_r & ~w_data_r[0]; // IRQ_STAT W1C
                    default: ;
                endcase
            end
        end
    end

    // ── AXI 읽기 채널 ─────────────────────────────────────────
    wire busy_w = (tx_st != TS_IDLE) || !tx_ready_w;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'd0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_arready <= 1'b0;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                case (s_axi_araddr[5:2])
                    4'd0: s_axi_rdata <= {22'd0, bt_state, busy_w, 6'd0, bt_en, 1'b0};
                    4'd1: s_axi_rdata <= {24'd0, tx_spd_r};
                    4'd2: s_axi_rdata <= {24'd0, tx_ang_r};
                    4'd3: s_axi_rdata <= {24'd0, rx_dat_r};
                    4'd4: s_axi_rdata <= {31'd0, irq_en_r};
                    4'd5: s_axi_rdata <= {31'd0, irq_stat_r};
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

    // ── IRQ 출력 ──────────────────────────────────────────────
    assign irq = irq_stat_r;

endmodule
`default_nettype wire
