// axil_error_slave.v — AXI4-Lite Error Slave
// 미매핑 주소 요청에 DECERR(2'b11) 응답. 쓰기·읽기 모두 처리.
// Verilog-2001. iverilog/verilator/yosys 호환.
// 원본: fpga-soc-harness 하네스 직접 작성 (2026-11-06)

`timescale 1ns/1ps
module axil_error_slave #(
  parameter DATA_W = 32
) (
  input  wire clk,
  input  wire rst_n,
  // Write address
  input  wire        awvalid,
  output reg         awready,
  // Write data
  input  wire        wvalid,
  output reg         wready,
  // Write response
  output reg  [1:0]  bresp,
  output reg         bvalid,
  input  wire        bready,
  // Read address
  input  wire        arvalid,
  output reg         arready,
  // Read data
  output reg  [DATA_W-1:0] rdata,
  output reg  [1:0]  rresp,
  output reg         rvalid,
  input  wire        rready
);

  // Write state: IDLE → AW_WAIT (got AW, waiting for W) or W_WAIT
  //              → B_WAIT → IDLE
  // Simplification: accept AW+W simultaneously for consistency with xbar
  localparam WR_IDLE   = 2'd0;
  localparam WR_B_WAIT = 2'd1;
  reg [1:0] wr_st;

  // Read state: IDLE → R_WAIT → IDLE
  localparam RD_IDLE   = 1'd0;
  localparam RD_R_WAIT = 1'd1;
  reg rd_st;

  // Write path
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_st   <= WR_IDLE;
      awready <= 1'b0;
      wready  <= 1'b0;
      bvalid  <= 1'b0;
      bresp   <= 2'b11; // DECERR
    end else begin
      case (wr_st)
        WR_IDLE: begin
          if (awvalid && wvalid) begin
            awready <= 1'b1;
            wready  <= 1'b1;
            bvalid  <= 1'b0;
            wr_st   <= WR_B_WAIT;
          end
        end
        WR_B_WAIT: begin
          awready <= 1'b0;
          wready  <= 1'b0;
          bvalid  <= 1'b1;
          bresp   <= 2'b11; // DECERR
          if (bvalid && bready) begin
            bvalid <= 1'b0;
            wr_st  <= WR_IDLE;
          end
        end
        default: wr_st <= WR_IDLE;
      endcase
    end
  end

  // Read path
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_st   <= RD_IDLE;
      arready <= 1'b0;
      rvalid  <= 1'b0;
      rdata   <= {DATA_W{1'b0}};
      rresp   <= 2'b11; // DECERR
    end else begin
      case (rd_st)
        RD_IDLE: begin
          if (arvalid) begin
            arready <= 1'b1;
            rd_st   <= RD_R_WAIT;
          end
        end
        RD_R_WAIT: begin
          arready <= 1'b0;
          rvalid  <= 1'b1;
          rdata   <= {DATA_W{1'bx}}; // undefined data with DECERR
          rresp   <= 2'b11; // DECERR
          if (rvalid && rready) begin
            rvalid <= 1'b0;
            rd_st  <= RD_IDLE;
          end
        end
        default: rd_st <= RD_IDLE;
      endcase
    end
  end

endmodule
