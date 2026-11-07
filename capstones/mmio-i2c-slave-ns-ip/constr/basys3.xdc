# basys3.xdc — Basys3 핀 제약 (I2C 슬레이브 무클럭스트레칭 AXI4-Lite IP)
# 보드: Digilent Basys3 (XC7A35TCPG236-1)
# 클럭: W5 100 MHz, 리셋: btnC(U18)
# I2C: Pmod JA — JA1(J1)=SCL, JA2(J2)=SDA

# ─── 클럭 ───
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk_100mhz]

# ─── 리셋 (btnC, active-high) ───
set_property PACKAGE_PIN U18 [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

# ─── Pmod JA — I2C 핀 ───
# JA1 (J1 핀 1): SCL 입력
set_property PACKAGE_PIN J1 [get_ports ja1_scl]
set_property IOSTANDARD LVCMOS33 [get_ports ja1_scl]

# JA2 (J1 핀 2): SDA 양방향 (오픈 드레인)
set_property PACKAGE_PIN L2 [get_ports ja2_sda]
set_property IOSTANDARD LVCMOS33 [get_ports ja2_sda]

# ─── 타이밍 예외 ───
# SCL/SDA는 100 kHz I2C 신호 (10µs 주기). 고속 경로가 아니므로 멀티사이클 적용.
set_multicycle_path -setup -from [get_ports ja1_scl] 2
set_multicycle_path -hold  -from [get_ports ja1_scl] 1
set_multicycle_path -setup -from [get_ports ja2_sda] 2
set_multicycle_path -hold  -from [get_ports ja2_sda] 2

# AXI 마스터 포트 — MicroBlaze V 인터커넥트 연결 시 추가 XDC에서 선언.
# 단독 테스트 시 아래 더미 핀을 필요에 따라 활성화한다 (기본: 비활성).
# set_property PACKAGE_PIN ... [get_ports M_AXI_*]
