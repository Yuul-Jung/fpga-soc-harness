// gpio.v — GPIO LED/SW (mmio-lite 슬레이브)
// 0x00 LED(RW, [15:0]), 0x04 SW(RO, 2단 동기화)
`timescale 1ns/1ps
module gpio (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire [15:0] sw,
    output wire [15:0] led
);
    reg  [15:0] led_r;
    reg  [15:0] sw_s0, sw_s1; // 2단 동기화

    assign led = led_r;

    always @(posedge clk) begin
        if (rst) begin
            led_r <= 16'd0;
            sw_s0 <= 16'd0;
            sw_s1 <= 16'd0;
        end else begin
            sw_s0 <= sw;
            sw_s1 <= sw_s0;
            if (sel && we && (off == 16'h0000))
                led_r <= wdata[15:0];
        end
    end

    always @* begin
        case (off)
            16'h0000: rdata = {16'd0, led_r};
            16'h0004: rdata = {16'd0, sw_s1};
            default:  rdata = 32'h0000_0000;
        endcase
    end
endmodule
