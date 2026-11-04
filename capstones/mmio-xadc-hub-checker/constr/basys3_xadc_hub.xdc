# basys3_xadc_hub.xdc
# Basys3 핀 배치: XADC 허브 IP
# 보드: Digilent Basys3 (XC7A35T-1CPG236C)
# 참고: Basys3 Schematic Rev.E, Digilent JXADC 헤더 문서

# ============================================================
# 클럭 (100 MHz 온보드 오실레이터)
# ============================================================
set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

# ============================================================
# 리셋 (중앙 버튼 btnC)
# ============================================================
set_property PACKAGE_PIN T17  [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# ============================================================
# JXADC 아날로그 입력
# VAUXP/N[4]  : JA1(D18) / JA2(E17) — Pmod JA 헤더
# VAUXP/N[5]  : JA3(A13) / JA4(A14) — Pmod JA 헤더
# VAUXP/N[12] : JB1(B16) / JB2(B17) — Pmod JB 헤더
# VAUXP/N[13] : JB3(A16) / JB4(A17) — Pmod JB 헤더
# 주의: JXADC 입력 범위 0~1 V; 3.3 V 직결 금지
# ============================================================
set_property PACKAGE_PIN D18  [get_ports vauxp4]
set_property PACKAGE_PIN E17  [get_ports vauxn4]
set_property IOSTANDARD LVCMOS33 [get_ports {vauxp4 vauxn4}]

set_property PACKAGE_PIN A13  [get_ports vauxp5]
set_property PACKAGE_PIN A14  [get_ports vauxn5]
set_property IOSTANDARD LVCMOS33 [get_ports {vauxp5 vauxn5}]

set_property PACKAGE_PIN B16  [get_ports vauxp12]
set_property PACKAGE_PIN B17  [get_ports vauxn12]
set_property IOSTANDARD LVCMOS33 [get_ports {vauxp12 vauxn12}]

set_property PACKAGE_PIN A16  [get_ports vauxp13]
set_property PACKAGE_PIN A17  [get_ports vauxn13]
set_property IOSTANDARD LVCMOS33 [get_ports {vauxp13 vauxn13}]

# ============================================================
# LED (LD0~LD15)
# ============================================================
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

# ============================================================
# 타이밍 제약 완화 (XADC DRP는 비동기 경로)
# ============================================================
set_false_path -from [get_ports {vauxp4 vauxn4 vauxp5 vauxn5 vauxp12 vauxn12 vauxp13 vauxn13}]
