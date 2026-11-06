// multi_crc_axil.v — AXI4-Lite slave: CRC-8/16/32 선택 IP
// Board: Basys3 (XC7A35T), Address: 0x40270000, INTC: ch14 (미사용, ip2intc_irpt=0)
// Source: fpga-soc-harness, original work (HARNESS.md §13.3)
// Frozen map: mbv-frozen-v2, slot [27]
//
// Register map (word address, AXI awaddr[3:2]):
//   0x00  MODE    [1:0] 00=CRC-8, 01=CRC-16, 10=CRC-32  (R/W)
//   0x04  DATA_IN [7:0] 바이트 쓰기 → CRC 누산 트리거    (W, reads 0)
//   0x08  CRC_OUT [31:0] 현재 누산값 (CRC-8: [7:0], CRC-16: [15:0])  (R)
//   0x0C  CTRL    [0]=INIT 펄스 → 초기값으로 리셋        (W, reads 0)
//
// AXI write: AW+W 동시 핸드쉐이크만 허용 (MicroBlaze V 드라이버 패턴)
// CRC 업데이트: DATA_IN 쓰기 다음 사이클에 반영 (1사이클 레이턴시)
`default_nettype none

module multi_crc_axil #(
    parameter ADDR_WIDTH = 4
) (
    // AXI4-Lite slave
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write address
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // Write data
    input  wire [31:0] s_axi_wdata,
    input  wire  [3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // Write response
    output reg   [1:0] s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read address
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // Read data
    output reg  [31:0] s_axi_rdata,
    output reg   [1:0] s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // 인터럽트 (미사용: 0 고정)
    output wire        ip2intc_irpt
);

// 인터럽트 없음
assign ip2intc_irpt = 1'b0;

// -------------------------------------------------------------------------
// 레지스터
// -------------------------------------------------------------------------
reg [1:0]  mode_reg;      // 00=CRC-8, 01=CRC-16, 10=CRC-32
reg [7:0]  crc8_acc;
reg [15:0] crc16_acc;
reg [31:0] crc32_acc;

// CRC 초기값
localparam [7:0]  CRC8_INIT  = 8'hFF;
localparam [15:0] CRC16_INIT = 16'hFFFF;
localparam [31:0] CRC32_INIT = 32'hFFFFFFFF;

// -------------------------------------------------------------------------
// CRC 코어 배선
// -------------------------------------------------------------------------
wire [7:0]  crc8_out;
wire [15:0] crc16_out;
wire [31:0] crc32_out;

reg  [7:0]  data_latch;
reg         data_we;    // 1-cycle pulse: DATA_IN 쓰기 다음 사이클

crc8_core u_crc8 (
    .crc_in  (crc8_acc),
    .data    (data_latch),
    .crc_out (crc8_out)
);

crc16_core u_crc16 (
    .crc_in  (crc16_acc),
    .data    (data_latch),
    .crc_out (crc16_out)
);

crc32_core u_crc32 (
    .crc_in  (crc32_acc),
    .data    (data_latch),
    .crc_out (crc32_out)
);

// -------------------------------------------------------------------------
// CRC 누산기 업데이트
// -------------------------------------------------------------------------
always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        crc8_acc  <= CRC8_INIT;
        crc16_acc <= CRC16_INIT;
        crc32_acc <= CRC32_INIT;
    end else begin
        if (ctrl_init) begin
            crc8_acc  <= CRC8_INIT;
            crc16_acc <= CRC16_INIT;
            crc32_acc <= CRC32_INIT;
        end else if (data_we) begin
            crc8_acc  <= crc8_out;
            crc16_acc <= crc16_out;
            crc32_acc <= crc32_out;
        end
    end
end

// -------------------------------------------------------------------------
// AXI 쓰기 경로 (AW+W 동시 핸드쉐이크)
// -------------------------------------------------------------------------
reg ctrl_init;  // 1-cycle pulse

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        s_axi_awready <= 1'b0;
        s_axi_wready  <= 1'b0;
        s_axi_bvalid  <= 1'b0;
        s_axi_bresp   <= 2'b00;
        mode_reg      <= 2'b00;
        data_latch    <= 8'h00;
        data_we       <= 1'b0;
        ctrl_init     <= 1'b0;
    end else begin
        // 펄스 자동 해제
        data_we   <= 1'b0;
        ctrl_init <= 1'b0;

        // 쓰기 핸드쉐이크
        if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b1;

            case (s_axi_awaddr[3:2])
                2'b00: begin  // MODE
                    if (s_axi_wstrb[0]) mode_reg <= s_axi_wdata[1:0];
                end
                2'b01: begin  // DATA_IN
                    if (s_axi_wstrb[0]) begin
                        data_latch <= s_axi_wdata[7:0];
                        data_we    <= 1'b1;
                    end
                end
                2'b10: ;      // CRC_OUT: 쓰기 무시
                2'b11: begin  // CTRL
                    if (s_axi_wstrb[0] && s_axi_wdata[0])
                        ctrl_init <= 1'b1;
                end
                default: ;
            endcase

            s_axi_bvalid <= 1'b1;
            s_axi_bresp  <= 2'b00;  // OKAY
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
        end

        // B 채널 핸드쉐이크
        if (s_axi_bvalid && s_axi_bready)
            s_axi_bvalid <= 1'b0;
    end
end

// -------------------------------------------------------------------------
// 읽기 경로
// -------------------------------------------------------------------------
wire [31:0] crc_out_val =
    (mode_reg == 2'b00) ? {24'h000000, crc8_acc}  :
    (mode_reg == 2'b01) ? {16'h0000, crc16_acc}   :
                          crc32_acc;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        s_axi_arready <= 1'b0;
        s_axi_rvalid  <= 1'b0;
        s_axi_rdata   <= 32'h0;
        s_axi_rresp   <= 2'b00;
    end else begin
        if (s_axi_arvalid && !s_axi_rvalid) begin
            s_axi_arready <= 1'b1;
            s_axi_rvalid  <= 1'b1;
            s_axi_rresp   <= 2'b00;
            case (s_axi_araddr[3:2])
                2'b00:  s_axi_rdata <= {30'h0, mode_reg};
                2'b01:  s_axi_rdata <= 32'h0;
                2'b10:  s_axi_rdata <= crc_out_val;
                2'b11:  s_axi_rdata <= 32'h0;
                default: s_axi_rdata <= 32'h0;
            endcase
        end else begin
            s_axi_arready <= 1'b0;
        end

        if (s_axi_rvalid && s_axi_rready)
            s_axi_rvalid <= 1'b0;
    end
end

endmodule
`default_nettype wire
