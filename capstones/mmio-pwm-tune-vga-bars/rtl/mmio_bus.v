// mmio-lite 버스: 단일 마스터, 주소 [31:12]로 슬레이브 선택(gpio/pwm/vga), 읽기 데이터 조합 경로, 항상 ready.
module mmio_bus (
    input  wire        valid,
    input  wire [31:0] addr,
    output wire        sel_gpio,
    output wire        sel_pwm,
    output wire        sel_vga,
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_pwm,
    input  wire [31:0] rdata_vga,
    output reg  [31:0] rdata,
    output wire        ready
);
    assign sel_gpio = valid && (addr[31:12] == 20'h10000);
    assign sel_pwm  = valid && (addr[31:12] == 20'h10003);
    assign sel_vga  = valid && (addr[31:12] == 20'h10004);
    assign ready    = 1'b1;

    always @* begin
        if (addr[31:12] == 20'h10000)      rdata = rdata_gpio;
        else if (addr[31:12] == 20'h10003) rdata = rdata_pwm;
        else if (addr[31:12] == 20'h10004) rdata = rdata_vga;
        else                               rdata = 32'h0000_0000;
    end
endmodule
