# basys3_xadc_hub.xdc
# Basys3 제약 파일 — XADC 4채널 아날로그 입력 허브
# 보드: Digilent Basys3 (XC7A35T-1CPG236C)

# 시스템 클럭 100 MHz (W5)
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports aclk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports aclk]

# 리셋 버튼 (btnC = U18, 액티브 하이 → 반전하여 aresetn 생성)
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports aresetn]

# JXADC 아날로그 핀은 XADC 프리미티브가 직접 관리하므로
# IOSTANDARD 제약을 추가하지 않는다.
# 전압 분배기(33kΩ + 10kΩ)로 최대 ≈0.77V 인가 필수.
#
# JXADC 핀 배치 (참조: Basys3 Reference Manual, Rev. E):
#   VAUXP0/N0: 핀 1(P) / 핀 7(N)   → JXADC[1]/JXADC[7]
#   VAUXP1/N1: 핀 2(P) / 핀 8(N)   → JXADC[2]/JXADC[8]
#   VAUXP8/N8: 핀 3(P) / 핀 9(N)   → JXADC[3]/JXADC[9]
#   VAUXP9/N9: 핀 4(P) / 핀 10(N)  → JXADC[4]/JXADC[10]
