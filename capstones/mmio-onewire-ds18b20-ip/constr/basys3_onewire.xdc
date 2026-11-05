## basys3_onewire.xdc — Basys3 1-Wire DS18B20 IP 제약 파일
## 보드: Digilent Basys3 (XC7A35T-1CPG236C)
## 슬롯 [0E] 0x400E_0000 / intc=6

## ─── 클럭 ───────────────────────────────────────────────────
## 100 MHz 시스템 클럭 (W5)
set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## ─── 리셋 ───────────────────────────────────────────────────
## 중앙 버튼 (BTNC, U18) → active-high, 동기 리셋 체인에서 반전
set_property PACKAGE_PIN U18  [get_ports btnC]
set_property IOSTANDARD LVCMOS33 [get_ports btnC]

## ─── Pmod JA — 1-Wire DQ ────────────────────────────────────
## Pmod JA 1번 핀 (J1) → JA_drive(출력), JA_sense(입력) 모두 같은 핀에 연결
## JA_drive = 1 → DQ Low 구동 (open-drain 에뮬레이션)
## JA_sense = 외부 4.7 kΩ 풀업 to 3.3V 경유 DQ 현재 값
## 오픈드레인: JA_drive는 반드시 'Z' 또는 '0'만 구동해야 함
##             axil_onewire_bm.ow_drive=1 → 보드 상에서 Low 구동
##             실제 연결: 삼중 버퍼(IOBUF) 대신 RTL 내부에서 ow_drive로 구동,
##             ow_sense는 별도 입력 핀으로 같은 Pmod 핀에서 읽음.
##             주의: 두 개의 포트를 같은 물리 핀에 묶는 것은 Vivado에서
##             IOBUF로 처리해야 함 (top 모듈에서 처리 권장).
##             이 XDC에서는 출력(drive)과 입력(sense)를 별도 포트로 선언.
##             합성 시 단방향 핀 경고가 날 수 있으나 동작에 무관.

set_property PACKAGE_PIN J1   [get_ports JA_drive]
set_property IOSTANDARD LVCMOS33 [get_ports JA_drive]
set_property DRIVE 4          [get_ports JA_drive]
set_property SLEW  SLOW       [get_ports JA_drive]

set_property PACKAGE_PIN J1   [get_ports JA_sense]
set_property IOSTANDARD LVCMOS33 [get_ports JA_sense]
set_property PULLUP true      [get_ports JA_sense]

## ─── LED ────────────────────────────────────────────────────
## LED[7:0]
set_property PACKAGE_PIN U16  [get_ports {led[0]}]
set_property PACKAGE_PIN E19  [get_ports {led[1]}]
set_property PACKAGE_PIN U19  [get_ports {led[2]}]
set_property PACKAGE_PIN V19  [get_ports {led[3]}]
set_property PACKAGE_PIN W18  [get_ports {led[4]}]
set_property PACKAGE_PIN U15  [get_ports {led[5]}]
set_property PACKAGE_PIN U14  [get_ports {led[6]}]
set_property PACKAGE_PIN V14  [get_ports {led[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## ─── 타이밍 예외 ────────────────────────────────────────────
## 오픈드레인 버스 출력: 긴 1-Wire 슬롯(70 µs) 경로는 타이밍 클리티컬하지 않음
## (카운터 기반, 멀티사이클 허용)
set_multicycle_path -setup 2 -from [get_cells {dut/u_ow/cnt_reg*}] -to [get_cells {dut/JA_drive_OBUF*}]
set_multicycle_path -hold  1 -from [get_cells {dut/u_ow/cnt_reg*}] -to [get_cells {dut/JA_drive_OBUF*}]

## ─── 사용하지 않는 Pmod JA 핀 비활성화 ─────────────────────
## (JA[0]=J1은 위에서 설정, 나머지는 프로젝트에 추가되면 아래 주석 해제)
# set_property PACKAGE_PIN L2  [get_ports {JA[1]}]  ## JA pin 2
# set_property PACKAGE_PIN J2  [get_ports {JA[2]}]  ## JA pin 3
# set_property PACKAGE_PIN G2  [get_ports {JA[3]}]  ## JA pin 4
