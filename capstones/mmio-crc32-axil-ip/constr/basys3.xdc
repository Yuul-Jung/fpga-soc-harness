## basys3.xdc — CRC-32 AXI4-Lite IP 제약 (Basys3 XC7A35T-1CPG236C)
## slug: mmio-crc32-axil-ip
## 이 IP는 단독 합성 확인용 제약 파일이다.
## Vivado 시스템 통합 시 MicroBlaze V 블록 디자인에서 주소(0x4017_0000)를 배정한다.

## ----------------------------------------------------------------
## 클럭 (100 MHz, W5)
## ----------------------------------------------------------------
set_property PACKAGE_PIN W5 [get_ports s_axi_aclk]
set_property IOSTANDARD LVCMOS33 [get_ports s_axi_aclk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports s_axi_aclk]

## ----------------------------------------------------------------
## 리셋 — btnC (active-low, aresetn = ~btnC)
## ----------------------------------------------------------------
set_property PACKAGE_PIN U18 [get_ports s_axi_aresetn]
set_property IOSTANDARD LVCMOS33 [get_ports s_axi_aresetn]

## ----------------------------------------------------------------
## LED [15:0] — 단독 테스트 시 CRC_OUT[15:0] 표시용 (선택)
## ----------------------------------------------------------------
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V13 [get_ports {led[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN V3  [get_ports {led[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN W3  [get_ports {led[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN U3  [get_ports {led[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN P3  [get_ports {led[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN N3  [get_ports {led[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN P1  [get_ports {led[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN L1  [get_ports {led[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]
