// soc_top.v — demo_master + mmio_bus + 모든 IP 연결
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)

`timescale 1ns/1ps
module soc_top (
    input  wire        clk,
    input  wire        rst_n,
    // GPIO
    output wire [15:0] led,
    input  wire [15:0] sw,
    // UART
    output wire        uart_tx,
    // HC-SR04
    output wire        hc_trig,
    input  wire        hc_echo,
    // DHT11
    output wire        dht_oe,
    input  wire        dht_in,
    // I2C
    output wire        i2c_scl_oe,
    output wire        i2c_sda_oe,
    input  wire        i2c_sda_in
);

    wire [31:0] m_addr, m_wdata, m_rdata;
    wire        m_we;

    wire [31:0] rdata_gpio, rdata_uart, rdata_hub;

    // 마스터
    demo_master u_master (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (m_addr),
        .wdata (m_wdata),
        .we    (m_we),
        .rdata (m_rdata)
    );

    // 버스
    mmio_bus u_bus (
        .addr      (m_addr),
        .wdata     (m_wdata),
        .we        (m_we),
        .rdata     (m_rdata),
        .sel_gpio  (sel_gpio),
        .sel_uart  (sel_uart),
        .sel_hub   (sel_hub),
        .rdata_gpio(rdata_gpio),
        .rdata_uart(rdata_uart),
        .rdata_hub (rdata_hub)
    );

    wire sel_gpio, sel_uart, sel_hub;

    // GPIO
    gpio u_gpio (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (m_addr),
        .wdata (m_wdata),
        .we    (m_we),
        .sel   (sel_gpio),
        .rdata (rdata_gpio),
        .led   (led),
        .sw    (sw)
    );

    // UART TX
    uart_tx u_uart (
        .clk   (clk),
        .rst_n (rst_n),
        .addr  (m_addr),
        .wdata (m_wdata),
        .we    (m_we),
        .sel   (sel_uart),
        .rdata (rdata_uart),
        .tx    (uart_tx)
    );

    // Sensor Hub
    sensor_hub_top u_hub (
        .clk     (clk),
        .rst_n   (rst_n),
        .addr    (m_addr),
        .wdata   (m_wdata),
        .we      (m_we),
        .sel     (sel_hub),
        .rdata   (rdata_hub),
        .trig_o  (hc_trig),
        .echo_i  (hc_echo),
        .dht_oe  (dht_oe),
        .dht_in  (dht_in),
        .scl_oe  (i2c_scl_oe),
        .sda_oe  (i2c_sda_oe),
        .sda_in  (i2c_sda_in)
    );

endmodule
