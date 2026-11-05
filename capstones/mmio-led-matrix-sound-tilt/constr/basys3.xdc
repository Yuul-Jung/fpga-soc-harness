# basys3.xdc
# Basys3 핀 제약: mmio-led-matrix-sound-tilt
# 보드: Digilent Basys3 (XC7A35T-1CPG236C)
# 도구: Vivado 2024.2
#
# 외부 연결:
#   Pmod JA (J1): PDM 마이크 (SPH0645LM4H 또는 호환)
#     JA1 = pdm_clk → 마이크 CLK 핀
#     JA2 = pdm_data ← 마이크 DATA 핀
#   Pmod JB (J2): MAX7219 체인 (2× 8×8 도트 매트릭스)
#     JB1 = SPI CLK → MAX7219 CLK
#     JB2 = SPI MOSI(DIN) → MAX7219 DIN
#     JB3 = SPI CS_N(LOAD) → MAX7219 LOAD
#   Pmod JC (J3): ADXL345 (SPI 모드, CS 활성 로우)
#     JC1 = SCLK → ADXL345 SCL/SCLK
#     JC2 = MOSI → ADXL345 SDI/MOSI
#     JC3 = MISO ← ADXL345 SDO/MISO
#     JC4 = CS_N → ADXL345 CS

# =============================================================================
# 클럭
# =============================================================================
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports CLK100MHZ]

# =============================================================================
# 리셋 (CPU_RESETN, 액티브 로우, 슬라이드 스위치 옆 버튼)
# =============================================================================
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports CPU_RESETN]

# =============================================================================
# Pmod JA: PDM 마이크
# JA 커넥터 상단 (J1, 핀 1-4 순)
# =============================================================================
# JA1 = pdm_clk_out (출력)
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports JA1]
# JA2 = pdm_data_in (입력)
set_property -dict {PACKAGE_PIN L2  IOSTANDARD LVCMOS33} [get_ports JA2]

# =============================================================================
# Pmod JB: MAX7219 SPI
# JB 커넥터 상단 (J2, 핀 1-4 순)
# =============================================================================
# JB1 = SPI CLK (출력)
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports JB1]
# JB2 = SPI MOSI/DIN (출력)
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports JB2]
# JB3 = SPI CS_N/LOAD (출력)
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports JB3]

# =============================================================================
# Pmod JC: ADXL345 SPI
# JC 커넥터 상단 (J3, 핀 1-4 순)
# =============================================================================
# JC1 = SCLK (출력)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports JC1]
# JC2 = MOSI (출력)
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports JC2]
# JC3 = MISO (입력)
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports JC3]
# JC4 = CS_N (출력)
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports JC4]

# =============================================================================
# 온보드 LED (디버그)
# =============================================================================
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]
set_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {LED[4]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {LED[5]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {LED[6]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {LED[7]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {LED[8]}]
set_property -dict {PACKAGE_PIN V3  IOSTANDARD LVCMOS33} [get_ports {LED[9]}]
set_property -dict {PACKAGE_PIN W3  IOSTANDARD LVCMOS33} [get_ports {LED[10]}]
set_property -dict {PACKAGE_PIN U3  IOSTANDARD LVCMOS33} [get_ports {LED[11]}]
set_property -dict {PACKAGE_PIN P3  IOSTANDARD LVCMOS33} [get_ports {LED[12]}]
set_property -dict {PACKAGE_PIN N3  IOSTANDARD LVCMOS33} [get_ports {LED[13]}]
set_property -dict {PACKAGE_PIN P1  IOSTANDARD LVCMOS33} [get_ports {LED[14]}]
set_property -dict {PACKAGE_PIN L1  IOSTANDARD LVCMOS33} [get_ports {LED[15]}]

# =============================================================================
# 타이밍 제약 (SPI 출력 — 비동기 경로)
# =============================================================================
# MAX7219 SPI: SCLK ≈ 3.125 MHz, 긴 경로가 없으므로 false path 선언
set_false_path -to [get_ports JB1]
set_false_path -to [get_ports JB2]
set_false_path -to [get_ports JB3]

# ADXL345 SPI: SCLK ≈ 1 MHz
set_false_path -to   [get_ports JC1]
set_false_path -to   [get_ports JC2]
set_false_path -from [get_ports JC3]
set_false_path -to   [get_ports JC4]

# PDM 클럭 출력 (약 1.22 MHz)
set_false_path -to   [get_ports JA1]
set_false_path -from [get_ports JA2]
