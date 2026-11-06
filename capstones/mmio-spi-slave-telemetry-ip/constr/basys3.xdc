# basys3.xdc — Basys3 보드 제약 (AXI4-Lite SPI 슬레이브 IP)
# PIN: Pmod JA (JA1~JA4)
#   JA1 = SCLK (SPI 클럭, 입력)
#   JA2 = MOSI (마스터→슬레이브, 입력)
#   JA3 = MISO (슬레이브→마스터, 출력)
#   JA4 = CS_N (칩 선택 액티브 로우, 입력)

## 시스템 클럭 100 MHz
set_property PACKAGE_PIN W5      [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## 리셋 버튼 (중앙)
set_property PACKAGE_PIN U18     [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## Pmod JA — SPI 슬레이브
# JA1 = SCLK
set_property PACKAGE_PIN J1      [get_ports ja0]
set_property IOSTANDARD LVCMOS33 [get_ports ja0]
# JA2 = MOSI
set_property PACKAGE_PIN L2      [get_ports ja1]
set_property IOSTANDARD LVCMOS33 [get_ports ja1]
# JA3 = MISO (출력)
set_property PACKAGE_PIN J2      [get_ports ja2]
set_property IOSTANDARD LVCMOS33 [get_ports ja2]
# JA4 = CS_N
set_property PACKAGE_PIN G2      [get_ports ja3]
set_property IOSTANDARD LVCMOS33 [get_ports ja3]

## LED [3:0]
set_property PACKAGE_PIN U16     [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19     [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19     [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19     [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

## 타이밍 — SPI 클럭을 비동기 입력으로 선언 (CDC 더블 플립플롭 처리)
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin]
