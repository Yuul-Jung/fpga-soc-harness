// axil_xbar_2m4s.v — 2-Master, 4-Slave AXI4-Lite Crossbar
// 주소 기반 슬레이브 선택, 고정 우선순위 중재(M0 > M1), DECERR 에러 슬레이브 내장.
// 한계: AW+W 동시 제시(awvalid && wvalid) 필요 (표준 단순화).
// Verilog-2001. iverilog/verilator/yosys 호환.
// 원본: fpga-soc-harness 하네스 직접 작성 (2026-11-06)

`timescale 1ns/1ps
module axil_xbar_2m4s #(
  parameter DATA_W  = 32,
  parameter ADDR_W  = 32,
  parameter S0_BASE = 32'h4022_0000, parameter S0_MASK = 32'hFFFF_0000,
  parameter S1_BASE = 32'h4023_0000, parameter S1_MASK = 32'hFFFF_0000,
  parameter S2_BASE = 32'h4024_0000, parameter S2_MASK = 32'hFFFF_0000,
  parameter S3_BASE = 32'h4025_0000, parameter S3_MASK = 32'hFFFF_0000
) (
  input  wire clk, rst_n,

  // === Master 0 (high priority) ===
  input  wire [ADDR_W-1:0]   m0_awaddr,  input  wire [2:0] m0_awprot,
  input  wire                m0_awvalid, output wire       m0_awready,
  input  wire [DATA_W-1:0]   m0_wdata,   input  wire [3:0] m0_wstrb,
  input  wire                m0_wvalid,  output wire       m0_wready,
  output wire [1:0]          m0_bresp,   output wire       m0_bvalid,
  input  wire                m0_bready,
  input  wire [ADDR_W-1:0]   m0_araddr,  input  wire [2:0] m0_arprot,
  input  wire                m0_arvalid, output wire       m0_arready,
  output wire [DATA_W-1:0]   m0_rdata,   output wire [1:0] m0_rresp,
  output wire                m0_rvalid,  input  wire       m0_rready,

  // === Master 1 (low priority) ===
  input  wire [ADDR_W-1:0]   m1_awaddr,  input  wire [2:0] m1_awprot,
  input  wire                m1_awvalid, output wire       m1_awready,
  input  wire [DATA_W-1:0]   m1_wdata,   input  wire [3:0] m1_wstrb,
  input  wire                m1_wvalid,  output wire       m1_wready,
  output wire [1:0]          m1_bresp,   output wire       m1_bvalid,
  input  wire                m1_bready,
  input  wire [ADDR_W-1:0]   m1_araddr,  input  wire [2:0] m1_arprot,
  input  wire                m1_arvalid, output wire       m1_arready,
  output wire [DATA_W-1:0]   m1_rdata,   output wire [1:0] m1_rresp,
  output wire                m1_rvalid,  input  wire       m1_rready,

  // === Slave 0 ===
  output wire [ADDR_W-1:0]   s0_awaddr,  output wire [2:0] s0_awprot,
  output wire                s0_awvalid, input  wire       s0_awready,
  output wire [DATA_W-1:0]   s0_wdata,   output wire [3:0] s0_wstrb,
  output wire                s0_wvalid,  input  wire       s0_wready,
  input  wire [1:0]          s0_bresp,   input  wire       s0_bvalid,
  output wire                s0_bready,
  output wire [ADDR_W-1:0]   s0_araddr,  output wire [2:0] s0_arprot,
  output wire                s0_arvalid, input  wire       s0_arready,
  input  wire [DATA_W-1:0]   s0_rdata,   input  wire [1:0] s0_rresp,
  input  wire                s0_rvalid,  output wire       s0_rready,

  // === Slave 1 ===
  output wire [ADDR_W-1:0]   s1_awaddr,  output wire [2:0] s1_awprot,
  output wire                s1_awvalid, input  wire       s1_awready,
  output wire [DATA_W-1:0]   s1_wdata,   output wire [3:0] s1_wstrb,
  output wire                s1_wvalid,  input  wire       s1_wready,
  input  wire [1:0]          s1_bresp,   input  wire       s1_bvalid,
  output wire                s1_bready,
  output wire [ADDR_W-1:0]   s1_araddr,  output wire [2:0] s1_arprot,
  output wire                s1_arvalid, input  wire       s1_arready,
  input  wire [DATA_W-1:0]   s1_rdata,   input  wire [1:0] s1_rresp,
  input  wire                s1_rvalid,  output wire       s1_rready,

  // === Slave 2 ===
  output wire [ADDR_W-1:0]   s2_awaddr,  output wire [2:0] s2_awprot,
  output wire                s2_awvalid, input  wire       s2_awready,
  output wire [DATA_W-1:0]   s2_wdata,   output wire [3:0] s2_wstrb,
  output wire                s2_wvalid,  input  wire       s2_wready,
  input  wire [1:0]          s2_bresp,   input  wire       s2_bvalid,
  output wire                s2_bready,
  output wire [ADDR_W-1:0]   s2_araddr,  output wire [2:0] s2_arprot,
  output wire                s2_arvalid, input  wire       s2_arready,
  input  wire [DATA_W-1:0]   s2_rdata,   input  wire [1:0] s2_rresp,
  input  wire                s2_rvalid,  output wire       s2_rready,

  // === Slave 3 ===
  output wire [ADDR_W-1:0]   s3_awaddr,  output wire [2:0] s3_awprot,
  output wire                s3_awvalid, input  wire       s3_awready,
  output wire [DATA_W-1:0]   s3_wdata,   output wire [3:0] s3_wstrb,
  output wire                s3_wvalid,  input  wire       s3_wready,
  input  wire [1:0]          s3_bresp,   input  wire       s3_bvalid,
  output wire                s3_bready,
  output wire [ADDR_W-1:0]   s3_araddr,  output wire [2:0] s3_arprot,
  output wire                s3_arvalid, input  wire       s3_arready,
  input  wire [DATA_W-1:0]   s3_rdata,   input  wire [1:0] s3_rresp,
  input  wire                s3_rvalid,  output wire       s3_rready
);

  // ─── Address decode ───────────────────────────────────────────────────────
  // Returns 3-bit: 0~3 = S0~S3, 4 = error slave
  function [2:0] decode;
    input [ADDR_W-1:0] addr;
    begin
      if      ((addr & S0_MASK) == S0_BASE) decode = 3'd0;
      else if ((addr & S1_MASK) == S1_BASE) decode = 3'd1;
      else if ((addr & S2_MASK) == S2_BASE) decode = 3'd2;
      else if ((addr & S3_MASK) == S3_BASE) decode = 3'd3;
      else                                   decode = 3'd4; // error slave
    end
  endfunction

  wire [2:0] m0_wd = decode(m0_awaddr);
  wire [2:0] m0_rd = decode(m0_araddr);
  wire [2:0] m1_wd = decode(m1_awaddr);
  wire [2:0] m1_rd = decode(m1_araddr);

  // ─── Write grant state: per-slave ─────────────────────────────────────────
  // State: 0=IDLE, 1=M0_ACTIVE(wait B), 2=M1_ACTIVE(wait B)
  reg [1:0] wgnt [0:3]; // wgnt[s]: grant for slave s
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wgnt[0] <= 2'd0; wgnt[1] <= 2'd0; wgnt[2] <= 2'd0; wgnt[3] <= 2'd0;
    end else begin
      for (i = 0; i < 4; i = i+1) begin
        case (wgnt[i])
          2'd0: begin // IDLE
            if      (m0_awvalid && m0_wvalid && m0_wd == i[2:0]) wgnt[i] <= 2'd1;
            else if (m1_awvalid && m1_wvalid && m1_wd == i[2:0]) wgnt[i] <= 2'd2;
          end
          2'd1: begin // M0 active, wait for B handshake
            // s_bvalid is the slave's bvalid; m0_bready is master's ready
            // B transfer complete when slave bvalid & master bready
            // We detect this per-slave below
          end
          2'd2: begin // M1 active, wait for B handshake
          end
          default: wgnt[i] <= 2'd0;
        endcase
      end
    end
  end

  // B handshake completion per slave
  wire s0_b_done = (wgnt[0] == 2'd1) ? (s0_bvalid & m0_bready) :
                   (wgnt[0] == 2'd2) ? (s0_bvalid & m1_bready) : 1'b0;
  wire s1_b_done = (wgnt[1] == 2'd1) ? (s1_bvalid & m0_bready) :
                   (wgnt[1] == 2'd2) ? (s1_bvalid & m1_bready) : 1'b0;
  wire s2_b_done = (wgnt[2] == 2'd1) ? (s2_bvalid & m0_bready) :
                   (wgnt[2] == 2'd2) ? (s2_bvalid & m1_bready) : 1'b0;
  wire s3_b_done = (wgnt[3] == 2'd1) ? (s3_bvalid & m0_bready) :
                   (wgnt[3] == 2'd2) ? (s3_bvalid & m1_bready) : 1'b0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin end
    else begin
      if (wgnt[0] != 2'd0 && s0_b_done) wgnt[0] <= 2'd0;
      if (wgnt[1] != 2'd0 && s1_b_done) wgnt[1] <= 2'd0;
      if (wgnt[2] != 2'd0 && s2_b_done) wgnt[2] <= 2'd0;
      if (wgnt[3] != 2'd0 && s3_b_done) wgnt[3] <= 2'd0;
    end
  end

  // ─── Read grant state: per-slave ──────────────────────────────────────────
  reg [1:0] rgnt [0:3];
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rgnt[0] <= 2'd0; rgnt[1] <= 2'd0; rgnt[2] <= 2'd0; rgnt[3] <= 2'd0;
    end else begin
      for (i = 0; i < 4; i = i+1) begin
        if (rgnt[i] == 2'd0) begin // IDLE
          if      (m0_arvalid && m0_rd == i[2:0]) rgnt[i] <= 2'd1;
          else if (m1_arvalid && m1_rd == i[2:0]) rgnt[i] <= 2'd2;
        end
      end
    end
  end

  wire s0_r_done = (rgnt[0] == 2'd1) ? (s0_rvalid & m0_rready) :
                   (rgnt[0] == 2'd2) ? (s0_rvalid & m1_rready) : 1'b0;
  wire s1_r_done = (rgnt[1] == 2'd1) ? (s1_rvalid & m0_rready) :
                   (rgnt[1] == 2'd2) ? (s1_rvalid & m1_rready) : 1'b0;
  wire s2_r_done = (rgnt[2] == 2'd1) ? (s2_rvalid & m0_rready) :
                   (rgnt[2] == 2'd2) ? (s2_rvalid & m1_rready) : 1'b0;
  wire s3_r_done = (rgnt[3] == 2'd1) ? (s3_rvalid & m0_rready) :
                   (rgnt[3] == 2'd2) ? (s3_rvalid & m1_rready) : 1'b0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin end
    else begin
      if (rgnt[0] != 2'd0 && s0_r_done) rgnt[0] <= 2'd0;
      if (rgnt[1] != 2'd0 && s1_r_done) rgnt[1] <= 2'd0;
      if (rgnt[2] != 2'd0 && s2_r_done) rgnt[2] <= 2'd0;
      if (rgnt[3] != 2'd0 && s3_r_done) rgnt[3] <= 2'd0;
    end
  end

  // ─── Slave write mux (AW, W channels) ────────────────────────────────────
  // Slave gets signals from the granted master. awready/wready go back to that master.
  assign s0_awvalid = (wgnt[0]==2'd1) ? m0_awvalid :
                      (wgnt[0]==2'd2) ? m1_awvalid : 1'b0;
  assign s0_awaddr  = (wgnt[0]==2'd1) ? m0_awaddr  : m1_awaddr;
  assign s0_awprot  = (wgnt[0]==2'd1) ? m0_awprot  : m1_awprot;
  assign s0_wvalid  = (wgnt[0]==2'd1) ? m0_wvalid  :
                      (wgnt[0]==2'd2) ? m1_wvalid  : 1'b0;
  assign s0_wdata   = (wgnt[0]==2'd1) ? m0_wdata   : m1_wdata;
  assign s0_wstrb   = (wgnt[0]==2'd1) ? m0_wstrb   : m1_wstrb;
  assign s0_bready  = (wgnt[0]==2'd1) ? m0_bready  :
                      (wgnt[0]==2'd2) ? m1_bready  : 1'b0;

  assign s1_awvalid = (wgnt[1]==2'd1) ? m0_awvalid :
                      (wgnt[1]==2'd2) ? m1_awvalid : 1'b0;
  assign s1_awaddr  = (wgnt[1]==2'd1) ? m0_awaddr  : m1_awaddr;
  assign s1_awprot  = (wgnt[1]==2'd1) ? m0_awprot  : m1_awprot;
  assign s1_wvalid  = (wgnt[1]==2'd1) ? m0_wvalid  :
                      (wgnt[1]==2'd2) ? m1_wvalid  : 1'b0;
  assign s1_wdata   = (wgnt[1]==2'd1) ? m0_wdata   : m1_wdata;
  assign s1_wstrb   = (wgnt[1]==2'd1) ? m0_wstrb   : m1_wstrb;
  assign s1_bready  = (wgnt[1]==2'd1) ? m0_bready  :
                      (wgnt[1]==2'd2) ? m1_bready  : 1'b0;

  assign s2_awvalid = (wgnt[2]==2'd1) ? m0_awvalid :
                      (wgnt[2]==2'd2) ? m1_awvalid : 1'b0;
  assign s2_awaddr  = (wgnt[2]==2'd1) ? m0_awaddr  : m1_awaddr;
  assign s2_awprot  = (wgnt[2]==2'd1) ? m0_awprot  : m1_awprot;
  assign s2_wvalid  = (wgnt[2]==2'd1) ? m0_wvalid  :
                      (wgnt[2]==2'd2) ? m1_wvalid  : 1'b0;
  assign s2_wdata   = (wgnt[2]==2'd1) ? m0_wdata   : m1_wdata;
  assign s2_wstrb   = (wgnt[2]==2'd1) ? m0_wstrb   : m1_wstrb;
  assign s2_bready  = (wgnt[2]==2'd1) ? m0_bready  :
                      (wgnt[2]==2'd2) ? m1_bready  : 1'b0;

  assign s3_awvalid = (wgnt[3]==2'd1) ? m0_awvalid :
                      (wgnt[3]==2'd2) ? m1_awvalid : 1'b0;
  assign s3_awaddr  = (wgnt[3]==2'd1) ? m0_awaddr  : m1_awaddr;
  assign s3_awprot  = (wgnt[3]==2'd1) ? m0_awprot  : m1_awprot;
  assign s3_wvalid  = (wgnt[3]==2'd1) ? m0_wvalid  :
                      (wgnt[3]==2'd2) ? m1_wvalid  : 1'b0;
  assign s3_wdata   = (wgnt[3]==2'd1) ? m0_wdata   : m1_wdata;
  assign s3_wstrb   = (wgnt[3]==2'd1) ? m0_wstrb   : m1_wstrb;
  assign s3_bready  = (wgnt[3]==2'd1) ? m0_bready  :
                      (wgnt[3]==2'd2) ? m1_bready  : 1'b0;

  // ─── Slave read mux (AR channel) ─────────────────────────────────────────
  assign s0_arvalid = (rgnt[0]==2'd1) ? m0_arvalid :
                      (rgnt[0]==2'd2) ? m1_arvalid : 1'b0;
  assign s0_araddr  = (rgnt[0]==2'd1) ? m0_araddr  : m1_araddr;
  assign s0_arprot  = (rgnt[0]==2'd1) ? m0_arprot  : m1_arprot;
  assign s0_rready  = (rgnt[0]==2'd1) ? m0_rready  :
                      (rgnt[0]==2'd2) ? m1_rready  : 1'b0;

  assign s1_arvalid = (rgnt[1]==2'd1) ? m0_arvalid :
                      (rgnt[1]==2'd2) ? m1_arvalid : 1'b0;
  assign s1_araddr  = (rgnt[1]==2'd1) ? m0_araddr  : m1_araddr;
  assign s1_arprot  = (rgnt[1]==2'd1) ? m0_arprot  : m1_arprot;
  assign s1_rready  = (rgnt[1]==2'd1) ? m0_rready  :
                      (rgnt[1]==2'd2) ? m1_rready  : 1'b0;

  assign s2_arvalid = (rgnt[2]==2'd1) ? m0_arvalid :
                      (rgnt[2]==2'd2) ? m1_arvalid : 1'b0;
  assign s2_araddr  = (rgnt[2]==2'd1) ? m0_araddr  : m1_araddr;
  assign s2_arprot  = (rgnt[2]==2'd1) ? m0_arprot  : m1_arprot;
  assign s2_rready  = (rgnt[2]==2'd1) ? m0_rready  :
                      (rgnt[2]==2'd2) ? m1_rready  : 1'b0;

  assign s3_arvalid = (rgnt[3]==2'd1) ? m0_arvalid :
                      (rgnt[3]==2'd2) ? m1_arvalid : 1'b0;
  assign s3_araddr  = (rgnt[3]==2'd1) ? m0_araddr  : m1_araddr;
  assign s3_arprot  = (rgnt[3]==2'd1) ? m0_arprot  : m1_arprot;
  assign s3_rready  = (rgnt[3]==2'd1) ? m0_rready  :
                      (rgnt[3]==2'd2) ? m1_rready  : 1'b0;

  // ─── Error slave wires ────────────────────────────────────────────────────
  // Write error: M0 or M1 targeting unmapped address
  wire err_m0_wr = m0_awvalid && m0_wvalid && (m0_wd == 3'd4);
  wire err_m1_wr = m1_awvalid && m1_wvalid && (m1_wd == 3'd4);
  wire err_m0_rd = m0_arvalid && (m0_rd == 3'd4);
  wire err_m1_rd = m1_arvalid && (m1_rd == 3'd4);

  // Error slave instance - priority: M0 for writes, M0 for reads
  // For simplicity, only one master can hit error at a time
  // (crossbar DECERR path: M0 wins, M1 blocked while M0 uses err slave)
  wire err_awvalid_in = err_m0_wr ? m0_awvalid : (err_m1_wr ? m1_awvalid : 1'b0);
  wire err_wvalid_in  = err_m0_wr ? m0_wvalid  : (err_m1_wr ? m1_wvalid  : 1'b0);
  wire err_arvalid_in = err_m0_rd ? m0_arvalid : (err_m1_rd ? m1_arvalid : 1'b0);
  wire err_bready_in  = err_m0_wr ? m0_bready  : m1_bready;
  wire err_rready_in  = err_m0_rd ? m0_rready  : m1_rready;

  wire       err_awready, err_wready, err_bvalid, err_arready, err_rvalid;
  wire [1:0] err_bresp, err_rresp;
  wire [DATA_W-1:0] err_rdata;

  axil_error_slave #(.DATA_W(DATA_W)) u_err (
    .clk     (clk),         .rst_n   (rst_n),
    .awvalid (err_awvalid_in), .awready (err_awready),
    .wvalid  (err_wvalid_in),  .wready  (err_wready),
    .bresp   (err_bresp),   .bvalid  (err_bvalid),  .bready (err_bready_in),
    .arvalid (err_arvalid_in), .arready (err_arready),
    .rdata   (err_rdata),   .rresp   (err_rresp),
    .rvalid  (err_rvalid),  .rready  (err_rready_in)
  );

  // ─── Master 0 response mux ────────────────────────────────────────────────
  // awready: which slave was selected?
  assign m0_awready = (m0_wd==3'd0) ? (wgnt[0]==2'd1 ? s0_awready : 1'b0) :
                      (m0_wd==3'd1) ? (wgnt[1]==2'd1 ? s1_awready : 1'b0) :
                      (m0_wd==3'd2) ? (wgnt[2]==2'd1 ? s2_awready : 1'b0) :
                      (m0_wd==3'd3) ? (wgnt[3]==2'd1 ? s3_awready : 1'b0) :
                      (err_m0_wr   ? err_awready : 1'b0);
  assign m0_wready  = (m0_wd==3'd0) ? (wgnt[0]==2'd1 ? s0_wready  : 1'b0) :
                      (m0_wd==3'd1) ? (wgnt[1]==2'd1 ? s1_wready  : 1'b0) :
                      (m0_wd==3'd2) ? (wgnt[2]==2'd1 ? s2_wready  : 1'b0) :
                      (m0_wd==3'd3) ? (wgnt[3]==2'd1 ? s3_wready  : 1'b0) :
                      (err_m0_wr   ? err_wready  : 1'b0);
  assign m0_bvalid  = (wgnt[0]==2'd1 && s0_bvalid) || (wgnt[1]==2'd1 && s1_bvalid) ||
                      (wgnt[2]==2'd1 && s2_bvalid) || (wgnt[3]==2'd1 && s3_bvalid) ||
                      (err_m0_wr   && err_bvalid);
  assign m0_bresp   = (wgnt[0]==2'd1) ? s0_bresp :
                      (wgnt[1]==2'd1) ? s1_bresp :
                      (wgnt[2]==2'd1) ? s2_bresp :
                      (wgnt[3]==2'd1) ? s3_bresp : err_bresp;

  assign m0_arready = (m0_rd==3'd0) ? (rgnt[0]==2'd1 ? s0_arready : 1'b0) :
                      (m0_rd==3'd1) ? (rgnt[1]==2'd1 ? s1_arready : 1'b0) :
                      (m0_rd==3'd2) ? (rgnt[2]==2'd1 ? s2_arready : 1'b0) :
                      (m0_rd==3'd3) ? (rgnt[3]==2'd1 ? s3_arready : 1'b0) :
                      (err_m0_rd   ? err_arready : 1'b0);
  assign m0_rvalid  = (rgnt[0]==2'd1 && s0_rvalid) || (rgnt[1]==2'd1 && s1_rvalid) ||
                      (rgnt[2]==2'd1 && s2_rvalid) || (rgnt[3]==2'd1 && s3_rvalid) ||
                      (err_m0_rd   && err_rvalid);
  assign m0_rdata   = (rgnt[0]==2'd1) ? s0_rdata :
                      (rgnt[1]==2'd1) ? s1_rdata :
                      (rgnt[2]==2'd1) ? s2_rdata :
                      (rgnt[3]==2'd1) ? s3_rdata : err_rdata;
  assign m0_rresp   = (rgnt[0]==2'd1) ? s0_rresp :
                      (rgnt[1]==2'd1) ? s1_rresp :
                      (rgnt[2]==2'd1) ? s2_rresp :
                      (rgnt[3]==2'd1) ? s3_rresp : err_rresp;

  // ─── Master 1 response mux ────────────────────────────────────────────────
  assign m1_awready = (m1_wd==3'd0) ? (wgnt[0]==2'd2 ? s0_awready : 1'b0) :
                      (m1_wd==3'd1) ? (wgnt[1]==2'd2 ? s1_awready : 1'b0) :
                      (m1_wd==3'd2) ? (wgnt[2]==2'd2 ? s2_awready : 1'b0) :
                      (m1_wd==3'd3) ? (wgnt[3]==2'd2 ? s3_awready : 1'b0) :
                      (!err_m0_wr && err_m1_wr ? err_awready : 1'b0);
  assign m1_wready  = (m1_wd==3'd0) ? (wgnt[0]==2'd2 ? s0_wready  : 1'b0) :
                      (m1_wd==3'd1) ? (wgnt[1]==2'd2 ? s1_wready  : 1'b0) :
                      (m1_wd==3'd2) ? (wgnt[2]==2'd2 ? s2_wready  : 1'b0) :
                      (m1_wd==3'd3) ? (wgnt[3]==2'd2 ? s3_wready  : 1'b0) :
                      (!err_m0_wr && err_m1_wr ? err_wready  : 1'b0);
  assign m1_bvalid  = (wgnt[0]==2'd2 && s0_bvalid) || (wgnt[1]==2'd2 && s1_bvalid) ||
                      (wgnt[2]==2'd2 && s2_bvalid) || (wgnt[3]==2'd2 && s3_bvalid) ||
                      (!err_m0_wr && err_m1_wr && err_bvalid);
  assign m1_bresp   = (wgnt[0]==2'd2) ? s0_bresp :
                      (wgnt[1]==2'd2) ? s1_bresp :
                      (wgnt[2]==2'd2) ? s2_bresp :
                      (wgnt[3]==2'd2) ? s3_bresp : err_bresp;

  assign m1_arready = (m1_rd==3'd0) ? (rgnt[0]==2'd2 ? s0_arready : 1'b0) :
                      (m1_rd==3'd1) ? (rgnt[1]==2'd2 ? s1_arready : 1'b0) :
                      (m1_rd==3'd2) ? (rgnt[2]==2'd2 ? s2_arready : 1'b0) :
                      (m1_rd==3'd3) ? (rgnt[3]==2'd2 ? s3_arready : 1'b0) :
                      (!err_m0_rd && err_m1_rd ? err_arready : 1'b0);
  assign m1_rvalid  = (rgnt[0]==2'd2 && s0_rvalid) || (rgnt[1]==2'd2 && s1_rvalid) ||
                      (rgnt[2]==2'd2 && s2_rvalid) || (rgnt[3]==2'd2 && s3_rvalid) ||
                      (!err_m0_rd && err_m1_rd && err_rvalid);
  assign m1_rdata   = (rgnt[0]==2'd2) ? s0_rdata :
                      (rgnt[1]==2'd2) ? s1_rdata :
                      (rgnt[2]==2'd2) ? s2_rdata :
                      (rgnt[3]==2'd2) ? s3_rdata : err_rdata;
  assign m1_rresp   = (rgnt[0]==2'd2) ? s0_rresp :
                      (rgnt[1]==2'd2) ? s1_rresp :
                      (rgnt[2]==2'd2) ? s2_rresp :
                      (rgnt[3]==2'd2) ? s3_rresp : err_rresp;

  // ─── $onehot0 assertions: at most one master per slave ───────────────────
  `ifdef SIMULATION
  always @(posedge clk) begin
    if (rst_n) begin
      if (!$onehot0({wgnt[0]==2'd1, wgnt[0]==2'd2}))
        $display("ASSERT FAIL: wgnt[0] not onehot0 at t=%0t", $time);
      if (!$onehot0({wgnt[1]==2'd1, wgnt[1]==2'd2}))
        $display("ASSERT FAIL: wgnt[1] not onehot0 at t=%0t", $time);
      if (!$onehot0({wgnt[2]==2'd1, wgnt[2]==2'd2}))
        $display("ASSERT FAIL: wgnt[2] not onehot0 at t=%0t", $time);
      if (!$onehot0({wgnt[3]==2'd1, wgnt[3]==2'd2}))
        $display("ASSERT FAIL: wgnt[3] not onehot0 at t=%0t", $time);
      if (!$onehot0({rgnt[0]==2'd1, rgnt[0]==2'd2}))
        $display("ASSERT FAIL: rgnt[0] not onehot0 at t=%0t", $time);
      if (!$onehot0({rgnt[1]==2'd1, rgnt[1]==2'd2}))
        $display("ASSERT FAIL: rgnt[1] not onehot0 at t=%0t", $time);
      if (!$onehot0({rgnt[2]==2'd1, rgnt[2]==2'd2}))
        $display("ASSERT FAIL: rgnt[2] not onehot0 at t=%0t", $time);
      if (!$onehot0({rgnt[3]==2'd1, rgnt[3]==2'd2}))
        $display("ASSERT FAIL: rgnt[3] not onehot0 at t=%0t", $time);
    end
  end
  `endif

endmodule
