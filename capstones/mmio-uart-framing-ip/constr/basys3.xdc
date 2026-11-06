## Basys3 제약 파일
## 100 MHz 클럭 (W5)
create_clock -period 10.000 -name CLK100MHZ [get_ports CLK100MHZ]

## 클럭 소스 핀
set_property PACKAGE_PIN W5   [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]

## 중앙 버튼 (리셋)
set_property PACKAGE_PIN U18  [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## Pmod JA 핀1 — UART RX
## Basys3 Pmod JA 커넥터: JA1=J1, JA2=L2, JA3=J2, JA4=G2
## JA7=H1, JA8=K2, JA9=H2, JA10=G3
set_property PACKAGE_PIN J1   [get_ports JA1]
set_property IOSTANDARD LVCMOS33 [get_ports JA1]
set_property PULLUP true [get_ports JA1]

## 7세그 세그먼트 (CA..CG, 공통 양극 — High = OFF)
set_property PACKAGE_PIN W7   [get_ports {seg[6]}]
set_property PACKAGE_PIN W6   [get_ports {seg[5]}]
set_property PACKAGE_PIN U8   [get_ports {seg[4]}]
set_property PACKAGE_PIN V8   [get_ports {seg[3]}]
set_property PACKAGE_PIN U5   [get_ports {seg[2]}]
set_property PACKAGE_PIN V5   [get_ports {seg[1]}]
set_property PACKAGE_PIN U7   [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

## 7세그 애노드 (AN0..AN3)
set_property PACKAGE_PIN U2   [get_ports {an[0]}]
set_property PACKAGE_PIN U4   [get_ports {an[1]}]
set_property PACKAGE_PIN V4   [get_ports {an[2]}]
set_property PACKAGE_PIN W4   [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[*]}]

## 소수점
set_property PACKAGE_PIN V7   [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]

## 타이밍 예외 — 비동기 리셋은 멀티사이클 불필요
set_false_path -from [get_ports btnC]
