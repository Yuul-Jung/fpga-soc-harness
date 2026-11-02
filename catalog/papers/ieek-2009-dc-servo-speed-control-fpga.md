---
name: ieek-2009-dc-servo-speed-control-fpga
url: https://koreascience.kr/article/CFKO200918133141392.pub
source_type: paper
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified: 초록 페이지만 열람
tools: [unverified: 초록에 없음]
bus: none
peripherals: [actuator-servo, sensor, debug]
stage: T4
license: unknown
stats: {pages: 3}
doc_language: ko
verification: L2
checked_at: 2026-11-02
status: 초록 페이지만 열람(검색 요약 수준). 본문 PDF는 열람하지 못함
source_rev: n/a
sources: [https://koreascience.kr/article/CFKO200918133141392.pub]
---

## 요약
2009년 대한전자공학회 학술대회에 실린 3쪽 분량 논문으로, FPGA 안에 PID 연산 블록과 PWM 블록을 두어 DC 서보 모터의 속도를 제어한 사례다. 한국어 서지 정보가 있는 국내 자료(검색 요약 기준).

## 구조
- 엔코더의 A상과 90도 늦은 B상 펄스를 HSC 블록이 받아 현재값(PV)을 만들고, 설정값(SV)과의 오차를 PID가 계산한다(초록 서술).
- PID 출력으로 PWM 블록이 H-브리지를 구동한다(초록 서술).
- DAC 인터페이스로 SV, PV, E, MV를 오실로스코프에 내보내 응답을 관찰한다(초록 서술).
- 엔코더 분해능, PWM 주파수, FPGA 소자, 고정소수점 형식: unverified: 초록에 없음.

## 검증·재현성
- 정량 결과와 자원 사용량: unverified: 초록에 수치 없음. 소스 코드 공개 여부도 확인하지 못함.

## 한계·위험
- 키워드에 BLDC가 있으나 제목·초록은 DC 서보라 서로 어긋난다(초록 페이지 기준). 어느 쪽인지 본문 확인 전에는 단정하지 않는다.
- 논문 본문 PDF를 열람하지 않았으므로 구조 세부는 카드 근거로 쓰지 못한다.

## 재사용 메모
- 내 판단: 엔코더 해독(HSC) → 오차 → PID → PWM → 관측용 DAC 출력이라는 블록 순서는 A 트랙 중급(속도 PID)의 블록 분할 근거로 쓸 만하다. 관측용 DAC 출력은 Basys3에 DAC가 없으므로 UART 로그나 7세그/VGA 표시로 바꿔야 한다.
- 개조: 블록(엔코더 카운터, PID, PWM)을 AXI4-Lite 레지스터(SETPOINT, MEASURED, KP/KI/KD, DUTY)로 옮긴다. DAC 출력부는 옮기지 않는다.
