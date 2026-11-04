## qenc_basys3.xdc — Basys3 핀 제약
## I-016 엔코더 난이도 사다리 (mmio-qenc-diag-checker, T2)
## Basys3 XC7A35T-1CPG236C

## ── 클럭 ──────────────────────────────────────────────────────
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk]

## ── 리셋 (btnC, active-high) ─────────────────────────────────
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports btnC]

## ── 엔코더 입력 (Pmod JA 상단 핀) ───────────────────────────
## JA[0] = enc_a (JA1, 핀 1)  → Basys3 J1
## JA[1] = enc_b (JA2, 핀 2)  → Basys3 J2
## 5V 엔코더는 3.3V 레벨 변환 필수 (전기 규칙: §17.2)
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports enc_a]
set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports enc_b]

## ── AXI4-Lite 슬레이브 포트 ──────────────────────────────────
## SoC 버스와 연결. 보드 standalone 테스트용 핀 미배정.
## Vivado 외부 포트 오류 억제용 false path
## (실제 SoC 통합 시에는 IP Integrator에서 연결)
set_false_path -from [get_ports s_awaddr*]
set_false_path -from [get_ports s_awvalid]
set_false_path -from [get_ports s_wdata*]
set_false_path -from [get_ports s_wstrb*]
set_false_path -from [get_ports s_wvalid]
set_false_path -from [get_ports s_bready]
set_false_path -from [get_ports s_araddr*]
set_false_path -from [get_ports s_arvalid]
set_false_path -from [get_ports s_rready]
set_false_path -to   [get_ports s_awready]
set_false_path -to   [get_ports s_wready]
set_false_path -to   [get_ports s_bresp*]
set_false_path -to   [get_ports s_bvalid]
set_false_path -to   [get_ports s_arready]
set_false_path -to   [get_ports s_rdata*]
set_false_path -to   [get_ports s_rresp*]
set_false_path -to   [get_ports s_rvalid]

## ── 구성 옵션 ────────────────────────────────────────────────
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
