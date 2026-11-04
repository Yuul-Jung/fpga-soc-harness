// gpio.v — GPIO LED/SW 슬레이브 (MMIO-lite)
// 0x00: LED[15:0] RW  (복귀값 = 마지막 쓴 값)
// 0x04: SW[15:0]  RO  (2단 동기화)

`default_nettype none

module gpio (
    input  wire        clk,
    input  wire        rst,
    // MMIO-lite 슬레이브
    input  wire        valid,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // 보드 I/O
    output reg  [15:0] led,
    input  wire [15:0] sw
);

    reg [15:0] sw_s1, sw_s2;

    always @(posedge clk) begin
        if (rst) begin
            led   <= 16'd0;
            sw_s1 <= 16'd0;
            sw_s2 <= 16'd0;
        end else begin
            sw_s1 <= sw;
            sw_s2 <= sw_s1;
            if (valid && we && addr[7:2] == 6'd0)
                led <= wdata[15:0];
        end
    end

    always @(*) begin
        case (addr[7:2])
            6'd0:    rdata = {16'd0, led};
            6'd1:    rdata = {16'd0, sw_s2};
            default: rdata = 32'd0;
        endcase
    end

endmodule

`default_nettype wire
