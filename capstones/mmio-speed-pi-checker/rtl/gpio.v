// gpio.v — 16-bit LED(RW) + 16-bit SW(RO, 2단 동기화)
// 원본: capstones/mmio-pwm-qenc-checker/rtl/gpio.v
`timescale 1ns/1ps
module gpio (
    input  wire        clk,
    input  wire        rst,
    // MMIO 슬레이브 포트
    input  wire        valid,
    input  wire        we,
    input  wire [15:0] off,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata,
    // 보드 I/O
    output reg  [15:0] led,
    input  wire [15:0] sw
);
    reg [15:0] sw_s1, sw_s2;

    always @(posedge clk) begin
        if (rst) begin
            led  <= 16'd0;
            sw_s1 <= 16'd0;
            sw_s2 <= 16'd0;
            rdata <= 32'd0;
        end else begin
            sw_s1 <= sw;
            sw_s2 <= sw_s1;
            if (valid) begin
                case (off)
                    16'h0000: begin
                        rdata <= {16'd0, led};
                        if (we) led <= wdata[15:0];
                    end
                    16'h0004: rdata <= {16'd0, sw_s2};
                    default:  rdata <= 32'd0;
                endcase
            end
        end
    end
endmodule
