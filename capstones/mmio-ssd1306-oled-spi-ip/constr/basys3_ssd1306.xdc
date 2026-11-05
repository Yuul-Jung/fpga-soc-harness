## basys3_ssd1306.xdc
## Basys3 핀 제약 — axil_ssd1306_spi / basys3_top_ssd1306
## 참고: Basys3 Reference Manual Rev. E
##
## Pmod JA (J1) 핀 배치 — Digilent Pmod OLED (SSD1306 128×32)
##   Pin 1 (JA[0]) = CS_N
##   Pin 2 (JA[1]) = MOSI
##   Pin 3 (JA[2]) = D/C
##   Pin 4 (JA[3]) = RES_N
##   Pin 7 (JA[4]) = VDD_EN
##   Pin 8 (JA[5]) = VBAT_EN
##   Pin 9 (JA[6]) = SCK (Basys3 JA4)
##
## 전압: 3.3V LVCMOS (레벨 변환 불필요)

## 클럭
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk_100mhz]

## 리셋 버튼 (BTNC)
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports reset_btn]

## Pmod JA — SSD1306 SPI
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33} [get_ports ja_cs_n]
set_property -dict {PACKAGE_PIN L2  IOSTANDARD LVCMOS33} [get_ports ja_mosi]
set_property -dict {PACKAGE_PIN J2  IOSTANDARD LVCMOS33} [get_ports ja_dc]
set_property -dict {PACKAGE_PIN G2  IOSTANDARD LVCMOS33} [get_ports ja_res_n]
set_property -dict {PACKAGE_PIN H1  IOSTANDARD LVCMOS33} [get_ports ja_vdd_en]
set_property -dict {PACKAGE_PIN K2  IOSTANDARD LVCMOS33} [get_ports ja_vbat_en]
set_property -dict {PACKAGE_PIN H2  IOSTANDARD LVCMOS33} [get_ports ja_sck]

## 디버그 LED (LD0~LD3)
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led_debug[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led_debug[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led_debug[2]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led_debug[3]}]
