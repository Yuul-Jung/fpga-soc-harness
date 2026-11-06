// basys3_top_xbar.v — Basys3 최상위 래퍼 (axil_xbar_2m4s 데모)
// M0 = AXI4-Lite 루프백 BFM (내부), M1 = 고정 주소 드라이버
// S0~S3 = 내부 더미 레지스터 슬레이브 (어서션·LED 출력용)
// LED[3:0] = {s3_awvalid, s2_arvalid, s1_awvalid, s0_arvalid}
// Verilog-2001. iverilog/verilator/yosys 호환.

`timescale 1ns/1ps
module basys3_top_xbar (
  input  wire       clk100mhz, // W5
  input  wire       btnC,      // T17 — active-high 리셋
  output wire [3:0] led        // U16/E19/U19/V19
);

  wire clk   = clk100mhz;
  wire rst_n = ~btnC;

  // ─── 내부 AXI4-Lite 버스 (M0, M1) ───────────────────────────────────────
  localparam DW = 32, AW = 32;

  // M0 — 고정 단일 쓰기/읽기 BFM (루프백 테스트)
  reg [AW-1:0] m0_awaddr;  reg [2:0] m0_awprot;  reg m0_awvalid;
  reg [DW-1:0] m0_wdata;   reg [3:0] m0_wstrb;   reg m0_wvalid;
  reg m0_bready;
  reg [AW-1:0] m0_araddr;  reg [2:0] m0_arprot;  reg m0_arvalid;
  reg m0_rready;

  wire m0_awready, m0_wready, m0_bvalid; wire [1:0] m0_bresp;
  wire m0_arready, m0_rvalid; wire [DW-1:0] m0_rdata; wire [1:0] m0_rresp;

  // M1 — 항상 S2로 읽기 시도 (우선순위 테스트)
  reg [AW-1:0] m1_awaddr;  reg [2:0] m1_awprot;  reg m1_awvalid;
  reg [DW-1:0] m1_wdata;   reg [3:0] m1_wstrb;   reg m1_wvalid;
  reg m1_bready;
  reg [AW-1:0] m1_araddr;  reg [2:0] m1_arprot;  reg m1_arvalid;
  reg m1_rready;

  wire m1_awready, m1_wready, m1_bvalid; wire [1:0] m1_bresp;
  wire m1_arready, m1_rvalid; wire [DW-1:0] m1_rdata; wire [1:0] m1_rresp;

  // ─── 슬레이브 더미 레지스터 버스 ─────────────────────────────────────────
  // S0~S3: 단일 레지스터 슬레이브 (awready=1,wready=1,arready=1 항상 준비)
  wire [AW-1:0] s0_awaddr, s1_awaddr, s2_awaddr, s3_awaddr;
  wire [2:0] s0_awprot, s1_awprot, s2_awprot, s3_awprot;
  wire s0_awvalid, s1_awvalid, s2_awvalid, s3_awvalid;
  wire [DW-1:0] s0_wdata, s1_wdata, s2_wdata, s3_wdata;
  wire [3:0] s0_wstrb, s1_wstrb, s2_wstrb, s3_wstrb;
  wire s0_wvalid, s1_wvalid, s2_wvalid, s3_wvalid;
  wire s0_bready, s1_bready, s2_bready, s3_bready;
  wire [AW-1:0] s0_araddr, s1_araddr, s2_araddr, s3_araddr;
  wire [2:0] s0_arprot, s1_arprot, s2_arprot, s3_arprot;
  wire s0_arvalid, s1_arvalid, s2_arvalid, s3_arvalid;
  wire s0_rready, s1_rready, s2_rready, s3_rready;

  // 더미 슬레이브 응답: 항상 OKAY, 데이터는 어드레스 에코
  assign s0_awready = 1'b1; assign s0_wready  = 1'b1;
  assign s1_awready = 1'b1; assign s1_wready  = 1'b1;
  assign s2_awready = 1'b1; assign s2_wready  = 1'b1;
  assign s3_awready = 1'b1; assign s3_wready  = 1'b1;

  // Write response (B channel) — single cycle after W accepted
  reg s0_bvalid_r, s1_bvalid_r, s2_bvalid_r, s3_bvalid_r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0_bvalid_r<=0; s1_bvalid_r<=0; s2_bvalid_r<=0; s3_bvalid_r<=0; end
    else begin
      s0_bvalid_r <= s0_awvalid && s0_awready;
      s1_bvalid_r <= s1_awvalid && s1_awready;
      s2_bvalid_r <= s2_awvalid && s2_awready;
      s3_bvalid_r <= s3_awvalid && s3_awready;
    end
  end
  wire [1:0] s0_bresp=2'b00, s1_bresp=2'b00, s2_bresp=2'b00, s3_bresp=2'b00;
  wire s0_bvalid=s0_bvalid_r, s1_bvalid=s1_bvalid_r;
  wire s2_bvalid=s2_bvalid_r, s3_bvalid=s3_bvalid_r;

  // Read response (AR→R)
  assign s0_arready = 1'b1; assign s1_arready = 1'b1;
  assign s2_arready = 1'b1; assign s3_arready = 1'b1;
  reg s0_rvalid_r, s1_rvalid_r, s2_rvalid_r, s3_rvalid_r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0_rvalid_r<=0; s1_rvalid_r<=0; s2_rvalid_r<=0; s3_rvalid_r<=0; end
    else begin
      s0_rvalid_r <= s0_arvalid && s0_arready;
      s1_rvalid_r <= s1_arvalid && s1_arready;
      s2_rvalid_r <= s2_arvalid && s2_arready;
      s3_rvalid_r <= s3_arvalid && s3_arready;
    end
  end
  wire [DW-1:0] s0_rdata=32'hDEAD_0000, s1_rdata=32'hDEAD_0001;
  wire [DW-1:0] s2_rdata=32'hDEAD_0002, s3_rdata=32'hDEAD_0003;
  wire [1:0]    s0_rresp=2'b00, s1_rresp=2'b00, s2_rresp=2'b00, s3_rresp=2'b00;
  wire s0_rvalid=s0_rvalid_r, s1_rvalid=s1_rvalid_r;
  wire s2_rvalid=s2_rvalid_r, s3_rvalid=s3_rvalid_r;

  // ─── Crossbar instance ────────────────────────────────────────────────────
  axil_xbar_2m4s u_xbar (
    .clk(clk), .rst_n(rst_n),
    .m0_awaddr(m0_awaddr), .m0_awprot(m0_awprot), .m0_awvalid(m0_awvalid), .m0_awready(m0_awready),
    .m0_wdata(m0_wdata),   .m0_wstrb(m0_wstrb),   .m0_wvalid(m0_wvalid),   .m0_wready(m0_wready),
    .m0_bresp(m0_bresp),   .m0_bvalid(m0_bvalid), .m0_bready(m0_bready),
    .m0_araddr(m0_araddr), .m0_arprot(m0_arprot), .m0_arvalid(m0_arvalid), .m0_arready(m0_arready),
    .m0_rdata(m0_rdata),   .m0_rresp(m0_rresp),   .m0_rvalid(m0_rvalid),   .m0_rready(m0_rready),
    .m1_awaddr(m1_awaddr), .m1_awprot(m1_awprot), .m1_awvalid(m1_awvalid), .m1_awready(m1_awready),
    .m1_wdata(m1_wdata),   .m1_wstrb(m1_wstrb),   .m1_wvalid(m1_wvalid),   .m1_wready(m1_wready),
    .m1_bresp(m1_bresp),   .m1_bvalid(m1_bvalid), .m1_bready(m1_bready),
    .m1_araddr(m1_araddr), .m1_arprot(m1_arprot), .m1_arvalid(m1_arvalid), .m1_arready(m1_arready),
    .m1_rdata(m1_rdata),   .m1_rresp(m1_rresp),   .m1_rvalid(m1_rvalid),   .m1_rready(m1_rready),
    .s0_awaddr(s0_awaddr), .s0_awprot(s0_awprot), .s0_awvalid(s0_awvalid), .s0_awready(s0_awready),
    .s0_wdata(s0_wdata),   .s0_wstrb(s0_wstrb),   .s0_wvalid(s0_wvalid),   .s0_wready(s0_wready),
    .s0_bresp(s0_bresp),   .s0_bvalid(s0_bvalid), .s0_bready(s0_bready),
    .s0_araddr(s0_araddr), .s0_arprot(s0_arprot), .s0_arvalid(s0_arvalid), .s0_arready(s0_arready),
    .s0_rdata(s0_rdata),   .s0_rresp(s0_rresp),   .s0_rvalid(s0_rvalid),   .s0_rready(s0_rready),
    .s1_awaddr(s1_awaddr), .s1_awprot(s1_awprot), .s1_awvalid(s1_awvalid), .s1_awready(s1_awready),
    .s1_wdata(s1_wdata),   .s1_wstrb(s1_wstrb),   .s1_wvalid(s1_wvalid),   .s1_wready(s1_wready),
    .s1_bresp(s1_bresp),   .s1_bvalid(s1_bvalid), .s1_bready(s1_bready),
    .s1_araddr(s1_araddr), .s1_arprot(s1_arprot), .s1_arvalid(s1_arvalid), .s1_arready(s1_arready),
    .s1_rdata(s1_rdata),   .s1_rresp(s1_rresp),   .s1_rvalid(s1_rvalid),   .s1_rready(s1_rready),
    .s2_awaddr(s2_awaddr), .s2_awprot(s2_awprot), .s2_awvalid(s2_awvalid), .s2_awready(s2_awready),
    .s2_wdata(s2_wdata),   .s2_wstrb(s2_wstrb),   .s2_wvalid(s2_wvalid),   .s2_wready(s2_wready),
    .s2_bresp(s2_bresp),   .s2_bvalid(s2_bvalid), .s2_bready(s2_bready),
    .s2_araddr(s2_araddr), .s2_arprot(s2_arprot), .s2_arvalid(s2_arvalid), .s2_arready(s2_arready),
    .s2_rdata(s2_rdata),   .s2_rresp(s2_rresp),   .s2_rvalid(s2_rvalid),   .s2_rready(s2_rready),
    .s3_awaddr(s3_awaddr), .s3_awprot(s3_awprot), .s3_awvalid(s3_awvalid), .s3_awready(s3_awready),
    .s3_wdata(s3_wdata),   .s3_wstrb(s3_wstrb),   .s3_wvalid(s3_wvalid),   .s3_wready(s3_wready),
    .s3_bresp(s3_bresp),   .s3_bvalid(s3_bvalid), .s3_bready(s3_bready),
    .s3_araddr(s3_araddr), .s3_arprot(s3_arprot), .s3_arvalid(s3_arvalid), .s3_arready(s3_arready),
    .s3_rdata(s3_rdata),   .s3_rresp(s3_rresp),   .s3_rvalid(s3_rvalid),   .s3_rready(s3_rready)
  );

  // ─── LED 출력 ─────────────────────────────────────────────────────────────
  assign led = {s3_awvalid, s2_arvalid, s1_awvalid, s0_arvalid};

  // ─── M0/M1 초기화 ─────────────────────────────────────────────────────────
  initial begin
    m0_awaddr=0; m0_awprot=0; m0_awvalid=0;
    m0_wdata=0;  m0_wstrb=0;  m0_wvalid=0;  m0_bready=0;
    m0_araddr=0; m0_arprot=0; m0_arvalid=0; m0_rready=0;
    m1_awaddr=0; m1_awprot=0; m1_awvalid=0;
    m1_wdata=0;  m1_wstrb=0;  m1_wvalid=0;  m1_bready=0;
    m1_araddr=0; m1_arprot=0; m1_arvalid=0; m1_rready=0;
  end

endmodule
