// basys3_top.v — Basys3 보드 최상위 (MMCM 없이 100 MHz 직결)
// 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL (Verilog-2001)
// ECHO 핀: 5V→3.3V 레벨 변환 후 연결 필수 (Pmod JA 3번 예시)
// DHT11 DATA: 풀업 4.7 kΩ to 3.3V
// I2C SDA/SCL: 오픈 드레인 풀업 4.7 kΩ to 3.3V

`timescale 1ns/1ps
module basys3_top (
    input  wire        clk,        // W5: 100 MHz
    input  wire        btnC,       // 리셋 (active high)
    // GPIO
    output wire [15:0] led,
    input  wire [15:0] sw,
    // UART (USB-UART)
    output wire        RsTx,
    // HC-SR04 (Pmod JA)
    output wire        ja1,        // TRIG
    input  wire        ja2,        // ECHO (레벨 변환 후)
    // DHT11 (Pmod JB)
    output wire        jb1_oe,     // DHT_OE → 외부 N-FET 게이트 또는 tri
    input  wire        jb1_in,     // DHT DATA 입력
    // I2C (Pmod JC)
    output wire        jc1_scl_oe, // SCL_OE → N-FET
    output wire        jc2_sda_oe, // SDA_OE → N-FET
    input  wire        jc2_sda_in  // SDA 입력
);

    wire rst_n = ~btnC;

    soc_top u_soc (
        .clk        (clk),
        .rst_n      (rst_n),
        .led        (led),
        .sw         (sw),
        .uart_tx    (RsTx),
        .hc_trig    (ja1),
        .hc_echo    (ja2),
        .dht_oe     (jb1_oe),
        .dht_in     (jb1_in),
        .i2c_scl_oe (jc1_scl_oe),
        .i2c_sda_oe (jc2_sda_oe),
        .i2c_sda_in (jc2_sda_in)
    );

endmodule
