// basys3_ps2_mouse_cursor_top.v
// Basys3 보드 최상위 래퍼
// PS/2 마우스 → VGA 커서 오버레이 (스탠드얼론 보드 시연용)
// Verilog-2001. iverilog/verilator/yosys 호환.
// 원작자: 하네스 자체 작성 (2026-11-04)

`default_nettype none

module basys3_ps2_mouse_cursor_top (
    input  wire        CLK_100,    // W5, 100 MHz
    input  wire        BTNC,       // U18, 비동기 리셋 (active-high)

    // PS/2 마우스 (오픈드레인 양방향)
    inout  wire        PS2_CLK,    // C17
    inout  wire        PS2_DATA,   // B17

    // VGA 출력
    output wire        VGA_HS,     // P19
    output wire        VGA_VS,     // R19
    output wire [3:0]  VGA_R,      // 4비트 (N19 J19 H19 N18)
    output wire [3:0]  VGA_G,      // 4비트 (J17 H17 G17 D17)
    output wire [3:0]  VGA_B,      // 4비트 (N17 P14 R18 P15)

    // 상태 LED
    output wire [3:0]  LED         // U16 E19 U19 V19
);

// ─── PS/2 오픈드레인 버퍼 ───────────────────────────────
wire ps2_clk_oe, ps2_data_oe;
wire ps2_clk_in  = PS2_CLK;
wire ps2_data_in = PS2_DATA;

// oe=1 → 0 구동, oe=0 → Hi-Z (외부 풀업에 의해 1)
assign PS2_CLK  = ps2_clk_oe  ? 1'b0 : 1'bz;
assign PS2_DATA = ps2_data_oe ? 1'b0 : 1'bz;

// ─── 초기화 FSM: 리셋 후 2클럭에서 CTRL, IRQ_ENABLE 설정 ─
// 실제 SoC 연결 시 이 FSM을 제거하고 AXI4-Lite 래퍼로 교체

// ─── 내부 리셋: BTNC (비동기 하이 활성) ─────────────────
wire rst = BTNC;

// ─── PS/2 마우스 호스트 ──────────────────────────────────
wire [9:0]  cursor_x, cursor_y;
wire [2:0]  mouse_btn;
wire        irq_out;

// ctrl_enable을 항상 1로 묶어두는 초기화 FSM 없이,
// ps2_mouse_host 내부 리셋 후 ctrl_enable=0 상태로 시작.
// 보드 시연을 위해 ctrl은 항상 enable로 고정.
// (실제 CPU 연결 시 MMIO 쓰기로 활성화)
// 간단한 보드 시연: sel/we 없이 호스트 IP 내부 ctrl_enable을 1로 묶는다.
// ps2_mouse_host는 ctrl_enable=0이면 패킷을 무시하므로,
// 자동 활성화를 위해 sel+we 1클럭 펄스를 초기화 FSM에서 보낸다.

wire [31:0] mmio_rdata;
reg  [1:0]  init_fsm;
reg         init_sel, init_we;
reg  [31:0] init_wdata;
reg  [15:0] init_offset;

always @(posedge CLK_100 or posedge rst) begin
    if (rst) begin
        init_fsm    <= 2'd0;
        init_sel    <= 1'b0;
        init_we     <= 1'b0;
        init_wdata  <= 32'd0;
        init_offset <= 16'd0;
    end else begin
        init_sel <= 1'b0; init_we <= 1'b0;
        case (init_fsm)
            2'd0: begin
                // CTRL = enable + cursor_en (bit1:0 = 2'b11)
                init_sel    <= 1'b1;
                init_we     <= 1'b1;
                init_offset <= 16'h0000;
                init_wdata  <= 32'h0000_0003;
                init_fsm    <= 2'd1;
            end
            2'd1: begin
                // IRQ_ENABLE bit[0] = 1
                init_sel    <= 1'b1;
                init_we     <= 1'b1;
                init_offset <= 16'hFFFC;
                init_wdata  <= 32'h0000_0001;
                init_fsm    <= 2'd2;
            end
            2'd2: init_fsm <= 2'd3;  // idle
            2'd3: ;
        endcase
    end
end

ps2_mouse_host #(.INHIBIT_CNT(10000)) u_ps2 (
    .clk          (CLK_100),
    .rst          (rst),
    .sel          (init_sel),
    .we           (init_we),
    .offset       (init_offset),
    .wdata        (init_wdata),
    .rdata        (mmio_rdata),
    .cursor_x     (cursor_x),
    .cursor_y     (cursor_y),
    .mouse_btn    (mouse_btn),
    .irq_out      (irq_out),
    .ps2_clk_in   (ps2_clk_in),
    .ps2_data_in  (ps2_data_in),
    .ps2_clk_oe   (ps2_clk_oe),
    .ps2_data_oe  (ps2_data_oe)
);

// ─── VGA 타이밍 + 커서 ──────────────────────────────────
vga_sync_cursor u_vga (
    .clk       (CLK_100),
    .rst       (rst),
    .cursor_x  (cursor_x),
    .cursor_y  (cursor_y),
    .cursor_en (1'b1),  // 항상 활성
    .hs        (VGA_HS),
    .vs        (VGA_VS),
    .red       (VGA_R),
    .green     (VGA_G),
    .blue      (VGA_B)
);

// ─── LED 상태 표시 ──────────────────────────────────────
// LED[3]=irq, LED[2]=M_BTN, LED[1]=R_BTN, LED[0]=L_BTN
assign LED[3] = irq_out;
assign LED[2] = mouse_btn[2];  // 미들 버튼
assign LED[1] = mouse_btn[1];  // 오른쪽 버튼
assign LED[0] = mouse_btn[0];  // 왼쪽 버튼

endmodule
`default_nettype wire
