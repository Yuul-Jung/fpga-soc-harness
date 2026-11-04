# basys3.xdc — mmio-spwm-deadtime-ip Basys3(XC7A35T) 제약
# 클럭, 리셋 버튼, Pmod JB(SPWM 출력), 상태 LED

# 100 MHz 시스템 클럭
set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# 리셋 버튼 (btnC, active high)
set_property PACKAGE_PIN T18  [get_ports btnC]
set_property IOSTANDARD  LVCMOS33 [get_ports btnC]

# Pmod JB 상단 4핀 (SPWM 보완 출력)
# JB1=HIN_A  JB2=LIN_A  JB3=HIN_B  JB4=LIN_B
set_property PACKAGE_PIN A14  [get_ports jb1]
set_property IOSTANDARD  LVCMOS33 [get_ports jb1]
set_property PACKAGE_PIN A16  [get_ports jb2]
set_property IOSTANDARD  LVCMOS33 [get_ports jb2]
set_property PACKAGE_PIN B15  [get_ports jb3]
set_property IOSTANDARD  LVCMOS33 [get_ports jb3]
set_property PACKAGE_PIN B16  [get_ports jb4]
set_property IOSTANDARD  LVCMOS33 [get_ports jb4]

# 상태 LED (16비트)
set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property PACKAGE_PIN W18  [get_ports {led[4]}]
set_property PACKAGE_PIN U15  [get_ports {led[5]}]
set_property PACKAGE_PIN U14  [get_ports {led[6]}]
set_property PACKAGE_PIN V14  [get_ports {led[7]}]
set_property PACKAGE_PIN V13  [get_ports {led[8]}]
set_property PACKAGE_PIN V3   [get_ports {led[9]}]
set_property PACKAGE_PIN W3   [get_ports {led[10]}]
set_property PACKAGE_PIN U3   [get_ports {led[11]}]
set_property PACKAGE_PIN P3   [get_ports {led[12]}]
set_property PACKAGE_PIN N3   [get_ports {led[13]}]
set_property PACKAGE_PIN P1   [get_ports {led[14]}]
set_property PACKAGE_PIN L1   [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
