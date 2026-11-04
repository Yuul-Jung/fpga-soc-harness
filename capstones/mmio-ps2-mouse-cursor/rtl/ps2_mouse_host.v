// ps2_mouse_host.v
// PS/2 마우스 호스트 수신기 + MMIO-lite 레지스터
// IP 표준 rev.1 관리 레지스터 (ID/VER/IRQ_STATUS W1C/IRQ_ENABLE) 포함
// Verilog-2001. iverilog/verilator/yosys 호환.
// 원작자: 하네스 자체 작성 (2026-11-04)

`default_nettype none

module ps2_mouse_host #(
    parameter INHIBIT_CNT = 10000  // CLK 인히빗 클럭 수 (기본: 100μs @100MHz)
) (
    input  wire        clk,
    input  wire        rst,

    // MMIO-lite 슬레이브
    input  wire        sel,
    input  wire        we,
    input  wire [15:0] offset,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,

    // 커서 출력
    output reg  [9:0]  cursor_x,
    output reg  [9:0]  cursor_y,
    output reg  [2:0]  mouse_btn,
    output wire        irq_out,

    // PS/2 오픈드레인 (oe=1 → 선 로우, oe=0 → Hi-Z)
    input  wire        ps2_clk_in,
    input  wire        ps2_data_in,
    output reg         ps2_clk_oe,
    output reg         ps2_data_oe
);

// ─── MMIO 레지스터 오프셋 ─────────────────────────────────
localparam OFF_CTRL      = 16'h0000;
localparam OFF_MOUSE_X   = 16'h0004;
localparam OFF_MOUSE_Y   = 16'h0008;
localparam OFF_MOUSE_BTN = 16'h000C;
localparam OFF_STATUS    = 16'h0010;
localparam OFF_ID        = 16'hFFF0;
localparam OFF_VER       = 16'hFFF4;
localparam OFF_IRQ_STS   = 16'hFFF8;
localparam OFF_IRQ_EN    = 16'hFFFC;

localparam IP_ID  = 32'h5053_324D; // 'PS2M'
localparam IP_VER = 32'h0100_0100;

// ─── 제어 레지스터 ───────────────────────────────────────
reg ctrl_enable;
reg ctrl_cursor_en;
reg irq_status_r;
reg irq_enable_r;
reg [1:0] status_r;  // [0]=init_done, [1]=streaming

assign irq_out = irq_status_r & irq_enable_r;

// ─── PS/2 CLK 2단 동기화 + 하강 에지 검출 ───────────────
reg ps2_clk_s0, ps2_clk_s1, ps2_clk_prev;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        ps2_clk_s0 <= 1'b1; ps2_clk_s1 <= 1'b1; ps2_clk_prev <= 1'b1;
    end else begin
        ps2_clk_s0 <= ps2_clk_in; ps2_clk_s1 <= ps2_clk_s0;
        ps2_clk_prev <= ps2_clk_s1;
    end
end
wire ps2_clk_fall = ps2_clk_prev & ~ps2_clk_s1;
// TX 중에는 수신기 비활성 (TX_INH, TX_START, TX_BITS 상태)
wire rx_en = (state != S_TX_INH) && (state != S_TX_START) && (state != S_TX_BITS);

// PS/2 DATA 2단 동기화
reg ps2_data_s0, ps2_data_s1;
always @(posedge clk or posedge rst) begin
    if (rst) begin ps2_data_s0 <= 1'b1; ps2_data_s1 <= 1'b1; end
    else     begin ps2_data_s0 <= ps2_data_in; ps2_data_s1 <= ps2_data_s0; end
end

// ─── 11비트 프레임 수신기 ────────────────────────────────
reg [3:0]  rx_bit_cnt;
reg [8:0]  rx_shift;   // D7..D0, parity (9비트 순차 누적)
reg        rx_done;
reg [7:0]  rx_byte;
reg        rx_ok;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rx_bit_cnt <= 4'd0; rx_shift <= 9'd0;
        rx_done <= 1'b0; rx_byte <= 8'd0; rx_ok <= 1'b0;
    end else begin
        rx_done <= 1'b0;
        if (ps2_clk_fall && rx_en) begin
            if (rx_bit_cnt == 4'd0) begin
                // 스타트 비트: DATA=0 이어야 함
                if (!ps2_data_s1) rx_bit_cnt <= 4'd1;
            end else begin
                rx_shift <= {ps2_data_s1, rx_shift[8:1]};
                rx_bit_cnt <= rx_bit_cnt + 4'd1;
                if (rx_bit_cnt == 4'd10) begin
                    // rx_shift 최종: [8]=stop [7]=parity [6:0]=D7..D1, ps2_data_s1=D0
                    // 실제 비트 순서: D0 먼저 수신 → shift right: shift[0]=D0, ..., shift[7]=D7, shift[8]=parity, 현재bit=stop
                    rx_bit_cnt <= 4'd0;
                    rx_byte    <= rx_shift[7:0];     // D0=shift[0] ... D7=shift[7]
                    rx_ok      <= ^{rx_shift[8], rx_shift[7:0]}; // 홀수패리티: 모두 XOR=1
                    rx_done    <= 1'b1;
                end
            end
        end
    end
end

// ─── TX: 0xF4 Enable Data Reporting ─────────────────────
// 0xF4 = 1111_0100 (1의 개수=5, 홀수) → 패리티 비트=0
// tx_frame[0]=start=0, [8:1]=D0..D7, [9]=parity=0, [10]=stop=1
localparam [10:0] TX_FRAME = 11'b1_0_11110100_0;

reg [19:0] inh_cnt;
reg [3:0]  tx_bit_cnt;

// ─── 메인 FSM ────────────────────────────────────────────
localparam [2:0]
    S_WAIT_AA  = 3'd0,
    S_WAIT_00  = 3'd1,
    S_TX_INH   = 3'd2,
    S_TX_START = 3'd3,
    S_TX_BITS  = 3'd4,
    S_WAIT_ACK = 3'd5,
    S_STREAM   = 3'd6;

reg [2:0] state;
reg [1:0] pkt_cnt;
reg [7:0] pkt0, pkt1, pkt2;
reg       pkt_ready;  // 1클럭 펄스: 3바이트 패킷 완성

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= S_WAIT_AA;
        ps2_clk_oe  <= 1'b0; ps2_data_oe <= 1'b0;
        inh_cnt     <= 20'd0; tx_bit_cnt <= 4'd0;
        pkt_cnt     <= 2'd0;
        pkt0 <= 8'd0; pkt1 <= 8'd0; pkt2 <= 8'd0;
        pkt_ready   <= 1'b0;
        mouse_btn   <= 3'd0;
        irq_status_r   <= 1'b0;
        status_r       <= 2'd0;
        ctrl_enable    <= 1'b0;
        ctrl_cursor_en <= 1'b0;
        irq_enable_r   <= 1'b0;
    end else begin
        pkt_ready <= 1'b0; // 기본: 클리어

        // MMIO 쓰기
        if (sel && we) begin
            case (offset)
                OFF_CTRL:    begin ctrl_enable <= wdata[0]; ctrl_cursor_en <= wdata[1]; end
                OFF_IRQ_STS: irq_status_r <= irq_status_r & ~wdata[0]; // W1C
                OFF_IRQ_EN:  irq_enable_r <= wdata[0];
                default: ;
            endcase
        end

        case (state)
            S_WAIT_AA: begin
                if (rx_done && rx_ok && rx_byte == 8'hAA) state <= S_WAIT_00;
            end
            S_WAIT_00: begin
                if (rx_done && rx_ok && rx_byte == 8'h00) begin
                    ps2_clk_oe <= 1'b1;
                    inh_cnt    <= 20'd0;
                    state      <= S_TX_INH;
                end
            end
            S_TX_INH: begin
                if (inh_cnt >= INHIBIT_CNT - 1) begin
                    ps2_data_oe <= 1'b1; // 스타트 비트 세팅
                    state       <= S_TX_START;
                end else inh_cnt <= inh_cnt + 20'd1;
            end
            S_TX_START: begin
                ps2_clk_oe <= 1'b0; // CLK 개방 → 장치 CLK 생성 시작
                tx_bit_cnt <= 4'd0;
                state      <= S_TX_BITS;
            end
            S_TX_BITS: begin
                if (ps2_clk_fall) begin
                    if (tx_bit_cnt == 4'd10) begin
                        ps2_data_oe <= 1'b0;
                        state       <= S_WAIT_ACK;
                    end else begin
                        // oe=1 → DATA=0; oe=0 → DATA=Hi-Z=1 (풀업)
                        // tx_bit_cnt=0 → D0=TX_FRAME[1], ..., =9 → stop=TX_FRAME[10]
                        ps2_data_oe <= ~TX_FRAME[tx_bit_cnt + 1];
                        tx_bit_cnt  <= tx_bit_cnt + 4'd1;
                    end
                end
            end
            S_WAIT_ACK: begin
                if (rx_done && rx_ok && rx_byte == 8'hFA) begin
                    status_r[0] <= 1'b1; // init_done
                    state       <= S_STREAM;
                end
            end
            S_STREAM: begin
                if (ctrl_enable) begin
                    status_r[1] <= 1'b1;
                    if (rx_done && rx_ok) begin
                        case (pkt_cnt)
                            2'd0: begin pkt0 <= rx_byte; pkt_cnt <= 2'd1; end
                            2'd1: begin pkt1 <= rx_byte; pkt_cnt <= 2'd2; end
                            2'd2: begin
                                pkt2      <= rx_byte;
                                pkt_cnt   <= 2'd0;
                                mouse_btn <= pkt0[2:0];
                                pkt_ready <= 1'b1;
                                irq_status_r <= 1'b1;
                            end
                            default: pkt_cnt <= 2'd0;
                        endcase
                    end
                end
            end
            default: state <= S_WAIT_AA;
        endcase
    end
end

// ─── 좌표 갱신 (pkt_ready 다음 클럭에서 pkt2 유효) ───────
// pkt_ready 직전 클럭에 pkt2 <= rx_byte 가 실행되므로
// pkt_ready 펄스가 나오는 클럭에 pkt0/pkt1 은 이미 등록됨.
// pkt2 도 같은 클럭에 등록 완료 → pkt_ready 다음 클럭에서 사용.

reg pkt_ready_d;  // 1클럭 지연
always @(posedge clk or posedge rst) begin
    if (rst) pkt_ready_d <= 1'b0;
    else     pkt_ready_d <= pkt_ready;
end

// 좌표 계산 조합 논리
wire [8:0]  dx_sgn  = {pkt0[4], pkt1};        // 부호있는 9비트
wire [8:0]  dy_sgn  = {pkt0[5], pkt2};
wire [10:0] new_x_w = {1'b0, cursor_x} + {{2{dx_sgn[8]}}, dx_sgn};
// PS/2 양수 dy = 위로 → cursor_y 감소 → cursor_y - dy_sgn
wire [10:0] neg_dy  = ~{2'b00, dy_sgn} + 11'd1;
wire [10:0] new_y_w = {1'b0, cursor_y} + neg_dy;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cursor_x <= 10'd320;
        cursor_y <= 10'd240;
    end else if (pkt_ready_d) begin
        // X 갱신 (클램프 0~639)
        if (new_x_w[10])
            cursor_x <= 10'd0;
        else if (new_x_w[9:0] > 10'd639)
            cursor_x <= 10'd639;
        else
            cursor_x <= new_x_w[9:0];
        // Y 갱신 (클램프 0~479)
        if (new_y_w[10])
            cursor_y <= 10'd0;
        else if (new_y_w[9:0] > 10'd479)
            cursor_y <= 10'd479;
        else
            cursor_y <= new_y_w[9:0];
    end
end

// ─── MMIO 읽기 ───────────────────────────────────────────
always @(*) begin
    rdata = 32'd0;
    if (sel && !we) begin
        case (offset)
            OFF_CTRL:      rdata = {30'd0, ctrl_cursor_en, ctrl_enable};
            OFF_MOUSE_X:   rdata = {22'd0, cursor_x};
            OFF_MOUSE_Y:   rdata = {22'd0, cursor_y};
            OFF_MOUSE_BTN: rdata = {29'd0, mouse_btn};
            OFF_STATUS:    rdata = {30'd0, status_r};
            OFF_ID:        rdata = IP_ID;
            OFF_VER:       rdata = IP_VER;
            OFF_IRQ_STS:   rdata = {31'd0, irq_status_r};
            OFF_IRQ_EN:    rdata = {31'd0, irq_enable_r};
            default:       rdata = 32'd0;
        endcase
    end
end

endmodule
`default_nettype wire
