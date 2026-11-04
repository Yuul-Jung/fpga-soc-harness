// gpio_stub.v — GPIO 스텁 (LED/SW 최소 래퍼, 기존 GPIO IP 대체 가능)
// 2026-11-04 하네스 자체 작성 (원본, 외부 코드 복사 아님)

`default_nettype none
module gpio (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] sw,
    output wire [15:0] led,
    // AXI4-Lite (미구현 — 스텁)
    input  wire [7:0]  s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [7:0]  s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready
);

// 스텁: 모든 출력 0
assign led             = 16'b0;
assign s_axil_awready  = 1'b0;
assign s_axil_wready   = 1'b0;
assign s_axil_bresp    = 2'b00;
assign s_axil_bvalid   = 1'b0;
assign s_axil_arready  = 1'b0;
assign s_axil_rdata    = 32'h0;
assign s_axil_rresp    = 2'b00;
assign s_axil_rvalid   = 1'b0;

endmodule
`default_nettype wire
