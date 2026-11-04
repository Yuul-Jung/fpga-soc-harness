// soc_top.v — SoC 최상위 (PS/2 키보드 수신기 + 스캔코드 디코더) (Verilog-2001)
// 하네스 직접 작성 원본.
//
// 블록:
//   demo_master  — 버스 마스터 (PS/2 폴링 FSM)
//   mmio_bus     — 주소 디코더 (GPIO/UART/KBD)
//   gpio         — GPIO 슬레이브 (LED/SW)
//   uart_tx      — UART TX 슬레이브 (115200 8N1)
//   ps2_rx       — PS/2 프레임 수신기 (11-bit, 하강 에지 샘플)
//   ps2_kbd      — PS/2 키보드 디코더 + MMIO 슬레이브
`timescale 1ns/1ps
module soc_top #(
    parameter CLK_HZ = 100_000_000
) (
    input  wire        clk,
    input  wire        rst,
    // PS/2
    input  wire        ps2_clk_in,
    input  wire        ps2_data_in,
    // GPIO
    input  wire [15:0] sw,
    output wire [15:0] led,
    // UART
    output wire        txd
);
    // ----------------------------------------------------------------
    // 버스 신호
    // ----------------------------------------------------------------
    wire        bus_valid;
    wire        bus_we;
    wire [31:0] bus_addr;
    wire [31:0] bus_wdata;
    wire [31:0] bus_rdata;
    wire        bus_ready;

    // 슬레이브 선택
    wire        sel_gpio, sel_uart, sel_kbd;
    wire [31:0] rdata_gpio, rdata_uart, rdata_kbd;

    // ----------------------------------------------------------------
    // 버스 마스터
    // ----------------------------------------------------------------
    demo_master u_master (
        .clk   (clk),
        .rst   (rst),
        .valid (bus_valid),
        .we    (bus_we),
        .addr  (bus_addr),
        .wdata (bus_wdata),
        .rdata (bus_rdata),
        .ready (bus_ready)
    );

    // ----------------------------------------------------------------
    // 주소 디코더 (MMIO 버스)
    // ----------------------------------------------------------------
    mmio_bus u_bus (
        .valid      (bus_valid),
        .we         (bus_we),
        .addr       (bus_addr),
        .wdata      (bus_wdata),
        .sel_gpio   (sel_gpio),
        .sel_uart   (sel_uart),
        .sel_kbd    (sel_kbd),
        .rdata_gpio (rdata_gpio),
        .rdata_uart (rdata_uart),
        .rdata_kbd  (rdata_kbd),
        .rdata      (bus_rdata),
        .ready      (bus_ready)
    );

    // ----------------------------------------------------------------
    // GPIO 슬레이브
    // ----------------------------------------------------------------
    gpio u_gpio (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_gpio),
        .we    (bus_we),
        .off   (bus_addr[7:0]),
        .wdata (bus_wdata),
        .rdata (rdata_gpio),
        .sw    (sw),
        .led   (led)
    );

    // ----------------------------------------------------------------
    // UART TX 슬레이브
    // ----------------------------------------------------------------
    uart_tx #(
        .CLK_HZ (CLK_HZ),
        .BAUD   (115_200)
    ) u_uart (
        .clk   (clk),
        .rst   (rst),
        .sel   (sel_uart),
        .we    (bus_we),
        .off   (bus_addr[7:0]),
        .wdata (bus_wdata),
        .rdata (rdata_uart),
        .txd   (txd)
    );

    // ----------------------------------------------------------------
    // PS/2 수신기
    // ----------------------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_err;

    ps2_rx u_rx (
        .clk         (clk),
        .rst         (rst),
        .ps2_clk_in  (ps2_clk_in),
        .ps2_data_in (ps2_data_in),
        .rx_data     (rx_data),
        .rx_valid    (rx_valid),
        .rx_err      (rx_err)
    );

    // ----------------------------------------------------------------
    // PS/2 키보드 디코더 + MMIO 슬레이브
    // ----------------------------------------------------------------
    // verilator lint_off UNUSED
    wire kbd_irq;
    // verilator lint_on UNUSED
    ps2_kbd u_kbd (
        .clk      (clk),
        .rst      (rst),
        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .rx_err   (rx_err),
        .sel      (sel_kbd),
        .we       (bus_we),
        .off      (bus_addr[7:0]),
        .wdata    (bus_wdata),
        .rdata    (rdata_kbd),
        .irq      (kbd_irq)
    );
endmodule
