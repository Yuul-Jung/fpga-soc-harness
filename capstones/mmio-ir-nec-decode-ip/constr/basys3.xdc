## basys3.xdc — Basys3 핀 제약 (NEC IR 디코더 AXI4-Lite IP)
## 보드: Digilent Basys3 (XC7A35T-1CPG236C)
## 클럭: 100 MHz (W5)
## 리셋: CPU_RESET 버튼 (T18, 액티브 하이)
## IR 입력: Pmod JA 핀 1 (J1) — TSOP38238 출력 (액티브 로우)
## LED: 디버그 표시 (led[0]=IRQ)

## ---------------------------------------------------------------
## 클럭
## ---------------------------------------------------------------
set_property PACKAGE_PIN W5 [get_ports clk100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk100mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk100mhz]

## ---------------------------------------------------------------
## 리셋 (CPU_RESET 버튼, 액티브 하이)
## ---------------------------------------------------------------
set_property PACKAGE_PIN T18 [get_ports cpu_resetn]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_resetn]

## ---------------------------------------------------------------
## IR 수신 모듈 입력 — Pmod JA 핀 1 (J1)
## TSOP38238: 3.3V 동작, 디모듈레이션 출력 (액티브 로우)
## 풀업은 모듈 내장. 레벨 변환 불필요.
## ---------------------------------------------------------------
set_property PACKAGE_PIN J1 [get_ports ir_in]
set_property IOSTANDARD LVCMOS33 [get_ports ir_in]

## ---------------------------------------------------------------
## LED (디버그)
## led[0] = IRQ (STATUS[0])
## ---------------------------------------------------------------
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

## ---------------------------------------------------------------
## AXI4-Lite 버스 — 실사용 시 MicroBlaze V IP 블록 설계에서
## 자동 연결되므로 핀 제약 불필요. 테스트 전용 보드 단독 실행 시에만
## 아래를 활성화한다 (기본: 주석 처리)
## ---------------------------------------------------------------
## set_property PACKAGE_PIN ... [get_ports s_axi_awaddr[0]]
## ...

## ---------------------------------------------------------------
## 타이밍 예외
## ---------------------------------------------------------------
## 비동기 경로 없음 (IR 입력은 FSM에서 동기 처리됨)
## ir_in은 100 MHz 클럭으로 직접 샘플링; 메타스테이빌리티는
## ir_prev 레지스터(1단 FF)로 처리. 필요 시 2단 동기화기 추가 권장.

## ---------------------------------------------------------------
## 비트스트림 설정
## ---------------------------------------------------------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
