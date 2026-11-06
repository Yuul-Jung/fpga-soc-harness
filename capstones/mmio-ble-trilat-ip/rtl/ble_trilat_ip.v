`timescale 1ns/1ps
// ble_trilat_ip.v — BLE 비콘 삼변측량 IP
// AXI4-Lite 슬레이브. 슬롯 [16] = 0x4016_0000, intc 13.
// UART 115200 bps 8N1 수신 → 8바이트 프레임 파싱 → 가중 중심 삼변측량.
// 프레임: 0xBB d1[15:8] d1[7:0] d2[15:8] d2[7:0] d3[15:8] d3[7:0] 0xEE
// 가중치: w_i = (d_i < 1000) ? (1000 - d_i) : 0
// x = (w2*400 + w3*200) / (w1+w2+w3)
// y = (w3*346) / (w1+w2+w3)
// IP 표준 Rev.1: ID=0xFFF0(R), VER=0xFFF4(R), IRQ_STATUS=0xFFF8(W1C), IRQ_ENABLE=0xFFFC(RW)
`default_nettype none

module ble_trilat_ip #(
    parameter CLKS_PER_BIT = 868  // 100 MHz / 115200
) (
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
    input  wire        uart_rx,
    output wire        irq
);
    localparam [31:0] IP_ID  = 32'h544C524C;
    localparam [31:0] IP_VER = 32'h01000001;
    localparam [15:0] W_MAX  = 16'd1000;
    localparam [15:0] AX2    = 16'd400;
    localparam [15:0] AX3    = 16'd200;
    localparam [15:0] AY3    = 16'd346;

    // ── AXI4-Lite 쓰기 채널 ─────────────────────────────────────────
    reg        aw_act, w_act;
    reg [13:0] wr_addr;
    reg [31:0] wr_data;
    wire       wr_fire = s_axi_awvalid && s_axi_wvalid && !aw_act;
    assign s_axi_awready = !aw_act;
    assign s_axi_wready  = !w_act;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_act <= 0; w_act <= 0; wr_addr <= 0; wr_data <= 0;
            s_axi_bvalid <= 0; s_axi_bresp <= 0;
        end else begin
            if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 0;
            if (wr_fire) begin
                aw_act  <= 1; w_act  <= 1;
                wr_addr <= s_axi_awaddr[15:2];
                wr_data <= s_axi_wdata;
            end
            if (aw_act && w_act) begin
                aw_act <= 0; w_act <= 0;
                s_axi_bvalid <= 1; s_axi_bresp <= 0;
            end
        end
    end

    // ── AXI4-Lite 읽기 채널 ─────────────────────────────────────────
    reg        ar_act;
    reg [13:0] rd_addr;
    assign s_axi_arready = !ar_act;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            ar_act <= 0; rd_addr <= 0;
            s_axi_rvalid <= 0; s_axi_rresp <= 0; s_axi_rdata <= 0;
        end else begin
            if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 0;
            if (s_axi_arvalid && !ar_act) begin
                ar_act  <= 1;
                rd_addr <= s_axi_araddr[15:2];
            end
            if (ar_act && !s_axi_rvalid) begin
                ar_act <= 0; s_axi_rvalid <= 1; s_axi_rresp <= 0;
                case (rd_addr)
                    14'd0:    s_axi_rdata <= {31'd0, ctrl_auto};
                    14'd1:    s_axi_rdata <= {29'd0, calc_err, calc_done_r, rx_busy};
                    14'd2:    s_axi_rdata <= {16'd0, d1_reg};
                    14'd3:    s_axi_rdata <= {16'd0, d2_reg};
                    14'd4:    s_axi_rdata <= {16'd0, d3_reg};
                    14'd5:    s_axi_rdata <= 32'd0;
                    14'd6:    s_axi_rdata <= {16'd0, x_pos};
                    14'd7:    s_axi_rdata <= {16'd0, y_pos};
                    14'h3FFC: s_axi_rdata <= IP_ID;
                    14'h3FFD: s_axi_rdata <= IP_VER;
                    14'h3FFE: s_axi_rdata <= {31'd0, irq_stat};
                    14'h3FFF: s_axi_rdata <= {31'd0, irq_en};
                    default:  s_axi_rdata <= 32'd0;
                endcase
            end
        end
    end

    // ── 내부 레지스터 ───────────────────────────────────────────────
    reg        ctrl_auto;
    reg [15:0] d1_reg, d2_reg, d3_reg;
    reg [15:0] x_pos, y_pos;
    reg        calc_done_r, calc_err;
    reg        irq_en, irq_stat;
    reg        trig_pulse;

    assign irq = irq_stat && irq_en;

    wire       do_write     = aw_act && w_act;
    wire       frame_valid;         // 1클럭 펄스 (파서에서)
    wire       calc_done_p;         // 1클럭 펄스 (삼변측량 FSM에서)

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            ctrl_auto <= 0; d1_reg <= 0; d2_reg <= 0; d3_reg <= 0;
            irq_en <= 0; irq_stat <= 0; trig_pulse <= 0;
        end else begin
            trig_pulse <= 0;
            // frame_valid 갱신 (AXI 쓰기보다 낮은 우선순위)
            if (frame_valid) begin
                d1_reg <= d1_w; d2_reg <= d2_w; d3_reg <= d3_w;
            end
            // AXI 쓰기 (우선순위 높음)
            if (do_write) begin
                case (wr_addr)
                    14'd0: ctrl_auto <= wr_data[0];
                    14'd2: d1_reg    <= wr_data[15:0];
                    14'd3: d2_reg    <= wr_data[15:0];
                    14'd4: d3_reg    <= wr_data[15:0];
                    14'd5: if (wr_data[0] && !calc_busy) trig_pulse <= 1;
                    14'h3FFE: irq_stat <= irq_stat & ~wr_data[0];  // W1C
                    14'h3FFF: irq_en   <= wr_data[0];
                    default: ;
                endcase
            end
            if (calc_done_p) irq_stat <= 1;
        end
    end

    // ── UART RX (인라인, 115200 bps 8N1) ──────────────────────────
    localparam [1:0] UR_IDLE=0, UR_START=1, UR_DATA=2, UR_STOP=3;
    reg [1:0]  ur_st;
    reg [15:0] ur_cnt;
    reg [2:0]  ur_bit;
    reg [7:0]  ur_shift;
    reg        rx_busy;
    reg [7:0]  rx_byte;
    reg        rx_valid;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            ur_st<=UR_IDLE; ur_cnt<=0; ur_bit<=0; ur_shift<=0;
            rx_busy<=0; rx_byte<=0; rx_valid<=0;
        end else begin
            rx_valid <= 0;
            case (ur_st)
                UR_IDLE: if (!uart_rx) begin
                    ur_cnt <= 0; ur_st <= UR_START; rx_busy <= 1;
                end
                UR_START: if (ur_cnt == CLKS_PER_BIT[15:0]/2 - 1) begin
                    ur_cnt <= 0; ur_bit <= 0; ur_st <= UR_DATA;
                end else ur_cnt <= ur_cnt + 1;
                UR_DATA:  if (ur_cnt == CLKS_PER_BIT[15:0] - 1) begin
                    ur_cnt  <= 0;
                    ur_shift <= {uart_rx, ur_shift[7:1]};
                    if (ur_bit == 7) ur_st <= UR_STOP;
                    else ur_bit <= ur_bit + 1;
                end else ur_cnt <= ur_cnt + 1;
                UR_STOP:  if (ur_cnt == CLKS_PER_BIT[15:0] - 1) begin
                    rx_byte <= ur_shift; rx_valid <= 1;
                    rx_busy <= 0; ur_st <= UR_IDLE; ur_cnt <= 0;
                end else ur_cnt <= ur_cnt + 1;
            endcase
        end
    end

    // ── 프레임 파서: 0xBB d1_hi d1_lo d2_hi d2_lo d3_hi d3_lo 0xEE ─
    localparam [2:0] FP_SOF=0,FP_D1H=1,FP_D1L=2,FP_D2H=3,FP_D2L=4,FP_D3H=5,FP_D3L=6,FP_EOF=7;
    reg [2:0]  fp_st;
    reg [15:0] d1_w, d2_w, d3_w;
    reg        frame_valid_r;
    assign frame_valid = frame_valid_r;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            fp_st<=FP_SOF; d1_w<=0; d2_w<=0; d3_w<=0; frame_valid_r<=0;
        end else begin
            frame_valid_r <= 0;
            if (rx_valid) case (fp_st)
                FP_SOF: if (rx_byte==8'hBB) fp_st <= FP_D1H;
                FP_D1H: begin d1_w[15:8]<=rx_byte; fp_st<=FP_D1L; end
                FP_D1L: begin d1_w[7:0] <=rx_byte; fp_st<=FP_D2H; end
                FP_D2H: begin d2_w[15:8]<=rx_byte; fp_st<=FP_D2L; end
                FP_D2L: begin d2_w[7:0] <=rx_byte; fp_st<=FP_D3H; end
                FP_D3H: begin d3_w[15:8]<=rx_byte; fp_st<=FP_D3L; end
                FP_D3L: begin d3_w[7:0] <=rx_byte; fp_st<=FP_EOF; end
                FP_EOF: begin
                    if (rx_byte==8'hEE) frame_valid_r <= 1;
                    fp_st <= FP_SOF;
                end
                default: fp_st <= FP_SOF;
            endcase
        end
    end

    // ── 삼변측량 FSM ───────────────────────────────────────────────
    localparam [2:0] TR_IDLE=0,TR_PREP=1,TR_XDIV=2,TR_XWAIT=3,
                     TR_YDIV=4,TR_YWAIT=5,TR_DONE=6,TR_ERR=7;
    reg [2:0]  tr_st;
    reg        calc_busy;
    reg        calc_done_pr;
    assign     calc_done_p = calc_done_pr;

    reg [15:0] w1, w2, w3;
    reg [31:0] w_tot, x_num, y_num;

    reg  [31:0] div_dd, div_dr;
    reg         div_start;
    wire [31:0] div_q;
    wire        div_done, div_busy_w;

    div32 u_div (
        .clk(s_axi_aclk), .rst_n(s_axi_aresetn),
        .dividend(div_dd), .divisor(div_dr), .start(div_start),
        .quotient(div_q), .remainder(), .done(div_done), .busy(div_busy_w)
    );

    wire do_trig = trig_pulse || (frame_valid && ctrl_auto);

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            tr_st<=TR_IDLE; calc_busy<=0; calc_done_r<=0; calc_err<=0;
            calc_done_pr<=0; x_pos<=0; y_pos<=0;
            w1<=0; w2<=0; w3<=0; w_tot<=0; x_num<=0; y_num<=0;
            div_start<=0; div_dd<=0; div_dr<=0;
        end else begin
            calc_done_pr <= 0;
            div_start    <= 0;
            case (tr_st)
                TR_IDLE: if (do_trig && !calc_busy) begin
                    calc_busy<=1; calc_done_r<=0; calc_err<=0;
                    tr_st<=TR_PREP;
                end
                TR_PREP: begin
                    w1 <= (d1_reg < W_MAX) ? (W_MAX - d1_reg) : 16'd0;
                    w2 <= (d2_reg < W_MAX) ? (W_MAX - d2_reg) : 16'd0;
                    w3 <= (d3_reg < W_MAX) ? (W_MAX - d3_reg) : 16'd0;
                    tr_st <= TR_XDIV;
                end
                TR_XDIV: begin
                    w_tot <= {16'd0,w1} + {16'd0,w2} + {16'd0,w3};
                    x_num <= ({16'd0,w2} * {16'd0,AX2}) + ({16'd0,w3} * {16'd0,AX3});
                    y_num <= {16'd0,w3} * {16'd0,AY3};
                    tr_st <= TR_XWAIT;
                end
                TR_XWAIT: begin
                    if (w_tot==0) begin
                        calc_err<=1; tr_st<=TR_ERR;
                    end else begin
                        div_dd<=x_num; div_dr<=w_tot; div_start<=1;
                        tr_st<=TR_YDIV;
                    end
                end
                TR_YDIV: if (div_done) begin
                    x_pos<=div_q[15:0];
                    div_dd<=y_num; div_dr<=w_tot; div_start<=1;
                    tr_st<=TR_YWAIT;
                end
                TR_YWAIT: if (div_done) begin
                    y_pos<=div_q[15:0]; tr_st<=TR_DONE;
                end
                TR_DONE: begin
                    calc_done_r<=1; calc_done_pr<=1;
                    calc_busy<=0; tr_st<=TR_IDLE;
                end
                TR_ERR: begin
                    calc_busy<=0; tr_st<=TR_IDLE;
                end
                default: tr_st<=TR_IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
