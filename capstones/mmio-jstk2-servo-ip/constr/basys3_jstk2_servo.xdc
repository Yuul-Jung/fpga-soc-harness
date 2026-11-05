## basys3_jstk2_servo.xdc — Basys3 XC7A35T 핀 제약
## Pmod JA: JSTK2 SPI (JA1=CS#, JA2=MOSI, JA3=MISO, JA4=SCLK)
## Pmod JB: 서보 (JB1=SERVO_A, JB2=SERVO_B)

## 클럭 100 MHz
set_property PACKAGE_PIN W5  [get_ports clk100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk100mhz]

## 리셋 버튼 (중앙)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## Pmod JA — JSTK2 SPI
## JA1 = U1 (CS#)
set_property PACKAGE_PIN J1  [get_ports ja1]
set_property IOSTANDARD LVCMOS33 [get_ports ja1]
## JA2 = L2 (MOSI)
set_property PACKAGE_PIN L2  [get_ports ja2]
set_property IOSTANDARD LVCMOS33 [get_ports ja2]
## JA3 = J2 (MISO)
set_property PACKAGE_PIN J2  [get_ports ja3]
set_property IOSTANDARD LVCMOS33 [get_ports ja3]
## JA4 = G2 (SCLK)
set_property PACKAGE_PIN G2  [get_ports ja4]
set_property IOSTANDARD LVCMOS33 [get_ports ja4]

## Pmod JB — 서보 출력
## JB1 = G14 (서보 A)
set_property PACKAGE_PIN G14 [get_ports jb1]
set_property IOSTANDARD LVCMOS33 [get_ports jb1]
## JB2 = F14 (서보 B)
set_property PACKAGE_PIN F14 [get_ports jb2]
set_property IOSTANDARD LVCMOS33 [get_ports jb2]

## LED (디버그)
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
