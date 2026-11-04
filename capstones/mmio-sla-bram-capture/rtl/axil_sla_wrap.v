// axil_sla_wrap.v — AXI4-Lite 슬레이브 래퍼 (sla_core 인스턴스)
// I-067 소프트 논리 분석기 IP (mmio-sla-bram-capture, T2)
// Verilog-2001. iverilog/verilator/yosys 호환.
//
// 레지스터 맵 (AXI araddr[7:0] 기준):
//   0x00  CTRL      [RW] bit0=ARM(자동 클리어), bit1=FORCE(자동 클리어),
//                        bit2=TRIG_POL(0=상승/1=하강), bit3=SRST
//   0x04  STATUS    [RO] bit0=ARMED, bit1=CAPTURING, bit2=FULL, bit3=TRIG_FOUND,
//                        [19:8]=TRIG_ADDR[11:0] (상위 비트 MSB 위치)
//   0x08  TRIG_CH   [RW] [3:0]=트리거 채널 번호 (0~15)
//   0x0C  PRETRIG   [RW] [DEPTH_LOG2-1:0]=프리트리거 샘플 수
//   0x10  CH_EN     [RW] [15:0]=채널 활성 마스크 (기본 0xFFFF)
//   0x14  RD_ADDR   [RW] [DEPTH_LOG2-1:0]=BRAM 읽기 주소
//   0x18  RD_DATA   [RO] [15:0]=RD_ADDR의 샘플 데이터 (1사이클 레이턴시, AXI 읽기 2사이클)

