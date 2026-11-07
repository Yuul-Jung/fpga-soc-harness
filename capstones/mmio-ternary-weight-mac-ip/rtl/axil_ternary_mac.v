// axil_ternary_mac.v — AXI4-Lite 슬레이브 + 삼진 가중치 MAC 제어
// Verilog-2001 — iverilog / verilator / yosys 호환
//
// 레지스터맵 (8비트 주소, 로컬 오프셋):
//   0x00 STATUS   RO  bit[0]=DONE, bit[1]=BUSY
//   0x04 CTRL     WO  bit[0]=START(자동클리어), bit[1]=CLR_DONE, bit[7:4]=VECLEN(0=1,15=16)
//   0x08 W_DATA   WO  2비트×16요소 가중치 패킹 (bit[1:0]=w[0],...,bit[31:30]=w[15])
//   0x0C W_ADDR   WO  가중치 블록 주소 (현재 0만 유효; 무시)
//   0x10 V_ADDR   WO  활성화 쓰기 주소 (0~15)
//   0x14 V_DATA   WO  활성화 바이트 (부호 있는 8비트) — V_ADDR 선행 필요
//   0x18 RESULT   RO  내적 결과 (부호 확장 32비트)

`timescale 1ns/1ps

module axil_ternary_mac (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite 슬레이브 포트
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
    input  wire [7:0]  s_araddr,
    input  wire        s_arvalid,
    output reg         s_arready,
    output reg  [31:0] s_rdata,
    output reg  [1:0]  s_rresp,
    output reg         s_rvalid,
    input  wire        s_rready
);

    // ── 애플리케이션 레지스터 ──────────────────────────────
    reg [31:0]  r_weights;      // W_DATA: 2비트×16
    reg [127:0] r_acts;         // 활성화 벡터 (8비트×16)
    reg [3:0]   r_v_addr;       // V_ADDR 래치
    reg [3:0]   r_veclen;       // CTRL bits[7:4]
    reg         r_done;         // STATUS bit[0]
    reg         r_start;        // MAC 트리거 (1클럭 펄스)

    // ternary_mac_core
    wire        core_busy;
    wire        core_done;
    wire [23:0] core_result;

    ternary_mac_core u_mac (
        .clk     (clk),
        .rst_n   (rst_n),
        .start   (r_start),
        .veclen  (r_veclen),
        .weights (r_weights),
        .acts    (r_acts),
        .result  (core_result),
        .busy    (core_busy),
        .done    (core_done)
    );

    // ── AXI4-Lite 쓰기 FSM ────────────────────────────────
    // 한 사이클에 AW와 W가 동시 혹은 AW 먼저 도착 가능
    // 간단화: awvalid와 wvalid가 동시에 주어질 때만 수용 (테스트벤치 호환)
    // → 아래 구현: AW 래치 후 W 대기

    localparam WR_IDLE  = 2'd0;
    localparam WR_WDATA = 2'd1;
    localparam WR_BRESP = 2'd2;

    reg [1:0]  wr_state;
    reg [7:0]  aw_addr;

    // V_DATA 쓰기를 위한 act 배열 갱신 (for-unroll)
    // Verilog-2001: 함수 내 for 가능, always 내 for도 OK (16-way mux 합성)
    integer j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_state  <= WR_IDLE;
            s_awready <= 1'b0;
            s_wready  <= 1'b0;
            s_bvalid  <= 1'b0;
            s_bresp   <= 2'b00;
            aw_addr   <= 8'd0;
            r_weights <= 32'd0;
            r_acts    <= 128'd0;
            r_v_addr  <= 4'd0;
            r_veclen  <= 4'd0;
            r_done    <= 1'b0;
            r_start   <= 1'b0;
        end else begin
            r_start <= 1'b0;  // 자동 클리어

            // done 래치
            if (core_done) r_done <= 1'b1;

            case (wr_state)
                WR_IDLE: begin
                    s_awready <= 1'b0;
                    s_wready  <= 1'b0;
                    if (s_awvalid) begin
                        // AW 수용
                        s_awready <= 1'b1;
                        aw_addr   <= s_awaddr;
                        wr_state  <= WR_WDATA;
                    end
                end

                WR_WDATA: begin
                    s_awready <= 1'b0;
                    if (s_wvalid) begin
                        s_wready <= 1'b1;
                        // 레지스터 쓰기 디코드
                        case (aw_addr[7:2])
                            6'h01: begin  // 0x04 CTRL
                                if (s_wdata[0]) r_start  <= 1'b1;
                                if (s_wdata[1]) r_done   <= 1'b0;  // CLR_DONE
                                r_veclen <= s_wdata[7:4];
                            end
                            6'h02: begin  // 0x08 W_DATA
                                if (s_wstrb[0]) r_weights[ 7: 0] <= s_wdata[ 7: 0];
                                if (s_wstrb[1]) r_weights[15: 8] <= s_wdata[15: 8];
                                if (s_wstrb[2]) r_weights[23:16] <= s_wdata[23:16];
                                if (s_wstrb[3]) r_weights[31:24] <= s_wdata[31:24];
                            end
                            // 6'h03: 0x0C W_ADDR — 무시
                            6'h04: begin  // 0x10 V_ADDR
                                r_v_addr <= s_wdata[3:0];
                            end
                            6'h05: begin  // 0x14 V_DATA
                                // 16-way mux: r_v_addr 로 인덱싱
                                for (j = 0; j < 16; j = j + 1) begin
                                    if (r_v_addr == j[3:0])
                                        r_acts[j*8 +: 8] <= s_wdata[7:0];
                                end
                            end
                            default: ; // OKAY, 무시
                        endcase
                        wr_state <= WR_BRESP;
                    end
                end

                WR_BRESP: begin
                    s_wready <= 1'b0;
                    if (!s_bvalid) begin
                        s_bvalid <= 1'b1;
                        s_bresp  <= 2'b00;  // OKAY
                    end else if (s_bready) begin
                        s_bvalid <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // ── AXI4-Lite 읽기 채널 ───────────────────────────────
    localparam RD_IDLE  = 2'd0;
    localparam RD_DATA  = 2'd1;

    reg [1:0] rd_state;
    reg [7:0] ar_addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_state  <= RD_IDLE;
            s_arready <= 1'b0;
            s_rvalid  <= 1'b0;
            s_rdata   <= 32'd0;
            s_rresp   <= 2'b00;
            ar_addr   <= 8'd0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_arready <= 1'b0;
                    if (s_arvalid) begin
                        s_arready <= 1'b1;
                        ar_addr   <= s_araddr;
                        rd_state  <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    s_arready <= 1'b0;
                    if (!s_rvalid) begin
                        s_rvalid <= 1'b1;
                        s_rresp  <= 2'b00;
                        case (ar_addr[7:2])
                            6'h00: s_rdata <= {30'd0, core_busy, r_done};  // STATUS
                            6'h06: s_rdata <= {{8{core_result[23]}}, core_result}; // RESULT
                            default: s_rdata <= 32'd0;
                        endcase
                    end else if (s_rready) begin
                        s_rvalid <= 1'b0;
                        rd_state <= RD_IDLE;
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

endmodule
