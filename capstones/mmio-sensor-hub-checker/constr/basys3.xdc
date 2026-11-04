# basys3.xdc — Basys3 핀 제약
# 출처: mmio-sensor-hub-checker 캡스톤 자체 RTL
# 참고: Digilent Basys3 Master XDC (공개 문서)

## 클럭
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## 리셋 (btnC)
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## LED [15:0]
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## Switches [15:0]
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]
set_property PACKAGE_PIN W15 [get_ports {sw[4]}]
set_property PACKAGE_PIN V15 [get_ports {sw[5]}]
set_property PACKAGE_PIN W14 [get_ports {sw[6]}]
set_property PACKAGE_PIN W13 [get_ports {sw[7]}]
set_property PACKAGE_PIN V2  [get_ports {sw[8]}]
set_property PACKAGE_PIN T3  [get_ports {sw[9]}]
set_property PACKAGE_PIN T2  [get_ports {sw[10]}]
set_property PACKAGE_PIN R3  [get_ports {sw[11]}]
set_property PACKAGE_PIN W2  [get_ports {sw[12]}]
set_property PACKAGE_PIN U1  [get_ports {sw[13]}]
set_property PACKAGE_PIN T1  [get_ports {sw[14]}]
set_property PACKAGE_PIN R2  [get_ports {sw[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

## UART (USB-UART TX)
set_property PACKAGE_PIN A18 [get_ports RsTx]
set_property IOSTANDARD LVCMOS33 [get_ports RsTx]

## Pmod JA — HC-SR04
# JA1: TRIG (출력)
set_property PACKAGE_PIN J1 [get_ports ja1]
set_property IOSTANDARD LVCMOS33 [get_ports ja1]
# JA2: ECHO (입력, 5V→3.3V 레벨 변환 후 연결 필수)
set_property PACKAGE_PIN L2 [get_ports ja2]
set_property IOSTANDARD LVCMOS33 [get_ports ja2]

## Pmod JB — DHT11 DATA
# JB1: DHT_OE (N-FET 게이트 또는 오픈 콜렉터 드라이버)
set_property PACKAGE_PIN A14 [get_ports jb1_oe]
set_property IOSTANDARD LVCMOS33 [get_ports jb1_oe]
# JB2: DHT_IN (입력, 풀업 4.7 kΩ to 3.3V)
set_property PACKAGE_PIN A16 [get_ports jb1_in]
set_property IOSTANDARD LVCMOS33 [get_ports jb1_in]

## Pmod JC — I2C
# JC1: SCL_OE (오픈 드레인, N-FET 게이트)
set_property PACKAGE_PIN K17 [get_ports jc1_scl_oe]
set_property IOSTANDARD LVCMOS33 [get_ports jc1_scl_oe]
# JC2: SDA_OE (오픈 드레인, N-FET 게이트)
set_property PACKAGE_PIN M18 [get_ports jc2_sda_oe]
set_property IOSTANDARD LVCMOS33 [get_ports jc2_sda_oe]
# JC3: SDA_IN (입력, 풀업 4.7 kΩ to 3.3V)
set_property PACKAGE_PIN N17 [get_ports jc2_sda_in]
set_property IOSTANDARD LVCMOS33 [get_ports jc2_sda_in]
