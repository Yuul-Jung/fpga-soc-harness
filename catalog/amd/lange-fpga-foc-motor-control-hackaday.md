---
name: lange-fpga-foc-motor-control-hackaday
url: https://hackaday.io/project/27797-field-oriented-control-motor-control-on-fpgas
source_type: article
vendor: amd
board: [Arty A7]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog, C (Vivado HLS 변환 목표)
tools: [Vivado, Vivado HLS]
bus: none
peripherals: [actuator-servo, sensor]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 미완 프로젝트 (마지막 로그 2017-11-25, 파일 0건)
sources: [https://hackaday.io/project/27797-field-oriented-control-motor-control-on-fpgas]
---

## 요약
Hackaday.io 프로젝트 로그. Arty A7에서 FOC 모터 제어를 목표로 직교 엔코더 카운터, PWM 카운터와 타이머, 공간 벡터 변조(C 함수를 HLS로 변환)를 단계별로 시험했다. 완성 사례가 아니라 부분 진행 기록이다.

## 구조
- 보고된 동작: 엔코더 카운터 동작(2017-11-15), PWM 카운터·타이머 동작(작성자가 엄밀 시험 없음이라고 단서를 붙임, 2017-11-21), MegaMoto로 DC 모터 반 브리지 구동(2017-11-18), 공간 벡터 변조 C 함수를 노트북에서 시험(2017-11-25).
- 하드웨어: RC 비행기 모터(Torque 2812T/720), Dynapar 직교 엔코더, MegaMoto Plus 드라이버 2장, 맞춤 듀얼 엔코더 인터페이스 PCB.

## 검증·재현성
- 클럭, 제어 주기, 자원 사용, 저장소: unverified: 페이지에 없음. 닫힌 루프 결과 없음.

## 한계·위험
- Park/Clarke 변환, PI 제어, 데드타임, ADC는 페이지에 언급 없음. 2020년 댓글이 완성 여부를 묻지만 답이 없음 → 완성 근거 없음.
- 라이선스 표기 없음 → unknown. 파일 0건이라 재사용 불가.

## 재사용 메모
- 내 판단: 최상 단계(BLDC/PMSM FOC)가 얼마나 어려운지 보여 주는 S6 실패 사례다. FOC를 한 번에 시도하지 말고 엔코더 → PWM → 데드타임 → 전류 센싱 → 변환 순으로 쪼개야 한다는 교훈으로 쓸 수 있다.
- 개조: 다른 CPU 자료는 아니지만 Arty A7(Artix-7)이라 핀·클럭만 Basys3로 포팅하면 된다. 엔코더·PWM 블록은 IP 표준 래퍼로 새로 쓴다.
