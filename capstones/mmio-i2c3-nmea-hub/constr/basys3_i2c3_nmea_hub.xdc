# basys3_i2c3_nmea_hub.xdc — Basys3 XC7A35T 핀 제약
# I2C: Pmod JA (JA1=SCL, JA2=SDA), UART RX: Pmod JB (JB1=RX)
# 단독 Top 불가 — SoC 환경에서 axil_i2c3_nmea_hub 인스턴스화 후 사용

# ── 시스템 클럭 (100MHz, W5) ──────────────────────────────
set_property PACKAGE_PIN W5 [get_ports aclk]
set_property IOSTANDARD LVCMOS33 [get_ports aclk]
create_clock -add -name sys_clk -period 10.00 -waveform {0 5} [get_ports aclk]

# ── 리셋 (CPU RESETN 또는 외부) ──────────────────────────
# aresetn은 SoC 톱에서 연결. 단독 테스트용 버튼 매핑 예:
# set_property PACKAGE_PIN U18 [get_ports aresetn]
# set_property IOSTANDARD LVCMOS33 [get_ports aresetn]

# ── I2C (Pmod JA) ─────────────────────────────────────────
# JA1 = SCL (오픈드레인, 외부 풀업 필요)
set_property PACKAGE_PIN J1 [get_ports scl]
set_property IOSTANDARD LVCMOS33 [get_ports scl]
set_property DRIVE 4 [get_ports scl]

# JA2 = SDA (오픈드레인, 외부 풀업 필요)
set_property PACKAGE_PIN L2 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports sda]
set_property DRIVE 4 [get_ports sda]

# ── UART RX (Pmod JB1) ────────────────────────────────────
# NEO-6M GPS TX → Basys3 JB1
set_property PACKAGE_PIN A14 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# ── 인터럽트 출력 (SoC에서 연결. 단독 테스트용: LED[0]) ─
# set_property PACKAGE_PIN U16 [get_ports irq_out]
# set_property IOSTANDARD LVCMOS33 [get_ports irq_out]
