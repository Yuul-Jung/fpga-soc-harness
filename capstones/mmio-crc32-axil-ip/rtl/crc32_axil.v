// crc32_axil.v — CRC-32 AXI4-Lite 슬레이브 IP
// slug: mmio-crc32-axil-ip
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
//
// 레지스터 (베이스 상대 오프셋):
//   0x00  DATA_IN  W   bit[7:0] 쓰기 → 1사이클 후 CRC-32 누산기 갱신. 읽기값 0.
//   0x04  CRC_OUT  R   현재 CRC-32 누산값 [31:0]. XorOut(0xFFFFFFFF)은 SW 담당.
//   0x08  CTRL     W   bit[0]=INIT 펄스: 1을 쓰면 crc_reg = 0xFFFFFFFF. 읽기값 0.
//
// 동결 맵 슬롯 [17] = 0x4017_0000 (64KB). 인터럽트 없음(ip2intc_irpt=0).
//
// AXI4-Lite 프로토콜:
//   - AW 채널과 W 채널을 독립 래치(aw_lat, w_lat)로 받아 do_commit에서 처리.
//   - MicroBlaze V의 AW+W 동시 핸드쉐이크도 지원하고, 순차 발행도 지원.
//   - BRESP/RRESP 항상 2'b00 (OKAY).
//   - ip2intc_irpt 상수 1'b0.
//
// Verilog-2001. iverilog/verilator/yosys 호환.

`default_nettype none
`timescale 1ns/1ps

