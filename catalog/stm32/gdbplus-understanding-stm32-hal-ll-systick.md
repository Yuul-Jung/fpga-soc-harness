---
name: gdbplus-understanding-stm32-hal-ll-systick
url: https://gdbplus.substack.com/p/understanding-stm32-hal-and-ll-drivers
source_type: article
vendor: neutral
board: [unverified: 특정 보드 미기재]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M)
language: C
tools: [STM32CubeMX]
bus: none
peripherals: [debug]
stage: T0
license: unknown (뉴스레터 글)
stats: {last_update: 2026-05-23}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://gdbplus.substack.com/p/understanding-stm32-hal-and-ll-drivers]
---
unverified: source_rev — 블로그 글이라 해당 없음

## 요약
같은 1 ms SysTick 타임베이스를 CMSIS 직접 설정, HAL, LL 세 방식으로 만들어 보며 HAL과 LL의 차이를 설명하는 글이다. 발행 2026-03-09, 마지막 수정 2026-05-23(페이지 메타 표기).

## 구조
- CMSIS: `SysTick_Config(SystemCoreClock / 1000)`. HAL: HAL_Init가 HAL_InitTick으로 SysTick을 설정하고 핸들러가 HAL_IncTick(uwTick 증가), HAL_Delay는 HAL_GetTick을 바쁜 대기. LL: `LL_Init1msTick`을 직접 호출하고 핸들러가 자체 변수를 증가.
- 글의 결론: HAL은 쉽고 이식성이 좋지만 코드가 크고 계층이 많다, LL은 작고 빠르지만 손이 많이 간다, 둘을 섞어 쓸 수 있다.
- FreeRTOS는 SysTick을 스케줄러 틱으로 쓴다고 설명한다.

## 검증·재현성
- 크기·속도 수치 근거는 글에 없다. 예제를 실제 보드에서 돌려 보지 않았다(열람은 본문만).

## 한계·위험
- 글 속 주의점(내가 읽고 추린 것): LL은 타임베이스를 직접 초기화하지 않으면 지연이 끝나지 않는다. HAL(uwTick)과 LL(자체 카운터)을 섞으면 카운터가 둘이고 SysTick_Handler가 충돌할 수 있다. 예시의 LOAD 값 계산에 -1 일관성이 없다. HAL_Delay는 바쁜 대기라 RTOS에서 부적합.

## 재사용 메모
- 내 판단: 타임베이스 한 개를 누가 소유하느냐의 문제는 FPGA SoC에서 타이머 IP 한 개를 HAL형·직접 접근형 코드가 같이 쓸 때의 충돌과 같다. 드라이버 구조에 "타임베이스 소유자 한 곳" 규칙을 두는 근거가 된다.
- 개조: 옮길 부분은 틱 카운터 + 비차단 경과 시간 비교(부호 없는 뺄셈) 패턴을 AXI4-Lite 타이머 IP의 레지스터 모델에 맞춘 드라이버로 쓰는 것. 못 옮길 부분은 SysTick 자체(Cortex-M 전용)와 HAL/LL API.
