## basys3.xdc — mmio-rc-car-arb-ip 핀 제약
## Basys3 (XC7A35T-1CPG236C) 100 MHz 기준
## 외부 신호는 Pmod JA(HC-SR04/서보)와 Pmod JB(모터 드라이버)에 배선한다
## 주의: 보드 실제 배선 전에 사용자가 핀 번호를 확인해야 한다

## ── 클럭 ─────────────────────────────────────────────────────────────
set_property PACKAGE_PIN W5   [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ── 리셋 (버튼 T18 = BTNC, active-high → 톱 래퍼에서 반전) ────────
set_property PACKAGE_PIN T18  [get_ports rst_btn]
set_property IOSTANDARD LVCMOS33 [get_ports rst_btn]

## ── Pmod JA — HC-SR04 초음파 센서 / 서보 ────────────────────────────
## JA 핀 배치: JA1=J1(TRIG), JA2=L2(ECHO-레벨변환후), JA3=J2(PWM_SERVO)
## HC-SR04 ECHO는 5V 출력 → 레벨 변환(예: TXS0101) 후 연결
set_property PACKAGE_PIN J1   [get_ports trig]
set_property IOSTANDARD LVCMOS33 [get_ports trig]

set_property PACKAGE_PIN L2   [get_ports echo]
set_property IOSTANDARD LVCMOS33 [get_ports echo]

set_property PACKAGE_PIN J2   [get_ports pwm_servo]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_servo]

## ── Pmod JB — TB6612FNG 모터 드라이버 ───────────────────────────────
## JB 핀 배치: JB1=A14, JB2=A16, JB3=B15, JB4=B16, JB7=A15, JB8=A17, JB9=C15
set_property PACKAGE_PIN A14  [get_ports ain1]
set_property IOSTANDARD LVCMOS33 [get_ports ain1]

set_property PACKAGE_PIN A16  [get_ports ain2]
set_property IOSTANDARD LVCMOS33 [get_ports ain2]

set_property PACKAGE_PIN B15  [get_ports pwm_a]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_a]

set_property PACKAGE_PIN B16  [get_ports bin1]
set_property IOSTANDARD LVCMOS33 [get_ports bin1]

set_property PACKAGE_PIN A15  [get_ports bin2]
set_property IOSTANDARD LVCMOS33 [get_ports bin2]

set_property PACKAGE_PIN A17  [get_ports pwm_b]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_b]

## ── 인터럽트 (IRQ → 슬라이드 스위치 대신 LED로 확인 가능) ───────────
## 실제 인터럽트 라인은 AXI INTC IP의 IRQ 포트에 연결
## 디버그용: LD0 (U16)
set_property PACKAGE_PIN U16  [get_ports irq]
set_property IOSTANDARD LVCMOS33 [get_ports irq]

## ── 타이밍 예외 ──────────────────────────────────────────────────────
## PWM 출력은 멀티사이클 허용 (레이턴시보다 주파수 중요)
set_multicycle_path 2 -setup -from [get_cells -hier -filter {NAME=~*u_motor/cnt*}]
set_multicycle_path 1 -hold  -from [get_cells -hier -filter {NAME=~*u_motor/cnt*}]