module crc32_axil #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // 시스템
    input  wire                                s_axi_aclk,
    input  wire                                s_axi_aresetn,
    // 쓰기 주소 채널
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
    input  wire [2:0]                          s_axi_awprot,   // 미사용, AXI 필수
    input  wire                                s_axi_awvalid,
    output wire                                s_axi_awready,
    // 쓰기 데이터 채널
    input  wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  s_axi_wstrb,
    input  wire                                s_axi_wvalid,
    output wire                                s_axi_wready,
    // 쓰기 응답 채널
    output wire [1:0]                          s_axi_bresp,
    output wire                                s_axi_bvalid,
    input  wire                                s_axi_bready,
    // 읽기 주소 채널
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
    input  wire [2:0]                          s_axi_arprot,   // 미사용, AXI 필수
    input  wire                                s_axi_arvalid,
    output wire                                s_axi_arready,
    // 읽기 데이터 채널
    output wire [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output wire [1:0]                          s_axi_rresp,
    output wire                                s_axi_rvalid,
    input  wire                                s_axi_rready,
    // 인터럽트 출력 (이 IP는 인터럽트 없음)
    output wire                                ip2intc_irpt
);

    // ----------------------------------------------------------------
    // 레지스터 주소 디코더 (addr[3:2])
    // ----------------------------------------------------------------
    localparam [1:0] REG_DATA_IN = 2'd0;  // 0x00
    localparam [1:0] REG_CRC_OUT = 2'd1;  // 0x04
    localparam [1:0] REG_CTRL    = 2'd2;  // 0x08

    // ----------------------------------------------------------------
    // CRC-32 누산기
    // ----------------------------------------------------------------
    reg [31:0] crc_reg;

    // 조합 CRC-32 코어 연결 (w_lat에서 래치된 데이터 사용)
    wire [31:0] crc_next;
    reg  [C_S_AXI_DATA_WIDTH-1:0] w_data_lat; // w_lat 래치값 (쓰기 처리용)

    crc32_core u_crc32 (
        .crc_in  (crc_reg),
        .data_in (w_data_lat[7:0]),
        .crc_out (crc_next)
    );

    // ================================================================
    // 쓰기 경로 (AW 래치 + W 래치 → do_commit)
    // ================================================================

    reg                            aw_lat;
    reg [C_S_AXI_ADDR_WIDTH-1:0]  aw_addr;

    reg                                       w_lat;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0]         w_strb;

    reg b_act;

    // awready/wready: 각 채널이 아직 래치를 비어있을 때 수락
    assign s_axi_awready = !aw_lat;
    assign s_axi_wready  = !w_lat;

    // 커밋: AW와 W 모두 래치됐고, 응답 대기 없을 때
    wire do_commit = aw_lat && w_lat && !b_act;

    wire [1:0] wr_sel = aw_addr[3:2];

    // AW 래치
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            aw_lat  <= 1'b0;
            aw_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_lat  <= 1'b1;
                aw_addr <= s_axi_awaddr;
            end else if (do_commit) begin
                aw_lat  <= 1'b0;
            end
        end
    end

    // W 래치
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            w_lat      <= 1'b0;
            w_data_lat <= {C_S_AXI_DATA_WIDTH{1'b0}};
            w_strb     <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
        end else begin
            if (s_axi_wvalid && s_axi_wready) begin
                w_lat      <= 1'b1;
                w_data_lat <= s_axi_wdata;
                w_strb     <= s_axi_wstrb;
            end else if (do_commit) begin
                w_lat  <= 1'b0;
            end
        end
    end

    // 쓰기 응답
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn)
            b_act <= 1'b0;
        else if (do_commit)
            b_act <= 1'b1;
        else if (s_axi_bvalid && s_axi_bready)
            b_act <= 1'b0;
    end

    assign s_axi_bvalid = b_act;
    assign s_axi_bresp  = 2'b00;  // OKAY

    // CRC 누산기 갱신
    // do_commit 시점에 crc_next(= crc32_core(crc_reg, w_data_lat[7:0]))는 이미 조합 출력으로 확정.
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            crc_reg <= 32'hFFFF_FFFF;
        end else if (do_commit) begin
            if (wr_sel == REG_DATA_IN) begin
                // DATA_IN 쓰기: CRC 누산
                crc_reg <= crc_next;
            end else if (wr_sel == REG_CTRL && w_data_lat[0]) begin
                // CTRL INIT 펄스: CRC 리셋
                crc_reg <= 32'hFFFF_FFFF;
            end
            // REG_CRC_OUT 쓰기: 무시 (읽기 전용)
        end
    end

    // ================================================================
    // 읽기 경로 (AR 래치 → R 응답)
    // ================================================================

    reg                           ar_lat;
    reg [C_S_AXI_ADDR_WIDTH-1:0] ar_addr;
    reg                           r_act;
    reg [C_S_AXI_DATA_WIDTH-1:0] r_data;

    wire [1:0] rd_sel = ar_addr[3:2];

    assign s_axi_arready = !ar_lat;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            ar_lat  <= 1'b0;
            ar_addr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            r_act   <= 1'b0;
            r_data  <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                ar_lat  <= 1'b1;
                ar_addr <= s_axi_araddr;
                r_act   <= 1'b1;
                // 읽기 데이터 캡처 (arvalid 수락 시점)
                if (s_axi_araddr[3:2] == REG_CRC_OUT)
                    r_data <= crc_reg;
                else
                    r_data <= {C_S_AXI_DATA_WIDTH{1'b0}};
            end else if (s_axi_rvalid && s_axi_rready) begin
                ar_lat  <= 1'b0;
                r_act   <= 1'b0;
            end
        end
    end

    assign s_axi_rvalid = r_act;
    assign s_axi_rresp  = 2'b00;  // OKAY
    assign s_axi_rdata  = r_data;

    // ================================================================
    // 인터럽트 — 이 IP는 인터럽트 없음
    // ================================================================
    assign ip2intc_irpt = 1'b0;

    // 미사용 입력 경고 억제 (prot 비트는 AXI 필수이나 이 IP에서 미사용)
    // verilator lint_off UNUSED
    wire _unused = &{s_axi_awprot, s_axi_arprot, s_axi_wstrb, rd_sel, w_strb};
    // verilator lint_on UNUSED

endmodule
`default_nettype wire
