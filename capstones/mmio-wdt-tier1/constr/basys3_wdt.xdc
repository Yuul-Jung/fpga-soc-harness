# basys3_wdt.xdc — Basys3 보드 제약 (AXI4-Lite 워치독 IP, mmio-wdt-tier1)
# 이 IP는 단독으로 합성하지 않고 SoC 톱 레벨에서 인스턴스화한다.
# 이 파일은 IP 단독 테스트용 클럭 제약만 포함한다.

## 클럭 제약 (Basys3 온보드 100MHz 오실레이터, W5)
set_property PACKAGE_PIN W5 [get_ports aclk]
set_property IOSTANDARD LVCMOS33 [get_ports aclk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports aclk]

## 리셋 (Basys3 CPU_RESET 버튼, U18, active-high → aresetn은 반전)
set_property PACKAGE_PIN U18 [get_ports aresetn]
set_property IOSTANDARD LVCMOS33 [get_ports aresetn]
