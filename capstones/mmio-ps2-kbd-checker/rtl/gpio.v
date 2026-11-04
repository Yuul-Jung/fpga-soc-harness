// gpio.v — GPIO 슬레이브 (Verilog-2001)
// 하네스 직접 작성 원본.
// 원본 경로: capstones/mmio-uart-gpio-skeleton/rtl/gpio.v
// 0x00 LED(RW, 16비트), 0x04 SW(RO, 2단 동기화)
`timescale 1ns/1ps
module gpio (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire        we,
    input  wire [7:0]  off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    input  wire [15:0] sw,
    output wire [15:0] led
);
    reg [15:0] led_r;
    reg [15:0] sw_s1, sw_s2;
    assign led = led_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_r <= 16'h0000;
            sw_s1 <= 16'h0000;
            sw_s2 <= 16'h0000;
        end else begin
            sw_s1 <= sw;
            sw_s2 <= sw_s1;
            if (sel && we && (off == 8'h00))
                led_r <= wdata[15:0];
        end
    end

    always @* begin
        case (off)
            8'h00:   rdata = {16'h0000, led_r};
            8'h04:   rdata = {16'h0000, sw_s2};
            default: rdata = 32'h0000_0000;
        endcase
    end
endmodule
