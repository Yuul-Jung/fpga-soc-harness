# basys3.xdc — Basys3 최소 제약 (mmio-ternary-weight-mac-ip)
# 클럭: W5 (100 MHz 온보드 클럭)
# rst_n: 활성-low, U18(btnC)에 연결 — 보드 버튼은 active-high이므로 인버터 필요

set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# btnC → rst_n 인버터 (보드 top 래퍼에서 처리)
set_property PACKAGE_PIN U18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
