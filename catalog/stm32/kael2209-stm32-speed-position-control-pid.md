---
name: kael2209-stm32-speed-position-control-pid
url: https://github.com/kael2209/-STM32-Speed-Position-Control-Using-PID-Algorithm
source_type: repo
vendor: neutral
board: [STM32F103C8T6 (Blue Pill)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M3)
language: C (Keil uVision) + C# WinForms GUI
tools: [Keil uVision, Visual Studio]
bus: none
peripherals: [actuator-servo, sensor, comm-uart]
stage: T2
license: unknown (페이지에 라이선스 표시 없음 → 사실만, 코드 반입 금지)
stats: {commits: 1, last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/kael2209/-STM32-Speed-Position-Control-Using-PID-Algorithm]
---
unverified: source_rev — 페이지에 최신 커밋 SHA가 표시되지 않음

## 요약
Blue Pill로 DC 서보 모터의 속도·위치를 PID로 폐루프 제어하고, PC의 C# GUI로 설정값 전송·실시간 그래프·기록을 하는 프로젝트다. 모터는 NF5475E, 리드스크류와 너트를 구동한다(README 서술).

## 구조
- 모터 드라이버 L298N: 방향 PA11·PA12, PWM은 PB8(ENA). 엔코더 A/B는 PA0·PA1(README 서술).
- 타이머: TIM2 CH1/CH2가 엔코더 인터페이스, TIM4 CH3이 PWM(README 서술).
- 위치 모드는 최대 속도와 접근 속도를 쓴다고 하나 값은 없다.
- unverified: PID 형태(P/PI/PID), 이득, 안티와인드업, 샘플 주기 — README에 서술 없음. 코드(main.c)는 열람하지 않았다.

## 검증·재현성
- 성능 주장(오버슈트 감소, 정상상태 오차 감소)은 수치·그래프 없이 서술만 있다. 데모 영상 링크가 있으나 열람 못 함. 테스트벤치·CI 없음.

## 한계·위험
- 커밋 1건, 라이선스 불명 → 코드 복사 금지. L298N 기반이라 저전력 모터 한정이라고 향후 과제에 적힌 드라이버 교체(LMD18200, BTS7960)로 추정(글 서술).
- 모터 전원을 MCU 보드와 분리하는지는 서술 없음 → unverified.

## 재사용 메모
- 내 판단: "엔코더 모드 타이머 + PWM 타이머 + 드라이버 방향 2핀 + PC 설정값 전송"의 4블록 구성은 이 저장소의 모터 IP 세트(PWM, 엔코더, PID) 구성과 같은 모양이다.
- 개조: 옮길 부분은 속도/위치 모드 전환과 접근 속도 제한이라는 제어 개념, UART 설정값 프로토콜 아이디어(MicroBlaze V 펌웨어가 AXI4-Lite로 PID 이득·설정값을 씀). 못 옮길 부분은 Keil·Blue Pill 핀 배치와 소스 코드 자체.
- 모터 전원은 보드와 분리, GND만 공통(프로젝트 전기 규칙). 라이선스 확인 필요.
- 관련: [[deepbluembedded-stm32-timer-encoder-mode]], [[1988kramer-motor-control]].
