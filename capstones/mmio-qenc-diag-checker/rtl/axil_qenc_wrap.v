// axil_qenc_wrap.v — AXI4-Lite 슬레이브 래퍼 (qenc_diag 인스턴스)
// I-016 엔코더 난이도 사다리 (mmio-qenc-diag-checker, T2)
// Verilog-2001. iverilog/verilator/yosys 호환.
//
// 레지스터 맵 (AXI araddr[7:0] 기준):
//   0x00  CTRL      [RW] bit0=EN, bit1=SRST, bit2=WINDOW_EN
//   0x04  POSITION  [RO] 32비트 부호 있는 위치
//   0x08  VELOCITY  [RO] 16비트 최근 10ms 창 속도 (상위 16비트 0)
//   0x0C  STATUS    [RO] bit0=DIR, bit1=OVFL, bit2=ERR_LATCH
//   0x10  ERROR_CNT [RO] 16비트 오류 누산 (상위 16비트 0)

`default_nettype none

module axil_qenc_wrap #(
    parameter WINDOW_CYCLES = 1_000_000  // 10 ms @ 100 MHz
) (
    // AXI 클럭/리셋
    input  wire        aclk,
    input  wire        aresetn,  // active-low

    // AXI4-Lite Write Channel
    input  wire [7:0]  s_awaddr,
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
    input  wire [7:0]  s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready,

    // 엔코더 외부 핀 (메타스테이블 방지는 qenc_diag 내부)
    input  wire        enc_a,
    input  wire        enc_b
);

    // ── 내부 리셋 (active-high) ───────────────────────────
    wire rst = !aresetn;

    // ── CTRL 레지스터 ────────────────────────────────────
    reg        ctrl_en;
    reg        ctrl_srst;
    reg        ctrl_window_en;

    // ── qenc_diag 출력 ───────────────────────────────────
    wire [31:0] position;
    wire [15:0] velocity;
    wire        dir;
    wire        ovfl;
    wire        err_latch;
    wire [15:0] error_cnt;

    // ── qenc_diag 인스턴스 ───────────────────────────────
    qenc_diag #(
        .WINDOW_CYCLES(WINDOW_CYCLES)
    ) u_core (
        .clk       (aclk),
        .rst       (rst),
        .en        (ctrl_en),
        .srst      (ctrl_srst),
        .window_en (ctrl_window_en),
        .a_in      (enc_a),
        .b_in      (enc_b),
        .position  (position),
        .velocity  (velocity),
        .dir       (dir),
        .ovfl      (ovfl),
        .err_latch (err_latch),
        .error_cnt (error_cnt)
    );

    // ── Write FSM ─────────────────────────────────────────
    // 한 사이클에 awready+wready 동시 assert, 다음 사이클에 bvalid
    reg aw_pend;
    reg [7:0] aw_addr_r;
    reg w_pend;
    reg [31:0] w_data_r;

    always @(posedge aclk) begin
        if (rst) begin
            s_awready  <= 1'b0;
            s_wready   <= 1'b0;
            s_bvalid   <= 1'b0;
            s_bresp    <= 2'b00;
            aw_pend    <= 1'b0;
            w_pend     <= 1'b0;
            ctrl_en        <= 1'b0;
            ctrl_srst      <= 1'b0;
            ctrl_window_en <= 1'b0;
        end else begin
            // SRST는 1사이클 펄스
            ctrl_srst <= 1'b0;

            // awready 핸드셰이크
            if (s_awvalid && !aw_pend) begin
                s_awready <= 1'b1;
                aw_pend   <= 1'b1;
                aw_addr_r <= s_awaddr;
            end else begin
                s_awready <= 1'b0;
            end

            // wready 핸드셰이크
            if (s_wvalid && !w_pend) begin
                s_wready <= 1'b1;
                w_pend   <= 1'b1;
                w_data_r <= s_wdata;
            end else begin
                s_wready <= 1'b0;
            end

            // 주소와 데이터 모두 수신 → 레지스터 쓰기 + bresp
            if (aw_pend && w_pend && !s_bvalid) begin
                // CTRL(0x00) 만 쓰기 가능, 나머지는 무시(OKAY 반환)
                if (aw_addr_r[7:2] == 6'h00) begin
                    ctrl_en        <= w_data_r[0];
                    ctrl_srst      <= w_data_r[1];
                    ctrl_window_en <= w_data_r[2];
                end
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
    reg [7:0] ar_addr_r;

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
                case (ar_addr_r[7:2])
                    6'h00: s_rdata <= {29'b0, ctrl_window_en, ctrl_srst, ctrl_en};
                    6'h01: s_rdata <= position;
                    6'h02: s_rdata <= {16'b0, velocity};
                    6'h03: s_rdata <= {29'b0, err_latch, ovfl, dir};
                    6'h04: s_rdata <= {16'b0, error_cnt};
                    default: s_rdata <= 32'hDEAD_BEEF;
                endcase
            end

            if (s_rvalid && s_rready)
                s_rvalid <= 1'b0;
        end
    end

endmodule

`default_nettype wire
