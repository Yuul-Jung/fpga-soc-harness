---
name: 1988kramer-motor-control
url: https://github.com/1988kramer/motor_control
source_type: repo
vendor: neutral
board: [Arduino 및 유사 MCU (README 서술, 특정 보드 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 라이브러리)
tools: [Arduino IDE]
bus: none
peripherals: [actuator-servo, sensor]
stage: T2
license: unknown (README·파일 목록에 라이선스 없음 → 코드 반입 금지)
stats: {stars: 49, commits: 57}
doc_language: en
verification: L3
checked_at: 2026-11-03
source_rev: "unverified: 페이지에서 커밋 해시가 보이지 않음"
sources: [https://github.com/1988kramer/motor_control]
---

## 요약
TB6612FNG와 직교 엔코더를 쓰는 DC 모터의 속도·위치 제어 Arduino 라이브러리. 클래스를 `Motor`, `Encoder`, `SpeedControl`, `PositionControl` 네 층으로 나눈 점이 구조적 특징이다(README 서술, 차동구동 로봇이 목적).

## 구조
- `Motor`: 방향 핀 2개 + PWM 핀 1개 (TB6612FNG 인터페이스와 동일한 3선).
- `Encoder`: 핀 A/B, 샘플 간격(마이크로초), 모터축 1회전당 틱 수를 받아 속도를 구함. 핀 A 인터럽트에서 `updateCount()` 호출.
- `SpeedControl`: Motor·Encoder 포인터를 받는 PID 속도 제어, 기본 이득 1.0, `setGains()`로 변경. `adjustPWM()`을 샘플 간격과 같은 주기의 타이머 인터럽트에서 호출.
- `PositionControl`: SpeedControl 위에 얹는 근사 위치 제어. 사용 시 `SpeedControl.adjustPWM()`을 따로 호출하지 않음.
- 단위, 샘플 주기 수치, 정수/부동소수 여부: unverified: README에 없음(소스 미열람).

## 검증·재현성
- 테스트·측정 자료: unverified: README에서 확인하지 못함. 빌드는 Arduino 라이브러리 설치 방식(저장소 스크립트 실행 안 함).

## 한계·위험
- 라이선스 없음 → 저작권 기본 보유 상태로 보고 코드를 가져오지 않는다. 라이선스 확인 필요.
- 위치 제어가 "근사"라고 README가 밝힘. 소스 미열람이라 와인드업·포화 처리 여부는 unverified.

## 재사용 메모
- 내 판단: 계층 분리(구동기 / 센서 / 속도 루프 / 위치 루프)는 우리 IP 표준의 "하드웨어 IP + 펌웨어 루프" 분리와 잘 맞는 설계 힌트다. 특히 샘플 간격을 Encoder와 제어기가 공유하는 점은 하드웨어 샘플 타이머 + 인터럽트 구조로 옮기기 쉽다.
- 개조: 구동기(방향 2비트+PWM)와 엔코더 카운터는 AXI4-Lite 레지스터 IP로, SpeedControl/PositionControl은 MicroBlaze V 펌웨어(고정소수점)로 옮긴다. 옮길 수 없는 부분은 Arduino 타이머·핀 인터럽트 API(CPU/MCU 전용 부분, 한 파일로 격리)이다. 코드는 라이선스가 없어 구조만 참고하고 RTL·펌웨어는 새로 쓴다.
