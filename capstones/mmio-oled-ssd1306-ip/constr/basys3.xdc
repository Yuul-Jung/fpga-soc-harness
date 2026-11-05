# basys3.xdc — Basys3 핀 제약 (axil_oled_ssd1306 IP)
# 하네스 원본
# 클럭: W5 (100MHz)
# Pmod JB: SSD1306 SPI 4선 + DC + RES
# 참고: Digilent Basys3 Reference Manual 핀 배치

## 클럭
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## 리셋 버튼 (CENTER, T18 — active low)
set_property PACKAGE_PIN T18 [get_ports cpu_resetn]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_resetn]

## Pmod JB (SPI 연결)
# JB1 → JB0 = CS_N   (Pmod 핀 1, pin J2)
set_property PACKAGE_PIN A14 [get_ports JB0_CS_N]
set_property IOSTANDARD LVCMOS33 [get_ports JB0_CS_N]

# JB2 → JB1 = MOSI   (Pmod 핀 2, pin A14 → 실제 B16)
set_property PACKAGE_PIN B16 [get_ports JB1_MOSI]
set_property IOSTANDARD LVCMOS33 [get_ports JB1_MOSI]

# JB3 → JB2 = SCK    (Pmod 핀 3, pin B15)
set_property PACKAGE_PIN B15 [get_ports JB2_SCK]
set_property IOSTANDARD LVCMOS33 [get_ports JB2_SCK]

# JB4 → JB3 = DC     (Pmod 핀 4, pin A15)
set_property PACKAGE_PIN A15 [get_ports JB3_DC]
set_property IOSTANDARD LVCMOS33 [get_ports JB3_DC]

# JB7 → JB4 = RES_N  (Pmod 핀 7, pin W17)
set_property PACKAGE_PIN W17 [get_ports JB4_RES_N]
set_property IOSTANDARD LVCMOS33 [get_ports JB4_RES_N]

## IRQ (내부 연결용. 실제 Vivado 프로젝트에서 INTC로 라우팅)
# set_property PACKAGE_PIN <IRQ_PIN> [get_ports irq_refresh_done]

## 비트스트림 설정
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## AXI 포트 타이밍 완화 (MicroBlaze V M_AXI_DP와 같은 클럭 도메인)
set_input_delay  -clock sys_clk_pin -min 1.0 [get_ports s_awaddr]
set_input_delay  -clock sys_clk_pin -max 3.0 [get_ports s_awaddr]
set_input_delay  -clock sys_clk_pin -min 1.0 [get_ports s_wdata]
set_input_delay  -clock sys_clk_pin -max 3.0 [get_ports s_wdata]
set_output_delay -clock sys_clk_pin -min 1.0 [get_ports s_awready]
set_output_delay -clock sys_clk_pin -max 3.0 [get_ports s_awready]
