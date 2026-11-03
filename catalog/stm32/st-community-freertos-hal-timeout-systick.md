---
name: st-community-freertos-hal-timeout-systick
url: https://community.st.com/t5/stm32-mcus-products/freertos-and-hal-driver-timeout-issue/m-p/472344/highlight/true
source_type: article
vendor: neutral
board: [STM32F4 (정확한 보드 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C (ST HAL + FreeRTOS)
tools: [STM32CubeMX]
bus: I2C
peripherals: [comm-i2c]
stage: T2
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {last_update: 2015-07}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/t5/stm32-mcus-products/freertos-and-hal-driver-timeout-issue/m-p/472344/highlight/true]
---
unverified: source_rev — 포럼 글이라 해당 없음

## 요약
I2C를 DMA로 쓰던 사용자가 FreeRTOS 위에서 HAL 타임아웃이 영원히 끝나지 않아 멈추는 문제를 올린 2014년 스레드(2015년 후속 글 포함)다. FreeRTOS 포트가 SysTick을 가장 낮은 우선순위로 바꿔, 인터럽트 문맥에서 HAL이 `HAL_GetTick()` 기반으로 기다리는 동안 틱이 올라가지 못하는 것이 원인이라는 설명이다.

## 구조
- 값(글 서술): SysTick·PendSV 우선순위 15(최하위), `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` 5. CubeMX 비RTOS 빌드는 SysTick을 최고 우선순위로 둬 문제가 드러나지 않는다.
- 제안된 해법: ISR 안에서 폴링·지연을 하지 말고 세마포어·큐로 일을 태스크로 넘긴다. `HAL_Delay()`는 `vTaskDelay()`로 대체, `HAL_IncTick()`은 `vApplicationTickHook()`에서 호출.
- 작성자는 `HAL_GetTick()`를 ICSR 보류 비트로 보정하는 우회를 썼으나 스스로 임시방편이라 평했다. 마지막 질문(SysTick CountFlag를 항상 폴링해도 되는가)은 답이 없다.
- unverified: ST가 이후 이 문제를 어떻게 고쳤는지.

## 검증·재현성
- 테스트벤치·CI 없음. 재현 코드는 글에 없다.

## 한계·위험
- 2014~2015년 글이라 현재 HAL·CubeMX 버전과 다를 수 있다. 타임베이스 분리(별도 타이머) 같은 최신 대안은 이 글에 없다.
- 라이선스 미표기 → 코드 반입 금지.

## 재사용 메모
- 내 판단: "HAL 블로킹 호출 + RTOS 틱 우선순위 충돌"은 FPGA 쪽에서 I2C 마스터 IP를 인터럽트·FIFO 방식으로 설계하고 펌웨어가 폴링하지 않게 하는 이유의 실패 사례 근거가 된다.
- 개조: 옮길 부분은 "드라이버는 ISR에서 기다리지 않고 완료 인터럽트만 올린다"는 IP 규약과 레지스터 STATUS 비트 설계. 못 옮길 부분은 SysTick·NVIC 우선순위 모델(CPU 전용 인터럽트는 `cpu_irq_<cpu>.c`에 격리).
- 같은 도메인: [[gdbplus-understanding-stm32-hal-ll-systick]].
