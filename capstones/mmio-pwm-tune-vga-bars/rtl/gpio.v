// 원본: capstones/mmio-uart-gpio-skeleton/rtl/gpio.v (이 저장소의 자체 원본을 복사)
// GPIO: 0x00 LED(RW, 16bit), 0x04 SW(RO, 2단 동기화된 스위치 16bit)
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

    always @(posedge clk) begin
        sw_s1 <= sw;
        sw_s2 <= sw_s1;
        if (rst)
            led_r <= 16'h0000;
        else if (sel && we && off == 8'h00)
            led_r <= wdata[15:0];
    end

    always @* begin
        case (off)
            8'h00:   rdata = {16'h0000, led_r};
            8'h04:   rdata = {16'h0000, sw_s2};
            default: rdata = 32'h0000_0000;
        endcase
    end
endmodule
