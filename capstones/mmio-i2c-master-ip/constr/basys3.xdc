## basys3.xdc — I2C Master MMIO IP Basys3 제약
## Origin: capstones/mmio-i2c-master-ip/constr/basys3.xdc
## 보드: Digilent Basys3 (XC7A35T-1CPG236C)
## I2C: Pmod JA — JA1=SCL (J1), JA2=SDA (L2)

## 클럭 100 MHz
set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## 리셋 버튼 (BTNC)
set_property PACKAGE_PIN U18  [get_ports btnc]
set_property IOSTANDARD LVCMOS33 [get_ports btnc]

## Pmod JA — 오픈드레인 I2C
## JA1 (상단 1번핀) = SCL
set_property PACKAGE_PIN J1   [get_ports ja1]
set_property IOSTANDARD LVCMOS33 [get_ports ja1]

## JA2 (상단 2번핀) = SDA
set_property PACKAGE_PIN L2   [get_ports ja2]
set_property IOSTANDARD LVCMOS33 [get_ports ja2]

## LED[7:0] — WHO_AM_I 값 표시
set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18  [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15  [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14  [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14  [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
