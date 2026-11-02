---
name: unipi-se-custom-peripheral-pwm
url: https://docenti.ing.unipi.it/~a011468/didattica/SE/Ppt/10_Custom_Peripheral_Tutorial.pdf
source_type: course
vendor: intel
board: [Cyclone II EP2C35 (보드명 미기재)]
fit_basys3: needs-port
cpu: Nios II
language: Verilog, C
tools: [Quartus II, Qsys, Eclipse]
bus: Avalon-MM
peripherals: [actuator-servo]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-02
sources: [https://docenti.ing.unipi.it/~a011468/didattica/SE/Ppt/10_Custom_Peripheral_Tutorial.pdf]
---

## 요약
피사 대학 임베디드 시스템 강의 자료. Nios II 시스템에 Verilog PWM 주변장치를 Qsys 사용자 컴포넌트로 붙이고 C 드라이버로 LED 밝기를 바꾸는 단계별 튜토리얼. 사용자 정의 IP 입문(T3).

## 구조
- 모듈 unipi_se_pwm.v: 32비트 업카운터가 PERIOD에서 0으로 돌아가며 출력을 세트하고 COMPARE에서 클리어. 포트는 address, clk, reset_n, read, write, writedata, readdata, pwm_out. 파라미터 RESET_PERIOD, RESET_COMPARE, RESET_PWM_ENABLE.
- 레지스터 3개: CONTROL(1비트 활성화), PERIOD(32비트, 주기 = 클럭 주기 x (PERIOD+1)), COMPARE(32비트, 듀티 = (COMPARE+1)/(PERIOD+1), 카운터가 랩할 때 반영되는 버퍼링). 오프셋은 자료에 없음(unverified).
- 절차: Qsys 새 컴포넌트 → HDL 지정 → 신호별 Avalon 인터페이스(clock, reset, memory-mapped slave, conduit) 역할 지정 → 시스템에 연결 → Quartus에서 출력 핀 연결 → Eclipse에서 C 드라이버로 밝기 조정.

## 검증·재현성
- 테스트벤치, 자원 사용: unverified: 자료에 없음.

## 한계·위험
- 변경: 이전 카드는 "PERIOD 쓰기 시 카운터 초기화"를 추정으로 적었으나 재열람(2026-11-02)에서 자료가 PERIOD 쓰기로 카운터가 초기화된다고 직접 서술함을 확인. 이제 사실이며, 한계 서술은 자료에 따로 없음.
- 라이선스 표기 없음 → unknown, 코드 반입 금지.

## 재사용 메모
- 내 판단: PERIOD/COMPARE/CONTROL 3레지스터와 랩 시점 반영(더블 버퍼) 구조는 카드 element14-eoi-blog3-custom-ip-pwm과 같은 계열로, A 트랙 PWM IP 레지스터 설계의 기본형으로 쓸 수 있다.
- 개조: Qsys/Avalon 연결부는 못 옮기고, 카운터·비교기 FSM과 레지스터 의미만 IP 표준 AXI4-Lite 래퍼로 자체 RTL에 새로 쓴다.
