---
name: deepbluembedded-stm32-timer-encoder-mode
url: https://deepbluembedded.com/stm32-timer-encoder-mode-stm32-rotary-encoder-interfacing/
source_type: article
vendor: neutral
board: [STM32 (TIM2 사용, 정확한 보드 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M)
language: C (STM32CubeMX/HAL)
tools: [STM32CubeMX]
bus: none
peripherals: [sensor, actuator-servo]
stage: T1
license: unknown (예제 코드에 라이선스 표기 없음, 코드 반입 대상 아님)
stats: {last_update: 2024-01}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://deepbluembedded.com/stm32-timer-encoder-mode-stm32-rotary-encoder-interfacing/]
---
unverified: source_rev — 블로그 글이라 해당 없음

## 요약
STM32의 하드웨어 타이머를 "엔코더 인터페이스 모드"로 두면 직교 신호의 계수와 방향 판정을 CPU 없이 처리한다는 입문 글이다. 로터리 엔코더로 LED 밝기를 조절하는 실습(TIM2 엔코더 + TIM3 PWM)이 예다. 글 발행 2020-06-22, 최종 갱신 2024-01(글 표기).

## 구조
- 타이머가 TI1·TI2 두 입력의 필터 통과 에지로 계수한다. 한 채널의 양 에지만 세면 x2, 두 채널 모두 세면 x4(글 서술). 실습은 두 채널 결합 모드.
- 방향은 TIM2 CR1의 DIR 비트가 전이 순서에 따라 하드웨어로 갱신된다(글 서술).
- 입력 필터 주기는 설정 가능하나 값·튜닝 지침은 글에 없고, 떨림(지터) 질문은 댓글에서 답이 없었다.
- 카운터는 0~ARR 범위로 돌고 실습은 0~65535(16비트로 추정, 글이 폭을 직접 쓰지는 않음). 코드는 4카운트가 한 칸(detent)이라 오른쪽으로 2비트 이동해 표시한다.
- CubeMX 설정: TIM2 combined channels 엔코더, TIM3 PWM, 시스템 클럭 72 MHz.

## 검증·재현성
- 테스트벤치·CI 없음(펌웨어 실습). 예제는 구글 드라이브 내려받기 형식이라 열람하지 않았다. unverified: 소스 코드 내용.

## 한계·위험
- 롤오버(wrap-around) 처리와 필터 값 가이드가 없다(글에 서술 없음).
- 라이선스 미표기 → 코드 반입 금지.

## 재사용 메모
- 내 판단: "필터 → x4 계수 → 방향 비트 → 16비트 카운터 + 소프트웨어가 읽는 구조"는 FPGA 엔코더 IP의 레지스터 모델(COUNT, DIR, 필터 길이 설정)로 그대로 대응된다.
- 개조: 옮길 부분은 필터 N사이클 설정, x2/x4 선택, DIR 상태 비트를 AXI4-Lite 레지스터(`COUNT`, `CTRL`, `STATUS`)로 노출하는 설계 아이디어와 ">>2 표시" 규약. 못 옮길 부분은 STM32 타이머 하드웨어 자체와 CubeMX 설정.
- 같은 주제 카드: [[stm32-community-encoder-rollover-management]] (롤오버 처리), [[kael2209-stm32-speed-position-control-pid]] (완결 프로젝트). 기존 FPGA 쪽: [[element14-arty-s7-artybot-axi-speed-sensing-ip]].
