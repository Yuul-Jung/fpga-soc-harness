## basys3.xdc — 클럭 제약만 포함 (시뮬레이션 전용 패키지)
## Basys3 Artix-7 XC7A35T, 100MHz 시스템 클럭 (W5)

set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
