## basys3.xdc — Basys3 핀 배정 (mmio-vga-doublebuf-ip)
## 참조: capstones/mmio-vga-tilemap-dashboard/constr/basys3.xdc
## VGA 핀: Basys3 Reference Manual (Digilent, Rev. F)

## 클럭 100 MHz
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk100]

## 리셋 (BTN CENTER, active-low)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports cpu_resetn]

## VGA 수평·수직 동기
set_property -dict { PACKAGE_PIN P19 IOSTANDARD LVCMOS33 } [get_ports vga_hs]
set_property -dict { PACKAGE_PIN R19 IOSTANDARD LVCMOS33 } [get_ports vga_vs]

## VGA Red [3:0]
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports {vga_r[0]}]
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports {vga_r[1]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports {vga_r[2]}]
set_property -dict { PACKAGE_PIN N19 IOSTANDARD LVCMOS33 } [get_ports {vga_r[3]}]

## VGA Green [3:0]
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {vga_g[0]}]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports {vga_g[1]}]
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {vga_g[2]}]
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports {vga_g[3]}]

## VGA Blue [3:0]
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports {vga_b[0]}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {vga_b[1]}]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports {vga_b[2]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {vga_b[3]}]

## AXI 포트: set_false_path (클럭 분주 출력, basys3_top 단독 테스트 시)
## 실 MicroBlaze V 연결 시 이 줄을 제거하고 AXI Master 쪽 XDC와 병합
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports {vga_*}]
