## basys3_can_fd.xdc — Basys3 핀 제약 (CAN FD RX IP)
## 보드: Digilent Basys3 (XC7A35T-1CPG236C)
## 클럭: W5 (100 MHz), 리셋: U18 (BTN0 액티브 로우), CAN RX: L2 (Pmod JA pin2)

## ── 클럭 ────────────────────────────────────────────────────────────────
set_property PACKAGE_PIN W5   [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk_100mhz]

## ── 리셋 (BTN0, 액티브 로우) ─────────────────────────────────────────────
set_property PACKAGE_PIN U18  [get_ports rst_n_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n_btn]

## ── CAN RX (Pmod JA pin2 = L2) ────────────────────────────────────────
## 트랜시버(TJA1050 등) RXD 핀 → FPGA 입력
set_property PACKAGE_PIN L2   [get_ports can_rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports can_rx_pin]

## ── 타이밍 예외 ────────────────────────────────────────────────────────
## CAN RX는 비동기 입력이므로 입력 경로 타이밍을 false path로 처리
set_false_path -from [get_ports can_rx_pin]
set_false_path -from [get_ports rst_n_btn]
