// tb_axil_xbar_2m4s.v — 자체 점검 테스트벤치
// 테스트 항목:
//   T1: M0 → S0 쓰기 (OKAY 확인)
//   T2: M0 → S1 읽기 (OKAY, 데이터 확인)
//   T3: M1 → S2 쓰기 (OKAY 확인)
//   T4: M1 → S3 읽기 (OKAY, 데이터 확인)
//   T5: M0+M1 동시 → S0 쓰기 (M0 우선, M1 대기 후 성공)
//   T6: M0 → 미매핑 주소 쓰기 (DECERR 확인)
//   T7: M1 → 미매핑 주소 읽기 (DECERR 확인)
// 통과 시 "PASS", 실패 시 "FAIL" 출력.

`timescale 1ns/1ps
module tb_axil_xbar_2m4s;

  localparam CLK_HALF = 5; // 100 MHz
  localparam DW = 32, AW = 32;

  reg clk, rst_n;
  integer fail_cnt;

  // ─── Master 0 BFM regs ────────────────────────────────────────────────────
  reg [AW-1:0] m0_awaddr; reg [2:0] m0_awprot; reg m0_awvalid;
  reg [DW-1:0] m0_wdata;  reg [3:0] m0_wstrb;  reg m0_wvalid;
  reg m0_bready;
  reg [AW-1:0] m0_araddr; reg [2:0] m0_arprot; reg m0_arvalid;
  reg m0_rready;
  wire m0_awready, m0_wready, m0_bvalid; wire [1:0] m0_bresp;
  wire m0_arready, m0_rvalid; wire [DW-1:0] m0_rdata; wire [1:0] m0_rresp;

  // ─── Master 1 BFM regs ────────────────────────────────────────────────────
  reg [AW-1:0] m1_awaddr; reg [2:0] m1_awprot; reg m1_awvalid;
  reg [DW-1:0] m1_wdata;  reg [3:0] m1_wstrb;  reg m1_wvalid;
  reg m1_bready;
  reg [AW-1:0] m1_araddr; reg [2:0] m1_arprot; reg m1_arvalid;
  reg m1_rready;
  wire m1_awready, m1_wready, m1_bvalid; wire [1:0] m1_bresp;
  wire m1_arready, m1_rvalid; wire [DW-1:0] m1_rdata; wire [1:0] m1_rresp;

  // ─── Slave dummy registers ────────────────────────────────────────────────
  wire [AW-1:0] s0_awaddr,s1_awaddr,s2_awaddr,s3_awaddr;
  wire [2:0]    s0_awprot,s1_awprot,s2_awprot,s3_awprot;
  wire s0_awvalid,s1_awvalid,s2_awvalid,s3_awvalid;
  wire [DW-1:0] s0_wdata,s1_wdata,s2_wdata,s3_wdata;
  wire [3:0]    s0_wstrb,s1_wstrb,s2_wstrb,s3_wstrb;
  wire s0_wvalid,s1_wvalid,s2_wvalid,s3_wvalid;
  wire s0_bready,s1_bready,s2_bready,s3_bready;
  wire [AW-1:0] s0_araddr,s1_araddr,s2_araddr,s3_araddr;
  wire [2:0]    s0_arprot,s1_arprot,s2_arprot,s3_arprot;
  wire s0_arvalid,s1_arvalid,s2_arvalid,s3_arvalid;
  wire s0_rready,s1_rready,s2_rready,s3_rready;

  // Slave always-ready responses
  assign s0_awready=1'b1; assign s0_wready=1'b1;
  assign s1_awready=1'b1; assign s1_wready=1'b1;
  assign s2_awready=1'b1; assign s2_wready=1'b1;
  assign s3_awready=1'b1; assign s3_wready=1'b1;
  assign s0_arready=1'b1; assign s1_arready=1'b1;
  assign s2_arready=1'b1; assign s3_arready=1'b1;

  // Write B response (1 cycle later)
  reg s0_bvalid_r,s1_bvalid_r,s2_bvalid_r,s3_bvalid_r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0_bvalid_r<=0;s1_bvalid_r<=0;s2_bvalid_r<=0;s3_bvalid_r<=0; end
    else begin
      s0_bvalid_r <= s0_awvalid & s0_awready;
      s1_bvalid_r <= s1_awvalid & s1_awready;
      s2_bvalid_r <= s2_awvalid & s2_awready;
      s3_bvalid_r <= s3_awvalid & s3_awready;
    end
  end
  wire [1:0] s0_bresp=2'b00,s1_bresp=2'b00,s2_bresp=2'b00,s3_bresp=2'b00;
  wire s0_bvalid=s0_bvalid_r,s1_bvalid=s1_bvalid_r;
  wire s2_bvalid=s2_bvalid_r,s3_bvalid=s3_bvalid_r;

  // Read R response (1 cycle later)
  reg s0_rv_r,s1_rv_r,s2_rv_r,s3_rv_r;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0_rv_r<=0;s1_rv_r<=0;s2_rv_r<=0;s3_rv_r<=0; end
    else begin
      s0_rv_r <= s0_arvalid & s0_arready;
      s1_rv_r <= s1_arvalid & s1_arready;
      s2_rv_r <= s2_arvalid & s2_arready;
      s3_rv_r <= s3_arvalid & s3_arready;
    end
  end
  wire [DW-1:0] s0_rdata=32'hCAFE_0000,s1_rdata=32'hCAFE_0001;
  wire [DW-1:0] s2_rdata=32'hCAFE_0002,s3_rdata=32'hCAFE_0003;
  wire [1:0]    s0_rresp=2'b00,s1_rresp=2'b00,s2_rresp=2'b00,s3_rresp=2'b00;
  wire s0_rvalid=s0_rv_r,s1_rvalid=s1_rv_r,s2_rvalid=s2_rv_r,s3_rvalid=s3_rv_r;

  // ─── DUT ─────────────────────────────────────────────────────────────────
  `define CONNECT_SLAVE(N) \
    .s``N``_awaddr(s``N``_awaddr), .s``N``_awprot(s``N``_awprot), \
    .s``N``_awvalid(s``N``_awvalid), .s``N``_awready(s``N``_awready), \
    .s``N``_wdata(s``N``_wdata),   .s``N``_wstrb(s``N``_wstrb), \
    .s``N``_wvalid(s``N``_wvalid),  .s``N``_wready(s``N``_wready), \
    .s``N``_bresp(s``N``_bresp),   .s``N``_bvalid(s``N``_bvalid), \
    .s``N``_bready(s``N``_bready), \
    .s``N``_araddr(s``N``_araddr), .s``N``_arprot(s``N``_arprot), \
    .s``N``_arvalid(s``N``_arvalid),.s``N``_arready(s``N``_arready), \
    .s``N``_rdata(s``N``_rdata),   .s``N``_rresp(s``N``_rresp), \
    .s``N``_rvalid(s``N``_rvalid), .s``N``_rready(s``N``_rready)

  axil_xbar_2m4s dut (
    .clk(clk), .rst_n(rst_n),
    .m0_awaddr(m0_awaddr),.m0_awprot(m0_awprot),.m0_awvalid(m0_awvalid),.m0_awready(m0_awready),
    .m0_wdata(m0_wdata),  .m0_wstrb(m0_wstrb),  .m0_wvalid(m0_wvalid),  .m0_wready(m0_wready),
    .m0_bresp(m0_bresp),  .m0_bvalid(m0_bvalid),.m0_bready(m0_bready),
    .m0_araddr(m0_araddr),.m0_arprot(m0_arprot),.m0_arvalid(m0_arvalid),.m0_arready(m0_arready),
    .m0_rdata(m0_rdata),  .m0_rresp(m0_rresp),  .m0_rvalid(m0_rvalid),  .m0_rready(m0_rready),
    .m1_awaddr(m1_awaddr),.m1_awprot(m1_awprot),.m1_awvalid(m1_awvalid),.m1_awready(m1_awready),
    .m1_wdata(m1_wdata),  .m1_wstrb(m1_wstrb),  .m1_wvalid(m1_wvalid),  .m1_wready(m1_wready),
    .m1_bresp(m1_bresp),  .m1_bvalid(m1_bvalid),.m1_bready(m1_bready),
    .m1_araddr(m1_araddr),.m1_arprot(m1_arprot),.m1_arvalid(m1_arvalid),.m1_arready(m1_arready),
    .m1_rdata(m1_rdata),  .m1_rresp(m1_rresp),  .m1_rvalid(m1_rvalid),  .m1_rready(m1_rready),
    `CONNECT_SLAVE(0), `CONNECT_SLAVE(1), `CONNECT_SLAVE(2), `CONNECT_SLAVE(3)
  );

  // ─── Clock & helpers ──────────────────────────────────────────────────────
  always #CLK_HALF clk = ~clk;
  task tick; begin @(posedge clk); #1; end endtask

  task do_m0_write;
    input [AW-1:0] addr; input [DW-1:0] data; output [1:0] resp;
    begin
      m0_awaddr=addr; m0_awprot=0; m0_awvalid=1;
      m0_wdata=data; m0_wstrb=4'hF; m0_wvalid=1; m0_bready=1;
      tick;
      while (!(m0_awready && m0_wready)) tick;
      m0_awvalid=0; m0_wvalid=0;
      while (!m0_bvalid) tick;
      resp = m0_bresp;
      m0_bready=0;
      tick;
    end
  endtask

  task do_m0_read;
    input [AW-1:0] addr; output [DW-1:0] data; output [1:0] resp;
    begin
      m0_araddr=addr; m0_arprot=0; m0_arvalid=1; m0_rready=1;
      tick;
      while (!m0_arready) tick;
      m0_arvalid=0;
      while (!m0_rvalid) tick;
      data = m0_rdata; resp = m0_rresp;
      m0_rready=0;
      tick;
    end
  endtask

  task do_m1_write;
    input [AW-1:0] addr; input [DW-1:0] data; output [1:0] resp;
    begin
      m1_awaddr=addr; m1_awprot=0; m1_awvalid=1;
      m1_wdata=data; m1_wstrb=4'hF; m1_wvalid=1; m1_bready=1;
      tick;
      while (!(m1_awready && m1_wready)) tick;
      m1_awvalid=0; m1_wvalid=0;
      while (!m1_bvalid) tick;
      resp = m1_bresp;
      m1_bready=0;
      tick;
    end
  endtask

  task do_m1_read;
    input [AW-1:0] addr; output [DW-1:0] data; output [1:0] resp;
    begin
      m1_araddr=addr; m1_arprot=0; m1_arvalid=1; m1_rready=1;
      tick;
      while (!m1_arready) tick;
      m1_arvalid=0;
      while (!m1_rvalid) tick;
      data = m1_rdata; resp = m1_rresp;
      m1_rready=0;
      tick;
    end
  endtask

  // ─── Test body ────────────────────────────────────────────────────────────
  reg [1:0] got_resp; reg [DW-1:0] got_data;

  initial begin
    clk=0; rst_n=0; fail_cnt=0;
    m0_awvalid=0; m0_wvalid=0; m0_bready=0; m0_arvalid=0; m0_rready=0;
    m1_awvalid=0; m1_wvalid=0; m1_bready=0; m1_arvalid=0; m1_rready=0;
    repeat(4) tick;
    rst_n=1;
    repeat(2) tick;

    // T1: M0 → S0 쓰기 (OKAY)
    do_m0_write(32'h4022_0000, 32'hA5A5_0000, got_resp);
    if (got_resp !== 2'b00) begin $display("FAIL T1: got bresp=%b", got_resp); fail_cnt=fail_cnt+1; end
    else $display("T1 OK: M0->S0 write OKAY");

    // T2: M0 → S1 읽기 (OKAY, 데이터 확인)
    do_m0_read(32'h4023_0000, got_data, got_resp);
    if (got_resp !== 2'b00 || got_data !== 32'hCAFE_0001) begin
      $display("FAIL T2: resp=%b data=%h", got_resp, got_data); fail_cnt=fail_cnt+1;
    end else $display("T2 OK: M0->S1 read OKAY data=%h", got_data);

    // T3: M1 → S2 쓰기 (OKAY)
    do_m1_write(32'h4024_0000, 32'hB5B5_0002, got_resp);
    if (got_resp !== 2'b00) begin $display("FAIL T3: got bresp=%b", got_resp); fail_cnt=fail_cnt+1; end
    else $display("T3 OK: M1->S2 write OKAY");

    // T4: M1 → S3 읽기 (OKAY, 데이터 확인)
    do_m1_read(32'h4025_0000, got_data, got_resp);
    if (got_resp !== 2'b00 || got_data !== 32'hCAFE_0003) begin
      $display("FAIL T4: resp=%b data=%h", got_resp, got_data); fail_cnt=fail_cnt+1;
    end else $display("T4 OK: M1->S3 read OKAY data=%h", got_data);

    // T5: M0+M1 동시 → S0 쓰기 (M0 우선, M1은 M0 완료 후)
    begin
      reg [1:0] r0, r1;
      m0_awaddr=32'h4022_0004; m0_awprot=0; m0_awvalid=1;
      m0_wdata=32'hC0C0_0000; m0_wstrb=4'hF; m0_wvalid=1; m0_bready=1;
      m1_awaddr=32'h4022_0008; m1_awprot=0; m1_awvalid=1;
      m1_wdata=32'hC1C1_0000; m1_wstrb=4'hF; m1_wvalid=1; m1_bready=1;
      tick;
      // M0 should get the grant first
      while (!(m0_awready && m0_wready)) tick;
      m0_awvalid=0; m0_wvalid=0;
      while (!m0_bvalid) tick;
      r0 = m0_bresp; m0_bready=0;
      // M1 should now get the grant
      while (!(m1_awready && m1_wready)) begin tick; end
      m1_awvalid=0; m1_wvalid=0;
      while (!m1_bvalid) tick;
      r1 = m1_bresp; m1_bready=0;
      if (r0 !== 2'b00 || r1 !== 2'b00) begin
        $display("FAIL T5: M0 resp=%b M1 resp=%b (both should be OKAY)", r0, r1);
        fail_cnt=fail_cnt+1;
      end else $display("T5 OK: M0+M1 -> S0, both completed OKAY");
    end

    tick; tick;

    // T6: M0 → 미매핑 주소 쓰기 (DECERR)
    do_m0_write(32'hDEAD_0000, 32'hFF00_0000, got_resp);
    if (got_resp !== 2'b11) begin
      $display("FAIL T6: expected DECERR(11) got=%b", got_resp); fail_cnt=fail_cnt+1;
    end else $display("T6 OK: M0 unmapped write DECERR");

    // T7: M1 → 미매핑 주소 읽기 (DECERR)
    do_m1_read(32'hBAD0_0000, got_data, got_resp);
    if (got_resp !== 2'b11) begin
      $display("FAIL T7: expected DECERR(11) got=%b", got_resp); fail_cnt=fail_cnt+1;
    end else $display("T7 OK: M1 unmapped read DECERR");

    tick; tick;

    if (fail_cnt == 0)
      $display("PASS: 모든 테스트 통과 (%0d/7)", 7-fail_cnt);
    else
      $display("FAIL: %0d건 실패", fail_cnt);

    $finish;
  end

  // 타임아웃
  initial begin
    #50000;
    $display("FAIL: 시뮬레이션 타임아웃 (50us)");
    $finish;
  end

endmodule
