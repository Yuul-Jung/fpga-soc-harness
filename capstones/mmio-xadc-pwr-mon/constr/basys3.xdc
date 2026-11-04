# basys3.xdc — mmio-xadc-pwr-mon 제약 파일
# Basys3 XC7A35T-1CPG236C
# XADC 전원 감시 IP: 외부 핀 없음 (내부 공급 채널만 사용)

# ==============================================================
# 클럭
# ==============================================================
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# ==============================================================
# 리셋 버튼 (btnC)
# ==============================================================
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports btnC]

# ==============================================================
# LED (상태 표시: [4]=irq, [3:0]=기타)
# ==============================================================
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {led[8]}]
set_property -dict {PACKAGE_PIN V3  IOSTANDARD LVCMOS33} [get_ports {led[9]}]
set_property -dict {PACKAGE_PIN W3  IOSTANDARD LVCMOS33} [get_ports {led[10]}]
set_property -dict {PACKAGE_PIN U3  IOSTANDARD LVCMOS33} [get_ports {led[11]}]
set_property -dict {PACKAGE_PIN P3  IOSTANDARD LVCMOS33} [get_ports {led[12]}]
set_property -dict {PACKAGE_PIN N3  IOSTANDARD LVCMOS33} [get_ports {led[13]}]
set_property -dict {PACKAGE_PIN P1  IOSTANDARD LVCMOS33} [get_ports {led[14]}]
set_property -dict {PACKAGE_PIN L1  IOSTANDARD LVCMOS33} [get_ports {led[15]}]

# ==============================================================
# XADC: VP/VN 전용 차동 쌍 (온칩 공급전압 채널 사용)
# 외부 Pmod 연결 없음.
# ==============================================================
# VP/VN는 XADC 프리미티브가 직접 사용. XDC 명시 불필요.

# ==============================================================
# 비트스트림 설정
# ==============================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
