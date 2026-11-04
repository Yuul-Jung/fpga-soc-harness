// mmio-lite 버스: 단일 마스터, 주소 [31:12]로 슬레이브 선택, 읽기 데이터 조합 경로, 항상 ready.
module mmio_bus (
    input  wire        valid,
    input  wire [31:0] addr,
    output wire        sel_gpio,
    output wire        sel_uart,
    output wire        sel_sd,
    input  wire [31:0] rdata_gpio,
    input  wire [31:0] rdata_uart,
    input  wire [31:0] rdata_sd,
    output reg  [31:0] rdata,
    output wire        ready
);
    assign sel_gpio = valid && (addr[31:12] == 20'h10000);
    assign sel_uart = valid && (addr[31:12] == 20'h10001);
    assign sel_sd   = valid && (addr[31:12] == 20'h10002);
    assign ready    = 1'b1;

    always @* begin
        if (addr[31:12] == 20'h10000)      rdata = rdata_gpio;
        else if (addr[31:12] == 20'h10001) rdata = rdata_uart;
        else if (addr[31:12] == 20'h10002) rdata = rdata_sd;
        else                               rdata = 32'h0000_0000;
    end
endmodule
