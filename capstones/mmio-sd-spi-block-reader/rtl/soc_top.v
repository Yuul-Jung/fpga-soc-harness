// SoC 코어: 마스터 포트(mmio-lite)를 밖으로 노출한다. 마스터는 데모 FSM, 테스트벤치, 나중에 CPU가 맡는다.
module soc_top #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD   = 115200
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        m_valid,
    input  wire        m_we,
    input  wire [31:0] m_addr,
    input  wire [31:0] m_wdata,
    output wire [31:0] m_rdata,
    output wire        m_ready,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire        uart_txd,
    output wire        sd_cs_n,
    output wire        sd_sclk,
    output wire        sd_mosi,
    input  wire        sd_miso
);
    wire        sel_gpio, sel_uart, sel_sd;
    wire [31:0] rd_gpio, rd_uart, rd_sd;

    mmio_bus u_bus (
        .valid(m_valid), .addr(m_addr),
        .sel_gpio(sel_gpio), .sel_uart(sel_uart), .sel_sd(sel_sd),
        .rdata_gpio(rd_gpio), .rdata_uart(rd_uart), .rdata_sd(rd_sd),
        .rdata(m_rdata), .ready(m_ready)
    );

    gpio u_gpio (
        .clk(clk), .rst(rst), .sel(sel_gpio), .we(m_we),
        .off(m_addr[7:0]), .wdata(m_wdata), .rdata(rd_gpio),
        .sw(sw), .led(led)
    );

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_uart (
        .clk(clk), .rst(rst), .sel(sel_uart), .we(m_we),
        .off(m_addr[7:0]), .wdata(m_wdata), .rdata(rd_uart),
        .txd(uart_txd)
    );

    sd_spi #(.CLK_HZ(CLK_HZ)) u_sd (
        .clk(clk), .rst(rst), .sel(sel_sd), .we(m_we),
        .off(m_addr[7:0]), .wdata(m_wdata), .rdata(rd_sd),
        .sd_cs_n(sd_cs_n), .sd_sclk(sd_sclk), .sd_mosi(sd_mosi), .sd_miso(sd_miso)
    );
endmodule
