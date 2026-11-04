## basys3_imu_cf.xdc — Basys3 XC7A35T 핀 제약 (IMU 상보 필터 IP)
## 클럭: W5 (100 MHz), 리셋: btnC (T17)
## AXI4-Lite 버스는 MicroBlaze V에서 IP 블록으로 연결 (핀 불필요)
## LED 디버그 출력: U16, E19, U19, V19, W18, U15, U14, V14, V13, V3, W3, U3, P3, N3
## 2026-11-04 하네스 자체 작성

## ── 클럭 ─────────────────────────────────────────────────────────────────────
set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## ── 리셋 (btnC) ─────────────────────────────────────────────────────────────
set_property PACKAGE_PIN T17  [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## ── LED[15:0] ────────────────────────────────────────────────────────────────
set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property PACKAGE_PIN W18  [get_ports {led[4]}]
set_property PACKAGE_PIN U15  [get_ports {led[5]}]
set_property PACKAGE_PIN U14  [get_ports {led[6]}]
set_property PACKAGE_PIN V14  [get_ports {led[7]}]
set_property PACKAGE_PIN V13  [get_ports {led[8]}]
set_property PACKAGE_PIN V3   [get_ports {led[9]}]
set_property PACKAGE_PIN W3   [get_ports {led[10]}]
set_property PACKAGE_PIN U3   [get_ports {led[11]}]
set_property PACKAGE_PIN P3   [get_ports {led[12]}]
set_property PACKAGE_PIN N3   [get_ports {led[13]}]
set_property PACKAGE_PIN P1   [get_ports {led[14]}]
set_property PACKAGE_PIN L1   [get_ports {led[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## ── AXI4-Lite 버스: IP 블록 연결 (핀 제약 불필요, MicroBlaze IP 연결) ───────
## s_axil_* 포트는 MicroBlaze V의 M_AXI_DP 포트에서 Vivado IP Integrator로 연결
## 핀 제약을 선언하지 않으면 Vivado IP 연결 시 자동 처리됨

## ── 비트스트림 설정 ──────────────────────────────────────────────────────────
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
