---
name: mit-6111-2018-team18-balancing-robot
url: https://fpga.mit.edu/videos/2018/team18/report.pdf
source_type: report
vendor: amd
board: [CMOD A7-35T, Nexys 4]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [unverified]
bus: none
peripherals: [sensor, actuator-servo, comm-uart, comm-bt, comm-spi]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://fpga.mit.edu/videos/2018/team18/report.pdf]
unverified: 자원 사용(LUT/BRAM), 도구 버전, 코드 공개 여부
---

## 요약
MIT 6.111(2018) 팀 보고서. Pololu Balboa 32U4 로봇의 센서·모터 구동은 마이크로컨트롤러가 맡고, 균형 제어(PI + PD 이중 루프)를 CMOD A7의 순수 Verilog FSM이 UART로 주고받으며 수행한다.

## 구조
- 클럭 12 MHz, 제어 주기 18 ms(약 55 Hz). 센서 6바이트를 9600 baud UART로 받고 모터 속도를 돌려보낸다(보고서 서술).
- 모듈: pidcontrol, reader/reader2(UART 수신), assigner(동기 바이트로 프레이밍), send_organize, uart_out, spi_master(MCP3008 가변저항으로 이득 조정).
- 수 형식: 센서 16비트 부호, 각도 24비트, 모터 누산 32비트, 모터 출력은 13비트 우측 시프트, 명령 ±300 제한. 3.3V↔5V 양방향 레벨 변환기를 사이에 둠.
- Nexys 4가 HC-05 블루투스로 원격 명령을 보냄.

## 검증·재현성
- 로봇 실물 시험 중심. 자체 점검형 테스트벤치와 자원 수치는 보고서에서 확인하지 못함(unverified).

## 한계·위험
- 보고서가 밝힌 것: 가속도계 융합을 안 해 자이로 드리프트 미보정, 전·후진 명령 불안정, 바퀴 불일치로 회전 드리프트, 미분항 잡음 증폭.
- 내가 확인한 불일치: 문서의 각도 감쇠(0.97, 18 ms)와 Verilog(1000/1024, CYCLE_TIME 10)가 다르다.
- 이득을 가변저항으로 바꾸는 배선이 로봇이 넘어질 때 흔들리는 문제를 보고서가 지적.

## 재사용 메모
- 내 판단: "각도 추정식 상수가 문서와 코드에서 어긋난" 사례는 샘플 주기와 필터 계수를 한 곳에서 파라미터화해야 한다는 교훈(1runxu 카드와 같은 계열).
- 내 판단: 센서(IMU+엔코더)를 UART 프레임으로 받고 제어를 FPGA가 하는 구조는 Pmod UART로 Basys3에서도 재현 가능해 보이나 전압 확인 필요.
- 개조: 동기 바이트 프레이밍은 버리고, 이득·목표각·제한값을 IP 표준 레지스터로, PI+PD 이중 루프를 MicroBlaze V C 또는 고정소수점 FSM로 옮긴다. 샘플 주기 파라미터화.