`default_nettype none

module axil_sla_wrap #(
    parameter DEPTH_LOG2 = 12   // sla_core와 맞춤 (테스트벤치는 8로 줄임)
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

    // 채널 입력 (메타스테이블 방지는 sla_core 내부)
    input  wire [15:0] ch_in
);

    // ── 내부 리셋 (active-high) ───────────────────────────
    wire rst = !aresetn;

    // ── 제어 레지스터 ────────────────────────────────────
    reg        ctrl_arm;        // 1사이클 펄스 (자동 클리어)
    reg        ctrl_force;      // 1사이클 펄스 (자동 클리어)
    reg        ctrl_trig_pol;
    reg        ctrl_srst;       // 1사이클 펄스 (자동 클리어)
    reg [3:0]  ctrl_trig_ch;
    reg [DEPTH_LOG2-1:0] ctrl_pretrig;
    reg [15:0] ctrl_ch_en;
    reg [DEPTH_LOG2-1:0] ctrl_rd_addr;

    // ── sla_core 출력 ───────────────────────────────────
    wire [15:0]            sample_out;
    wire                   armed;
    wire                   capturing;
    wire                   full;
    wire                   trig_found;
    wire [DEPTH_LOG2-1:0]  trig_addr;

    // STATUS[19:8]=TRIG_ADDR를 항상 12비트 필드에 넣기 위한 zero-extension
    // (DEPTH_LOG2 <= 12 범위에서만 사용)
    wire [11:0]            trig_addr_12 = trig_addr;

    // ── sla_core 인스턴스 ────────────────────────────────
    sla_core #(
        .DEPTH_LOG2(DEPTH_LOG2)
    ) u_core (
        .clk        (aclk),
        .rst        (rst),
        .arm        (ctrl_arm),
        .force_trig (ctrl_force),
        .srst       (ctrl_srst),
        .trig_ch    (ctrl_trig_ch),
        .trig_pol   (ctrl_trig_pol),
        .pretrig    (ctrl_pretrig),
        .ch_en      (ctrl_ch_en),
        .ch_in      (ch_in),
        .rd_addr    (ctrl_rd_addr),
        .sample_out (sample_out),
        .armed      (armed),
        .capturing  (capturing),
        .full       (full),
        .trig_found (trig_found),
        .trig_addr  (trig_addr)
    );

    // ── Write FSM ─────────────────────────────────────────
    reg       aw_pend;
    reg [7:0] aw_addr_r;
    reg       w_pend;
    reg [31:0] w_data_r;

    always @(posedge aclk) begin
        if (rst) begin
            s_awready    <= 1'b0;
            s_wready     <= 1'b0;
            s_bvalid     <= 1'b0;
            s_bresp      <= 2'b00;
            aw_pend      <= 1'b0;
            w_pend       <= 1'b0;
            ctrl_arm     <= 1'b0;
            ctrl_force   <= 1'b0;
            ctrl_trig_pol <= 1'b0;
            ctrl_srst    <= 1'b0;
            ctrl_trig_ch <= 4'd0;
            ctrl_pretrig <= {DEPTH_LOG2{1'b0}};
            ctrl_ch_en   <= 16'hFFFF;
            ctrl_rd_addr <= {DEPTH_LOG2{1'b0}};
        end else begin
            // 1사이클 펄스 자동 클리어
            ctrl_arm   <= 1'b0;
            ctrl_force <= 1'b0;
            ctrl_srst  <= 1'b0;

            // awready 핸드셰이크
            if (s_awvalid && !aw_pend && !s_bvalid) begin
                s_awready <= 1'b1;
                aw_pend   <= 1'b1;
                aw_addr_r <= s_awaddr;
            end else begin
                s_awready <= 1'b0;
            end

            // wready 핸드셰이크
            if (s_wvalid && !w_pend && !s_bvalid) begin
                s_wready <= 1'b1;
                w_pend   <= 1'b1;
                w_data_r <= s_wdata;
            end else begin
                s_wready <= 1'b0;
            end

            // 주소와 데이터 모두 수신 → 레지스터 쓰기 + bresp
            if (aw_pend && w_pend && !s_bvalid) begin
                case (aw_addr_r[7:2])
                    6'h00: begin  // CTRL
                        ctrl_arm     <= w_data_r[0];
                        ctrl_force   <= w_data_r[1];
                        ctrl_trig_pol <= w_data_r[2];
                        ctrl_srst    <= w_data_r[3];
                    end
                    6'h02: ctrl_trig_ch  <= w_data_r[3:0];       // TRIG_CH
                    6'h03: ctrl_pretrig  <= w_data_r[DEPTH_LOG2-1:0]; // PRETRIG
                    6'h04: ctrl_ch_en    <= w_data_r[15:0];      // CH_EN
                    6'h05: ctrl_rd_addr  <= w_data_r[DEPTH_LOG2-1:0]; // RD_ADDR
                    default: ;  // 나머지는 무시, OKAY 반환
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
    // RD_DATA는 sla_core에서 1사이클 레이턴시가 있으므로
    // arready를 assert한 다음 사이클에 rvalid를 올린다.
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
                    6'h00: s_rdata <= {28'b0, ctrl_srst, ctrl_trig_pol,
                                       ctrl_force, ctrl_arm};  // CTRL 읽기
                    6'h01: s_rdata <= {12'b0, trig_addr_12,
                                       4'b0, trig_found, full, capturing, armed}; // STATUS
                    6'h02: s_rdata <= {28'b0, ctrl_trig_ch};   // TRIG_CH
                    6'h03: s_rdata <= {{(32-DEPTH_LOG2){1'b0}}, ctrl_pretrig}; // PRETRIG
                    6'h04: s_rdata <= {16'b0, ctrl_ch_en};     // CH_EN
                    6'h05: s_rdata <= {{(32-DEPTH_LOG2){1'b0}}, ctrl_rd_addr}; // RD_ADDR
                    6'h06: s_rdata <= {16'b0, sample_out};     // RD_DATA
                    default: s_rdata <= 32'hDEAD_BEEF;
                endcase
            end

            if (s_rvalid && s_rready)
                s_rvalid <= 1'b0;
        end
    end

endmodule

`default_nettype wire
