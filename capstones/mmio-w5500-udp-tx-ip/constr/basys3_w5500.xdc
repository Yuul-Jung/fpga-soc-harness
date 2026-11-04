## basys3_w5500.xdc — Basys3 XDC for W5500 UDP TX IP
## Board: Digilent Basys3 (XC7A35T-1CPG236C)
## Pmod JA → W5500 Pmod NIC100 (or 직결 W5500 모듈)
## Origin: capstones/mmio-w5500-udp-tx-ip/constr/basys3_w5500.xdc

## ---- 시스템 클럭 100 MHz ----
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## ---- 리셋 (BTNC, 액티브 하이 → rst_n으로 반전) ----
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst_n]

## ---- Pmod JA ---- (W5500 SPI 인터페이스)
## JA1 → spi_sck  (SCK)
## JA2 → spi_mosi (MOSI)
## JA3 → spi_miso (MISO)
## JA4 → spi_csn  (CSn, 액티브 로우)
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports spi_sck]
set_property -dict { PACKAGE_PIN L2  IOSTANDARD LVCMOS33 } [get_ports spi_mosi]
set_property -dict { PACKAGE_PIN J2  IOSTANDARD LVCMOS33 } [get_ports spi_miso]
set_property -dict { PACKAGE_PIN G2  IOSTANDARD LVCMOS33 } [get_ports spi_csn]

## ---- IRQ 출력 (Pmod JA7, 슬롯 연결용) ----
## irq는 mmio 버스 상위로 연결하므로, 보드 보조 핀으로 노출할 경우에만 활성화
## set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports irq]

## ---- 타이밍 무시 (SPI 비동기 경계) ----
set_false_path -from [get_ports spi_miso]
set_false_path -to   [get_ports spi_sck]
set_false_path -to   [get_ports spi_mosi]
set_false_path -to   [get_ports spi_csn]
