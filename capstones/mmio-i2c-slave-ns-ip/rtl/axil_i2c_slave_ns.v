// axil_i2c_slave_ns.v — AXI4-Lite 슬레이브 래퍼 (I2C 슬레이브 무클럭스트레칭 IP)
// 8×32비트 범용 레지스터 + STATUS/I2C_ADDR/CTRL 레지스터 파일.
// i2c_slave_ns 코어를 인스턴스화해 MicroBlaze V AXI 버스에 연결한다.
// Verilog-2001 / iverilog / verilator / yosys 호환.
// SPDX-License-Identifier: MIT
// 하네스 원본 (capstones/mmio-i2c-slave-ns-ip)

`timescale 1ns/1ps

module axil_i2c_slave_ns #(
    parameter DEFAULT_ADDR = 7'h20
) (
    // AXI4-Lite 슬레이브 포트
    input  wire        S_AXI_ACLK,
    input  wire        S_AXI_ARESETN,

    // Write Address
    input  wire [7:0]  S_AXI_AWADDR,
    input  wire        S_AXI_AWVALID,
    output reg         S_AXI_AWREADY,

    // Write Data
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output reg         S_AXI_WREADY,

    // Write Response
    output reg  [1:0]  S_AXI_BRESP,
    output reg         S_AXI_BVALID,
    input  wire        S_AXI_BREADY,

    // Read Address
    input  wire [7:0]  S_AXI_ARADDR,
    input  wire        S_AXI_ARVALID,
    output reg         S_AXI_ARREADY,

    // Read Data
    output reg  [31:0] S_AXI_RDATA,
    output reg  [1:0]  S_AXI_RRESP,
    output reg         S_AXI_RVALID,
    input  wire        S_AXI_RREADY,

    // I2C 핀 (동기화 전 — 이 모듈 내에서 동기화)
    input  wire        SCL,
    inout  wire        SDA
);

wire clk   = S_AXI_ACLK;
wire rst   = ~S_AXI_ARESETN;

// ─── SCL/SDA 3단 동기화 ───
reg scl_s0, scl_s1, scl_s2;
reg sda_s0, sda_s1, sda_s2;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        scl_s0 <= 1'b1; scl_s1 <= 1'b1; scl_s2 <= 1'b1;
        sda_s0 <= 1'b1; sda_s1 <= 1'b1; sda_s2 <= 1'b1;
    end else begin
        scl_s0 <= SCL;    scl_s1 <= scl_s0; scl_s2 <= scl_s1;
        sda_s0 <= SDA;    sda_s1 <= sda_s0; sda_s2 <= sda_s1;
    end
end

// ─── I2C 코어 ───
reg  [7:0] core_reg_wdata;
reg  [2:0] core_reg_waddr;
reg        core_reg_we;
wire [2:0] core_reg_raddr;
wire [7:0] core_reg_proxy;
wire       core_busy, core_start_det, core_stop_det;
wire       sda_oe;

// I2C_ADDR 레지스터 (AXI에서 프로그래밍 가능)
reg [6:0]  i2c_addr_reg;
reg        clr_status_pulse;

i2c_slave_ns #(.SLAVE_ADDR(DEFAULT_ADDR)) u_i2c_core (
    .clk       (clk),
    .rst       (rst),
    .scl_in    (scl_s2),
    .sda_in    (sda_s2),
    .sda_oe    (sda_oe),
    .reg_wdata (core_reg_wdata),
    .reg_waddr (core_reg_waddr),
    .reg_we    (core_reg_we),
    .reg_rdata (),              // I2C 읽기 경로는 내부 처리
    .reg_raddr (core_reg_raddr),
    .reg_proxy (core_reg_proxy),
    .busy      (core_busy),
    .start_det (core_start_det),
    .stop_det  (core_stop_det),
    .clr_status(clr_status_pulse)
);

// SDA 오픈 드레인: sda_oe=1이면 풀다운, 0이면 Hi-Z
assign SDA = sda_oe ? 1'b0 : 1'bz;

// core_reg_raddr는 AXI 읽기 주소에서 결정 (레지스터 주소[4:2] → [2:0])
// AXI 주소 오프셋 0x00~0x1C → 레지스터 인덱스 0~7
reg [7:0] axi_araddr_lat;
assign core_reg_raddr = axi_araddr_lat[4:2];

// ─── AXI4-Lite 쓰기 채널 ───
reg [7:0] axi_awaddr_lat;
reg       aw_done, w_done;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        S_AXI_AWREADY  <= 1'b0;
        S_AXI_WREADY   <= 1'b0;
        S_AXI_BVALID   <= 1'b0;
        S_AXI_BRESP    <= 2'b00;
        axi_awaddr_lat <= 8'h00;
        aw_done        <= 1'b0;
        w_done         <= 1'b0;
        core_reg_we    <= 1'b0;
        core_reg_wdata <= 8'h00;
        core_reg_waddr <= 3'h0;
        clr_status_pulse <= 1'b0;
        i2c_addr_reg   <= DEFAULT_ADDR;
    end else begin
        clr_status_pulse <= 1'b0;
        core_reg_we      <= 1'b0;

        // AW 채널
        if (S_AXI_AWVALID && !aw_done) begin
            S_AXI_AWREADY  <= 1'b1;
            axi_awaddr_lat <= S_AXI_AWADDR;
            aw_done        <= 1'b1;
        end else begin
            S_AXI_AWREADY <= 1'b0;
        end

        // W 채널
        if (S_AXI_WVALID && !w_done) begin
            S_AXI_WREADY <= 1'b1;
            w_done       <= 1'b1;
        end else begin
            S_AXI_WREADY <= 1'b0;
        end

        // 쓰기 완료 처리
        if (aw_done && w_done && !S_AXI_BVALID) begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
            S_AXI_BVALID <= 1'b1;
            S_AXI_BRESP  <= 2'b00;

            // 레지스터 디코드
            case (axi_awaddr_lat[7:0])
                8'h00, 8'h04, 8'h08, 8'h0C,
                8'h10, 8'h14, 8'h18, 8'h1C: begin
                    // REG0~REG7: I2C 레지스터 파일에 쓰기
                    core_reg_we    <= 1'b1;
                    core_reg_waddr <= axi_awaddr_lat[4:2];
                    core_reg_wdata <= S_AXI_WDATA[7:0];
                end
                8'h24: begin
                    // I2C_ADDR
                    i2c_addr_reg <= S_AXI_WDATA[6:0];
                end
                8'h28: begin
                    // CTRL: [0]=clr_status
                    if (S_AXI_WDATA[0]) clr_status_pulse <= 1'b1;
                end
                default: ; // STATUS(0x20)는 읽기 전용
            endcase
        end

        if (S_AXI_BVALID && S_AXI_BREADY) begin
            S_AXI_BVALID <= 1'b0;
        end
    end
end

// ─── AXI4-Lite 읽기 채널 ───
always @(posedge clk or posedge rst) begin
    if (rst) begin
        S_AXI_ARREADY  <= 1'b0;
        S_AXI_RVALID   <= 1'b0;
        S_AXI_RDATA    <= 32'h0;
        S_AXI_RRESP    <= 2'b00;
        axi_araddr_lat <= 8'h00;
    end else begin
        if (S_AXI_ARVALID && !S_AXI_RVALID) begin
            S_AXI_ARREADY  <= 1'b1;
            axi_araddr_lat <= S_AXI_ARADDR;

            // 읽기 데이터 디코드
            S_AXI_RVALID <= 1'b1;
            S_AXI_RRESP  <= 2'b00;
            case (S_AXI_ARADDR[7:0])
                8'h00, 8'h04, 8'h08, 8'h0C,
                8'h10, 8'h14, 8'h18, 8'h1C: begin
                    // REG0~REG7: 레지스터 파일 프록시 읽기
                    // core_reg_raddr가 S_AXI_ARADDR[4:2]로 설정됨
                    S_AXI_RDATA <= {24'h0, core_reg_proxy};
                end
                8'h20: begin
                    // STATUS: [2]=start_det [1]=stop_det [0]=busy
                    S_AXI_RDATA <= {29'h0, core_start_det, core_stop_det, core_busy};
                end
                8'h24: begin
                    // I2C_ADDR
                    S_AXI_RDATA <= {25'h0, i2c_addr_reg};
                end
                default: S_AXI_RDATA <= 32'h0;
            endcase
        end else begin
            S_AXI_ARREADY <= 1'b0;
        end

        if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID <= 1'b0;
        end
    end
end

endmodule
