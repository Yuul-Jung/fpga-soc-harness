## basys3_mlp.xdc — Basys3 XC7A35T 제약 파일
## capstone: mmio-mlp-axil-ip
## 2026-11-08
##
## 이 IP는 MicroBlaze V AXI4-Lite 버스에 연결되므로
## 최상위 핀 배치는 MicroBlaze V 프로젝트가 담당한다.
## 아래는 독립 테스트 모드 (basys3_top_mlp) 기준이다.

## 클럭 100 MHz (W5)
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## 리셋 btnC (U18)
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports btnC]

## LED[3:0] (예측 클래스 — 하위 4비트)
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## AXI4-Lite 포트는 MicroBlaze V 블록 디자인에서 연결
## (핀 제약 없음; 내부 버스 연결)
