---
name: stm32-community-hal-vs-ll
url: https://community.st.com/stm32-mcus-products-25/hal-vs-ll-89879
source_type: article
vendor: neutral
board: [STM32F0·L0·L1·L4 (스레드 언급), 특정 보드 unverified]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M)
language: C
tools: [STM32CubeMX 4.16/4.17 (2016 시점 서술)]
bus: none
peripherals: [comm-uart]
stage: T1
license: unknown (포럼 글)
stats: {last_update: 2021-11-22}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/stm32-mcus-products-25/hal-vs-ll-89879]
---
unverified: source_rev — 포럼 글이라 해당 없음

## 요약
HAL과 LL 드라이버를 언제 쓰느냐는 ST 커뮤니티 질문과 답변 스레드다. 질문은 2016-11-13, 마지막 답은 2021-11-22(열람 표기).

## 구조
- ST 직원 답변: HAL은 높은 수준 API와 이식성, LL은 레지스터 수준 API이고 둘은 상호 보완이다. 같은 주변장치에 둘을 섞지 않으면 공존 가능(2016-12).
- 사용자 사례: GPIO·LPUART1을 HAL에서 LL로 옮기자 빌드 크기가 줄었다(8040→3896이라고 썼으나 열이 무엇인지 글에 없음). 이전하면서 SysTick을 직접 켜야 했고, 당시 CubeMX LL 모드는 LPUART1을 활성화하지 않았다.
- UART 송신은 TC보다 TXE를 기다리는 편이 효율적이라는 팁이 있다.
- 합의된 요약: 시작은 HAL, 최적화가 필요해지면 LL.

## 검증·재현성
- 수치는 사용자 한 명의 보고이며 재현 조건이 글에 없다. 2016~2021 시점의 CubeMX 지원 범위(당시 L4만 LL 프로젝트 생성)는 현재와 다를 수 있다. unverified: 현재 CubeMX의 LL 지원 범위.

## 한계·위험
- 오래된 스레드라 도구 버전 서술이 낡았을 수 있다. 크기 비교는 정량 근거로 쓰지 않는다.

## 재사용 메모
- 내 판단: "상위 편의 계층과 하위 직접 접근 계층을 한 주변장치에 섞지 않는다"는 규칙은 IP 표준 래퍼 드라이버에서 레지스터 직접 접근 경로와 고수준 API를 한 IP에 병행 쓰지 않는 규칙으로 옮길 수 있다.
- 개조: 옮길 부분은 2계층(고수준/레지스터) 드라이버 구조와 혼용 금지 규약, TXE 대기 같은 UART 송신 상태 비트 사용법(UART IP 레지스터 설계 참고). 못 옮길 부분은 ST HAL/LL 코드와 CubeMX 지원 범위.
