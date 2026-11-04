# basys3.xdc — Basys3 핀 배정: OV7670 SCCB 캡처 SoC
# Digilent Basys3 (XC7A35T-1CPG236C)
# 모든 IO: LVCMOS33 (3.3V)

## ---- 시스템 클럭 ----
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

## ---- 리셋 (CPU_RESETN, 가운데 아래 버튼, active-low) ----
set_property PACKAGE_PIN U18 [get_ports cpu_resetn]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_resetn]

## ---- 가운데 버튼 (btnc: START 펄스) ----
set_property PACKAGE_PIN U17 [get_ports btnc]
set_property IOSTANDARD LVCMOS33 [get_ports btnc]

## ---- 스위치 SW[1:0] ----
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]

## ---- LED [3:0] ----
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

## ---- Pmod JA (상단 행: JA1~JA4, 하단 행: JA7~JA10) ----
# JA1 = SIO_C (SCCB 클럭, 출력)
set_property PACKAGE_PIN J1 [get_ports ja1]
set_property IOSTANDARD LVCMOS33 [get_ports ja1]

# JA2 = SIO_D (SCCB 데이터, 양방향 오픈 드레인)
set_property PACKAGE_PIN L2 [get_ports ja2]
set_property IOSTANDARD LVCMOS33 [get_ports ja2]

# JA7 = cam_pclk
set_property PACKAGE_PIN J2 [get_ports ja7]
set_property IOSTANDARD LVCMOS33 [get_ports ja7]

# JA8 = cam_vsync
set_property PACKAGE_PIN G2 [get_ports ja8]
set_property IOSTANDARD LVCMOS33 [get_ports ja8]

# JA9 = cam_href
set_property PACKAGE_PIN H1 [get_ports ja9]
set_property IOSTANDARD LVCMOS33 [get_ports ja9]

# JA10 = cam_d[7]
set_property PACKAGE_PIN K2 [get_ports ja10]
set_property IOSTANDARD LVCMOS33 [get_ports ja10]

## ---- Pmod JB: cam_d[6:3] ----
# JB1 = cam_d[6]
set_property PACKAGE_PIN A14 [get_ports jb1]
set_property IOSTANDARD LVCMOS33 [get_ports jb1]

# JB2 = cam_d[5]
set_property PACKAGE_PIN A16 [get_ports jb2]
set_property IOSTANDARD LVCMOS33 [get_ports jb2]

# JB3 = cam_d[4]
set_property PACKAGE_PIN B15 [get_ports jb3]
set_property IOSTANDARD LVCMOS33 [get_ports jb3]

# JB4 = cam_d[3]
set_property PACKAGE_PIN B16 [get_ports jb4]
set_property IOSTANDARD LVCMOS33 [get_ports jb4]

## ---- Pmod JC: cam_d[2:0] ----
# JC1 = cam_d[2]
set_property PACKAGE_PIN K17 [get_ports jc1]
set_property IOSTANDARD LVCMOS33 [get_ports jc1]

# JC2 = cam_d[1]
set_property PACKAGE_PIN M18 [get_ports jc2]
set_property IOSTANDARD LVCMOS33 [get_ports jc2]

# JC3 = cam_d[0]
set_property PACKAGE_PIN N17 [get_ports jc3]
set_property IOSTANDARD LVCMOS33 [get_ports jc3]

## ---- cam_pclk 클럭 제약 (외부 카메라, 약 24 MHz) ----
create_clock -add -name cam_pclk_pin -period 41.667 -waveform {0 20.833} [get_ports ja7]
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin] -group [get_clocks cam_pclk_pin]

## ---- 타이밍 예외: SCCB (저속 직렬, 타이밍 경로 대신 경과 경로 허용) ----
# SCCB 클럭(100 kHz)이 시스템 클럭으로 분주되므로 멀티사이클 허용
set_multicycle_path -setup 2 -from [get_pins u_core/u_sccb/*] -to [get_pins u_core/u_sccb/*]
set_multicycle_path -hold  1 -from [get_pins u_core/u_sccb/*] -to [get_pins u_core/u_sccb/*]

## ---- 비트스트림 설정 ----
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
