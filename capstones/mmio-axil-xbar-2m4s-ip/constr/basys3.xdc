## basys3.xdc — Basys3 보드 제약 (axil_xbar_2m4s 데모)
## 대상: Digilent Basys3 (XC7A35T-1CPG236C)
## 작성: fpga-soc-harness 하네스 직접 작성 (2026-11-06)

## ─── 클럭 ─────────────────────────────────────────────────────────────────
create_clock -period 10.000 -name clk100mhz [get_ports clk100mhz]

## ─── 핀 배치 ──────────────────────────────────────────────────────────────
set_property PACKAGE_PIN W5   [get_ports clk100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk100mhz]

## btnC (T17) — active-high 리셋
set_property PACKAGE_PIN T17  [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## LED[0] = s0_arvalid (U16)
set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

## LED[1] = s1_awvalid (E19)
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

## LED[2] = s2_arvalid (U19)
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

## LED[3] = s3_awvalid (V19)
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
