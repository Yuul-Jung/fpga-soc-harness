// gpio.v — LED RW / SW RO (2단 동기화)
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// 레지스터: 0x00 LED(RW), 0x04 SW(RO)

`timescale 1ns/1ps
module gpio (
    input  wire        clk,
    input  wire        rst_n,
    // MMIO-lite
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        sel,
    output reg  [31:0] rdata,
    // 핀
    output reg  [15:0] led,
    input  wire [15:0] sw
);

    // 2단 동기화
    reg [15:0] sw_s1, sw_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_s1 <= 16'd0; sw_s2 <= 16'd0;
        end else begin
            sw_s1 <= sw; sw_s2 <= sw_s1;
        end
    end

    // 쓰기
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) led <= 16'd0;
        else if (sel && we && addr[3:0] == 4'h0)
            led <= wdata[15:0];
    end

    // 읽기
    always @(*) begin
        rdata = 32'd0;
        if (sel) begin
            case (addr[3:0])
                4'h0: rdata = {16'd0, led};
                4'h4: rdata = {16'd0, sw_s2};
                default: rdata = 32'd0;
            endcase
        end
    end

endmodule
