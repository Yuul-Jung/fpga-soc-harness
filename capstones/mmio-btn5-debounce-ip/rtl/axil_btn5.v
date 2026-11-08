// axil_btn5.v — AXI4-Lite 5-버튼 디바운스·긴누름·에지검출 IP
// 버튼: btn[4]=BTNC, btn[3]=BTNU, btn[2]=BTND, btn[1]=BTNL, btn[0]=BTNR
// 레지스터:
//   0x00 CTRL        RW  bit[0]=irq_global_en, bit[1]=irq_clr_all(auto-clear)
//   0x04 STATUS      RO  bit[4:0]=디바운스 출력(현재 안정화 상태)
//   0x08 LONGPRESS   RO  bit[4:0]=긴 누름 플래그
//   0x0C DEBOUNCE_MS RW  디바운스 임계값(ms, 기본 5)
//   0x10 LONGPRESS_MS RW 긴 누름 임계값(ms, 기본 1000)
//   0x14 IRQ_EN      RW  bit[4:0]=버튼별 IRQ 활성화 마스크
//   0x18 IRQ_STATUS  RW  bit[4:0]=이벤트 플래그 (W1C)
//   0x1C VERSION     RO  0x00010001
// Verilog-2001. No external IP. iverilog/verilator/yosys 호환.
// Copyright (c) 2026 jungbw92@gmail.com — original source for mmio-btn5-debounce-ip

`default_nettype none
`timescale 1ns/1ps

