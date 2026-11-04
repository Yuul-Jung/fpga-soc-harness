// axil_wdt_wrap.v — AXI4-Lite 슬레이브 래퍼 (wdt_core 인스턴스)
// I-070 AXI4-Lite 워치독 IP (mmio-wdt-tier1, T1)
// Verilog-2001. iverilog/verilator/yosys 호환.
//
// 레지스터 맵 (AXI araddr[15:0] 기준):
//   0x0000  CTRL      [RW] bit0=ENABLE, bit1=SRST(자동 클리어)
//   0x0004  LOAD      [RW] [31:0]=카운트다운 초기값 (100MHz × 값 = 타임아웃)
//   0x0008  STATUS    [RO] bit0=TIMEOUT_LAT, bit1=RUNNING
//   0x000C  KICK      [WO] 아무 값 쓰면 카운터를 LOAD 값으로 재적재
//   0x0010  COUNT     [RO] 현재 카운터 값
//   0xFFF0  ID_REG    [RO] 0x57445431 ("WDT1")
//   0xFFF4  VER_REG   [RO] 0x00010000 (v1.0.0)
//   0xFFF8  IRQ_EN    [RW] bit0=타임아웃 인터럽트 활성
//   0xFFFC  IRQ_PEND  [RW] bit0=인터럽트 대기 중, 1 쓰면 클리어
//
// 출력:
//   wdt_rst  — 타임아웃 시 1사이클 리셋 펄스 (SoC 시스템 리셋 연결용)
//   wdt_irq  — 인터럽트 레벨 신호 (IRQ_EN=1 && IRQ_PEND=1)

