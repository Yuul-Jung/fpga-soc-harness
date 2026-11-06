## basys3_i2s_rx.xdc — Basys3 핀 제약
## INMP441 I2S RX AXI4-Lite IP. Pmod JA 매핑.
## Vivado 2024.2 이상. set_property SEVERITY {WARNING} 대신 개행 형식 사용.

## ─── 클럭 ────────────────────────────────────────────────
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports CLK100MHZ]
set_property PACKAGE_PIN W5    [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]

## ─── 리셋 버튼 (btnC, 하이 활성) ─────────────────────────
set_property PACKAGE_PIN U18   [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## ─── Pmod JA — INMP441 I2S 연결 ─────────────────────────
## JA 상단열: JA1=J1, JA2=L2, JA3=J2, JA4=G2
## JA 하단열: JA7=H1, JA8=K2, JA9=H2, JA10=G3
##
## INMP441 연결:
##   JA1 (J1) → BCLK_OUT (마이크 SCK)
##   JA2 (L2) → LRCLK_OUT (마이크 WS)
##   JA3 (J2) ← DOUT_IN (마이크 SD)
##
set_property PACKAGE_PIN J1    [get_ports JA1]
set_property IOSTANDARD LVCMOS33 [get_ports JA1]

set_property PACKAGE_PIN L2    [get_ports JA2]
set_property IOSTANDARD LVCMOS33 [get_ports JA2]

set_property PACKAGE_PIN J2    [get_ports JA3]
set_property IOSTANDARD LVCMOS33 [get_ports JA3]

## ─── AXI4-Lite 슬레이브 포트 ─────────────────────────────
## 블록 디자인에서 MicroBlaze V에 연결한다.
## 단독 합성 테스트용: 핀 배정 없음 (블록 디자인이 연결)

## ─── 타이밍 예외 ────────────────────────────────────────
## bclk_out / lrclk_out 은 BCLK(≈1.042MHz) 도메인이므로
## AXI4-Lite 클럭(100MHz)과의 CDC 경로는 false_path로 선언한다.
## (내부 bclk_rise/bclk_fall 펄스로 동기화되어 CDC 없음 — 주석으로만 표기)
# set_false_path -from [get_ports JA3] -to [get_clocks sys_clk_pin]