module axil_btn5 #(
    parameter CLK_MHZ      = 100,  // 클럭 주파수(MHz)
    parameter DEB_MS_DEF   = 5,    // 기본 디바운스 임계값(ms)
    parameter LP_MS_DEF    = 1000  // 기본 긴 누름 임계값(ms)
)(
    input  wire        clk,
    input  wire        rst,          // active-high 동기 리셋

    // 버튼 입력 (동기화 전 로우)
    input  wire [4:0]  btn_in,       // [4]=BTNC, [3]=BTNU, [2]=BTND, [1]=BTNL, [0]=BTNR

    // IRQ 출력
    output wire        irq,

    // AXI4-Lite Slave 포트
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    output wire [1:0]  s_axil_bresp,
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    input  wire [7:0]  s_axil_araddr,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,
    output reg  [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp
);

// ─── 파라미터 및 로컬파라미터 ────────────────────────────────────
localparam CLK_PER_MS = CLK_MHZ * 1000;  // 1ms당 클럭 수 (100_000)
// 최대 카운터 값: DEBOUNCE_MS=500, LP_MS=2000
// 디바운스 카운터: 20비트 (최대 100_000×500/1000 = 100_000 필요, 실제 100_000×500 불가, 임계값 ≤4095 ms)
// 카운터 너비: CLK_PER_MS * max_ms. 500ms → 50_000_000 → 26비트. 27비트 사용.
localparam CNT_W = 27;

// AXI 주소 오프셋
localparam ADDR_CTRL        = 8'h00;
localparam ADDR_STATUS      = 8'h04;
localparam ADDR_LONGPRESS   = 8'h08;
localparam ADDR_DEBOUNCE_MS = 8'h0C;
localparam ADDR_LONGPRESS_MS= 8'h10;
localparam ADDR_IRQ_EN      = 8'h14;
localparam ADDR_IRQ_STATUS  = 8'h18;
localparam ADDR_VERSION     = 8'h1C;

localparam VERSION_VAL = 32'h00010001;

// ─── 레지스터 ────────────────────────────────────────────────────
reg        reg_irq_global_en;
reg [31:0] reg_debounce_ms;   // 디바운스 임계값(ms)
reg [31:0] reg_longpress_ms;  // 긴 누름 임계값(ms)
reg [4:0]  reg_irq_en;        // 버튼별 IRQ 활성화 마스크
reg [4:0]  reg_irq_status;    // 버튼별 이벤트 플래그 (W1C)

// ─── 버튼 동기화(2단 FF) ────────────────────────────────────────
reg [4:0] btn_sync0, btn_sync1;
always @(posedge clk) begin
    if (rst) begin
        btn_sync0 <= 5'b0;
        btn_sync1 <= 5'b0;
    end else begin
        btn_sync0 <= btn_in;
        btn_sync1 <= btn_sync0;
    end
end

// ─── 디바운스 FSM(카운터 방식) ×5 ───────────────────────────────
// 각 버튼: 카운터가 debounce_thr 이상이면 btn_stable 세트
reg  [CNT_W-1:0] deb_cnt   [4:0];
reg  [4:0]       btn_stable;      // 디바운스 완료 출력
reg  [4:0]       btn_prev;        // 에지 검출용

wire [CNT_W-1:0] debounce_thr;
assign debounce_thr = (reg_debounce_ms < 1) ? CLK_PER_MS :
                      reg_debounce_ms * CLK_PER_MS;

integer bi;
always @(posedge clk) begin
    if (rst) begin
        for (bi = 0; bi < 5; bi = bi + 1) begin
            deb_cnt[bi]   <= {CNT_W{1'b0}};
            btn_stable[bi] <= 1'b0;
        end
        btn_prev <= 5'b0;
    end else begin
        btn_prev <= btn_stable;
        for (bi = 0; bi < 5; bi = bi + 1) begin
            if (btn_sync1[bi] == btn_stable[bi]) begin
                // 입력이 현재 안정화 상태와 같음 → 카운터 리셋
                deb_cnt[bi] <= {CNT_W{1'b0}};
            end else begin
                // 입력이 다름 → 카운터 증가
                if (deb_cnt[bi] >= debounce_thr) begin
                    // 임계값 도달 → 상태 전환
                    btn_stable[bi] <= btn_sync1[bi];
                    deb_cnt[bi]    <= {CNT_W{1'b0}};
                end else begin
                    deb_cnt[bi] <= deb_cnt[bi] + 1'b1;
                end
            end
        end
    end
end

// ─── 에지 검출 ────────────────────────────────────────────────────
wire [4:0] press_edge   = btn_stable & ~btn_prev;   // 눌림 에지
wire [4:0] release_edge = ~btn_stable & btn_prev;   // 놓임 에지

// ─── 긴 누름 카운터 ×5 ──────────────────────────────────────────
reg  [CNT_W-1:0] lp_cnt    [4:0];
reg  [4:0]       lp_flag;    // 긴 누름 플래그 (눌린 상태 중 임계값 초과)
reg  [4:0]       lp_fired;   // IRQ 발생 방지용: 한 번만 발생

wire [CNT_W-1:0] longpress_thr;
assign longpress_thr = (reg_longpress_ms < 1) ? (CLK_PER_MS * 1000) :
                       reg_longpress_ms * CLK_PER_MS;

integer li;
always @(posedge clk) begin
    if (rst) begin
        for (li = 0; li < 5; li = li + 1) begin
            lp_cnt[li]  <= {CNT_W{1'b0}};
            lp_flag[li] <= 1'b0;
            lp_fired[li]<= 1'b0;
        end
    end else begin
        for (li = 0; li < 5; li = li + 1) begin
            if (!btn_stable[li]) begin
                // 버튼 놓임 → 카운터 클리어, 긴 누름 플래그 클리어
                lp_cnt[li]  <= {CNT_W{1'b0}};
                lp_flag[li] <= 1'b0;
                lp_fired[li]<= 1'b0;
            end else begin
                // 버튼 눌림 유지 → 카운터 증가
                if (lp_cnt[li] < longpress_thr) begin
                    lp_cnt[li] <= lp_cnt[li] + 1'b1;
                end else begin
                    lp_flag[li] <= 1'b1;
                end
            end
        end
    end
end

// 긴 누름 IRQ 에지(처음 임계값 도달 순간 1클럭)
reg [4:0] lp_flag_prev;
always @(posedge clk) begin
    if (rst) lp_flag_prev <= 5'b0;
    else     lp_flag_prev <= lp_flag;
end
wire [4:0] lp_edge = lp_flag & ~lp_flag_prev;  // 긴 누름 도달 에지

// ─── IRQ 로직 ────────────────────────────────────────────────────
// 이벤트: press_edge OR release_edge OR lp_edge, 마스크 AND
wire [4:0] event_any = press_edge | release_edge | lp_edge;

always @(posedge clk) begin
    if (rst) begin
        reg_irq_status <= 5'b0;
    end else begin
        // 이벤트 발생 시 set (마스크와 무관하게 플래그는 세움, IRQ_EN은 irq 출력에만 영향)
        reg_irq_status <= reg_irq_status | event_any;
    end
end

assign irq = reg_irq_global_en & |(reg_irq_status & reg_irq_en);

// ─── AXI4-Lite 슬레이브 ─────────────────────────────────────────
// BRESP, RRESP 항상 OKAY(2'b00)
assign s_axil_bresp = 2'b00;
assign s_axil_rresp = 2'b00;

// 쓰기 채널
reg [7:0] wr_addr;
reg       wr_addr_ok;
reg       wr_data_ok;

always @(posedge clk) begin
    if (rst) begin
        s_axil_awready <= 1'b0;
        s_axil_wready  <= 1'b0;
        s_axil_bvalid  <= 1'b0;
        wr_addr        <= 8'h00;
        wr_addr_ok     <= 1'b0;
        wr_data_ok     <= 1'b0;
    end else begin
        // 주소 핸드셰이크
        s_axil_awready <= 1'b0;
        if (s_axil_awvalid && !wr_addr_ok) begin
            s_axil_awready <= 1'b1;
            wr_addr        <= s_axil_awaddr;
            wr_addr_ok     <= 1'b1;
        end

        // 데이터 핸드셰이크
        s_axil_wready <= 1'b0;
        if (s_axil_wvalid && !wr_data_ok) begin
            s_axil_wready <= 1'b1;
            wr_data_ok    <= 1'b1;
        end

        // 응답
        if (s_axil_bvalid && s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
            wr_addr_ok    <= 1'b0;
            wr_data_ok    <= 1'b0;
        end

        // 레지스터 쓰기 (주소+데이터 모두 준비된 직후 단 1클럭)
        if (wr_addr_ok && wr_data_ok && !s_axil_bvalid) begin
            s_axil_bvalid <= 1'b1;
            case (wr_addr[7:0])
                ADDR_CTRL: begin
                    if (s_axil_wstrb[0]) begin
                        reg_irq_global_en <= s_axil_wdata[0];
                        if (s_axil_wdata[1]) begin
                            // irq_clr_all: 모든 IRQ_STATUS 클리어
                            reg_irq_status <= 5'b0;
                        end
                    end
                end
                ADDR_DEBOUNCE_MS: begin
                    if (s_axil_wstrb[0]) reg_debounce_ms[ 7: 0] <= s_axil_wdata[ 7: 0];
                    if (s_axil_wstrb[1]) reg_debounce_ms[15: 8] <= s_axil_wdata[15: 8];
                    if (s_axil_wstrb[2]) reg_debounce_ms[23:16] <= s_axil_wdata[23:16];
                    if (s_axil_wstrb[3]) reg_debounce_ms[31:24] <= s_axil_wdata[31:24];
                end
                ADDR_LONGPRESS_MS: begin
                    if (s_axil_wstrb[0]) reg_longpress_ms[ 7: 0] <= s_axil_wdata[ 7: 0];
                    if (s_axil_wstrb[1]) reg_longpress_ms[15: 8] <= s_axil_wdata[15: 8];
                    if (s_axil_wstrb[2]) reg_longpress_ms[23:16] <= s_axil_wdata[23:16];
                    if (s_axil_wstrb[3]) reg_longpress_ms[31:24] <= s_axil_wdata[31:24];
                end
                ADDR_IRQ_EN: begin
                    if (s_axil_wstrb[0]) reg_irq_en <= s_axil_wdata[4:0];
                end
                ADDR_IRQ_STATUS: begin
                    // W1C: 1을 쓰면 해당 bit 클리어
                    if (s_axil_wstrb[0])
                        reg_irq_status <= reg_irq_status & ~s_axil_wdata[4:0];
                end
                default: ; // 읽기 전용 또는 미구현 주소
            endcase
        end
    end
end

// 읽기 채널
always @(posedge clk) begin
    if (rst) begin
        s_axil_arready <= 1'b0;
        s_axil_rvalid  <= 1'b0;
        s_axil_rdata   <= 32'h0;
    end else begin
        s_axil_arready <= 1'b0;
        if (s_axil_arvalid && !s_axil_rvalid) begin
            s_axil_arready <= 1'b1;
            s_axil_rvalid  <= 1'b1;
            case (s_axil_araddr[7:0])
                ADDR_CTRL:         s_axil_rdata <= {30'b0, 1'b0, reg_irq_global_en};
                ADDR_STATUS:       s_axil_rdata <= {27'b0, btn_stable};
                ADDR_LONGPRESS:    s_axil_rdata <= {27'b0, lp_flag};
                ADDR_DEBOUNCE_MS:  s_axil_rdata <= reg_debounce_ms;
                ADDR_LONGPRESS_MS: s_axil_rdata <= reg_longpress_ms;
                ADDR_IRQ_EN:       s_axil_rdata <= {27'b0, reg_irq_en};
                ADDR_IRQ_STATUS:   s_axil_rdata <= {27'b0, reg_irq_status};
                ADDR_VERSION:      s_axil_rdata <= VERSION_VAL;
                default:           s_axil_rdata <= 32'hDEAD_BEEF;
            endcase
        end
        if (s_axil_rvalid && s_axil_rready)
            s_axil_rvalid <= 1'b0;
    end
end

// ─── 초기화 ───────────────────────────────────────────────────────
initial begin
    reg_irq_global_en = 1'b0;
    reg_debounce_ms   = DEB_MS_DEF;
    reg_longpress_ms  = LP_MS_DEF;
    reg_irq_en        = 5'b0;
    reg_irq_status    = 5'b0;
end

endmodule
`default_nettype wire