`default_nettype none

module axil_wdt_wrap (
    // AXI 클럭/리셋
    input  wire        aclk,
    input  wire        aresetn,  // active-low

    // AXI4-Lite Write Channel
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

    // AXI4-Lite Read Channel
    input  wire [15:0] s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // 기능 출력
    output wire        wdt_rst,  // 타임아웃 리셋 펄스
    output wire        wdt_irq   // 인터럽트 출력 (레벨)
);

    // ── 내부 리셋 (active-high) ───────────────────────────
    wire rst = !aresetn;

    // ── 제어 레지스터 ────────────────────────────────────
    reg        ctrl_enable;
    reg        ctrl_srst;       // 1사이클 펄스 (자동 클리어)
    reg [31:0] ctrl_load;
    reg        ctrl_kick;       // 1사이클 펄스 (자동 클리어)
    reg        irq_en;
    reg        irq_pend;

    // ── wdt_core 출력 ───────────────────────────────────
    wire [31:0] count_out;
    wire        timeout_pulse;
    wire        timeout_lat;
    wire        running;

    // ── wdt_core 인스턴스 ────────────────────────────────
    wdt_core #(
        .CNT_W(32)
    ) u_core (
        .clk        (aclk),
        .rst        (rst),
        .enable     (ctrl_enable),
        .kick       (ctrl_kick),
        .srst       (ctrl_srst),
        .load_val   (ctrl_load),
        .count_out  (count_out),
        .timeout    (timeout_pulse),
        .timeout_lat(timeout_lat),
        .running    (running)
    );

    // ── 인터럽트 / 리셋 출력 ────────────────────────────
    // IRQ_PEND는 AXI 쓰기 도메인에서 갱신; timeout_pulse는 wdt_core 클럭 도메인
    // (같은 aclk를 쓰므로 동기 처리 가능)
    always @(posedge aclk) begin
        if (rst) begin
            irq_pend <= 1'b0;
        end else begin
            if (timeout_pulse && irq_en)
                irq_pend <= 1'b1;
            // IRQ_PEND[0] 쓰기 클리어는 Write FSM에서 처리
        end
    end

    assign wdt_rst = timeout_pulse;              // 1사이클 리셋 펄스
    assign wdt_irq = irq_en && irq_pend;         // 레벨 인터럽트

    // ── Write FSM ─────────────────────────────────────────
    reg       aw_pend;
    reg [15:0] aw_addr_r;
    reg       w_pend;
    reg [31:0] w_data_r;

    always @(posedge aclk) begin
        if (rst) begin
            s_awready  <= 1'b0;
            s_wready   <= 1'b0;
            s_bvalid   <= 1'b0;
            s_bresp    <= 2'b00;
            aw_pend    <= 1'b0;
            w_pend     <= 1'b0;
            ctrl_enable <= 1'b0;
            ctrl_srst  <= 1'b0;
            ctrl_load  <= 32'd0;
            ctrl_kick  <= 1'b0;
            irq_en     <= 1'b0;
        end else begin
            // 1사이클 펄스 자동 클리어
            ctrl_srst <= 1'b0;
            ctrl_kick <= 1'b0;

            // awready 핸드셰이크 (!s_bvalid: re-capture 방지)
            if (s_awvalid && !aw_pend && !s_bvalid) begin
                s_awready <= 1'b1;
                aw_pend   <= 1'b1;
                aw_addr_r <= s_awaddr;
            end else begin
                s_awready <= 1'b0;
            end

            // wready 핸드셰이크 (!s_bvalid: re-capture 방지)
            if (s_wvalid && !w_pend && !s_bvalid) begin
                s_wready <= 1'b1;
                w_pend   <= 1'b1;
                w_data_r <= s_wdata;
            end else begin
                s_wready <= 1'b0;
            end

            // 주소와 데이터 모두 수신 → 레지스터 쓰기 + bresp
            if (aw_pend && w_pend && !s_bvalid) begin
                case (aw_addr_r)
                    16'h0000: begin  // CTRL
                        ctrl_enable <= w_data_r[0];
                        ctrl_srst   <= w_data_r[1];
                    end
                    16'h0004: ctrl_load  <= w_data_r;         // LOAD
                    16'h000C: ctrl_kick  <= 1'b1;             // KICK (write-only)
                    16'hFFF8: irq_en     <= w_data_r[0];      // IRQ_EN
                    16'hFFFC: begin  // IRQ_PEND: W1C (bit0)
                        if (w_data_r[0])
                            irq_pend <= 1'b0;
                    end
                    default: ;  // STATUS, COUNT, ID, VER: 무시, OKAY 반환
                endcase
                s_bvalid <= 1'b1;
                s_bresp  <= 2'b00;  // OKAY
                aw_pend  <= 1'b0;
                w_pend   <= 1'b0;
            end

            if (s_bvalid && s_bready)
                s_bvalid <= 1'b0;
        end
    end

    // ── Read FSM ──────────────────────────────────────────
    reg [15:0] ar_addr_r;

    always @(posedge aclk) begin
        if (rst) begin
            s_arready <= 1'b0;
            s_rvalid  <= 1'b0;
            s_rdata   <= 32'h0;
            s_rresp   <= 2'b00;
        end else begin
            if (s_arvalid && !s_rvalid) begin
                s_arready <= 1'b1;
                ar_addr_r <= s_araddr;
            end else begin
                s_arready <= 1'b0;
            end

            if (s_arready && s_arvalid) begin
                s_rvalid <= 1'b1;
                s_rresp  <= 2'b00;
                case (ar_addr_r)
                    16'h0000: s_rdata <= {30'b0, ctrl_srst, ctrl_enable};    // CTRL
                    16'h0004: s_rdata <= ctrl_load;                           // LOAD
                    16'h0008: s_rdata <= {30'b0, running, timeout_lat};       // STATUS
                    16'h000C: s_rdata <= 32'h0;                               // KICK: 읽으면 0
                    16'h0010: s_rdata <= count_out;                           // COUNT
                    16'hFFF0: s_rdata <= 32'h57445431;                        // ID ("WDT1")
                    16'hFFF4: s_rdata <= 32'h00010000;                        // VER (1.0.0)
                    16'hFFF8: s_rdata <= {31'b0, irq_en};                     // IRQ_EN
                    16'hFFFC: s_rdata <= {31'b0, irq_pend};                   // IRQ_PEND
                    default:  s_rdata <= 32'hDEAD_BEEF;
                endcase
            end

            if (s_rvalid && s_rready)
                s_rvalid <= 1'b0;
        end
    end

endmodule

`default_nettype wire
