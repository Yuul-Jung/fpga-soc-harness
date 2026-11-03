---
name: deepbluembedded-stm32-complementary-pwm-dead-time
url: https://deepbluembedded.com/stm32-complementary-pwm-dead-time-code-examples/
source_type: article
vendor: neutral
board: [STM32F103C8T6 Blue Pill (글 서술)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M3)
language: C
tools: [STM32CubeMX, HAL]
bus: none
peripherals: [actuator-servo]
stage: T2
license: unknown (저작권 표기 있음, 재사용 조건 미기재 — 라이선스 확인 필요)
stats: {last_update: 2025-02-07}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://deepbluembedded.com/stm32-complementary-pwm-dead-time-code-examples/]
---
unverified: source_rev — 블로그 글이라 해당 없음

## 요약
STM32의 고급 타이머 TIM1에서 상보(complementary) PWM과 데드타임을 설정하는 HAL 예제 글이다. 20 kHz PWM(ARR 3599, PSC 0, 72 MHz)에 CH1/CH1N을 쓴다(글 서술).

## 구조
- 상보 출력: CH1과 CH1N이 서로 반전, N 출력은 CH1이 low일 때만 high (글 서술).
- 데드타임: 글은 "레지스터 값 ÷ FCLK"의 선형 관계로 설명, 72 MHz에서 1 µs ↔ 값 72. 20 kHz 구동에는 약 0.25~2.5 µs를 권장(글 서술). BDTR 비트 인코딩은 글에 없음(unverified: 레지스터 인코딩).
- 설정: CubeMX 또는 `sBreakDeadTimeConfig.DeadTime` 수정, 시작은 `HAL_TIM_PWM_Start` + `HAL_TIMEx_PWMN_Start`.
- 너무 짧으면 shoot-through, 너무 길면 출력 손실 (글 서술).

## 검증·재현성
- 오실로스코프 측정값이나 시험 코드는 글에서 확인 못 함(unverified: 측정 자료 없음). 코드는 Google Drive 링크로만 제공.

## 한계·위험
- 브레이크 입력 설정은 다루지 않고 다른 글로 넘김. CH1 한 쌍만 다룸. 도입부 문단이 본문과 맞지 않음(글 자체 문제).
- 저작권 표기만 있고 재사용 조건이 없어 코드 복사 금지.

## 재사용 메모
- 내 판단: 데드타임 "값÷클럭" 개념은 FPGA PWM 상보 출력 RTL에서 카운터 기반 지연으로 그대로 옮겨진다. 듀티 엣지마다 N 클럭 대기 후 반대 출력을 올린다.
- 개조: 옮길 부분은 상보 출력 + 데드타임 레지스터(클럭 단위) 구조와 권장 범위 개념 → 프로젝트 IP 표준 AXI4-Lite 레지스터(DEADTIME, 주기, 듀티)로 자체 RTL. 못 옮길 부분은 TIM1 BDTR/브레이크 하드웨어 와 HAL 호출. 시험은 shoot-through 겹침 0을 단언하는 자체 점검 테스트벤치.
- 관련: [[st-community-tim1-complementary-no-deadtime]].
