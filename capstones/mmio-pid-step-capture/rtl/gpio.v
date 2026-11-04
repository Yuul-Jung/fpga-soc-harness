// gpio.v — GPIO LED/SW 슬레이브 (mmio-pid-step-capture)
// 0x00: LED[15:0] (RW, 리셋=0x0000)
// 0x04: SW[15:0]  (RO, 2단 동기화)
// Verilog-2001
`default_nettype none

module gpio (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid,
    input  wire        we,
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire [15:0] sw,
    output reg  [15:0] led
);

    // 2단 동기화기
    reg [15:0] sw_meta, sw_sync;
    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;
    end

    // 쓰기
    always @(posedge clk) begin
        if (rst)
            led <= 16'h0000;
        else if (valid && we && addr == 4'h0)
            led <= wdata[15:0];
    end

    // 읽기
    always @(*) begin
        case (addr)
            4'h0: rdata = {16'h0, led};
            4'h4: rdata = {16'h0, sw_sync};
            default: rdata = 32'h0;
        endcase
    end

endmodule
`default_nettype wire
