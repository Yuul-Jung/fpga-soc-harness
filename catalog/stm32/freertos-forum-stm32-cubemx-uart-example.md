---
name: freertos-forum-stm32-cubemx-uart-example
url: https://forums.freertos.org/t/generic-uart-example-for-stm32-using-cubemx-hal/6908
source_type: article
vendor: neutral
board: [STM32 (보드 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M)
language: C (CubeMX HAL + FreeRTOS)
tools: [STM32CubeMX, FreeRTOS v9.0]
bus: none
peripherals: [comm-uart]
stage: T2
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {last_update: 2017-12}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://forums.freertos.org/t/generic-uart-example-for-stm32-using-cubemx-hal/6908]
---
unverified: source_rev — 포럼 글이라 해당 없음

## 요약
Arduino에서 옮겨 온 명령 파서에 쓸 가변 길이 UART 수신을 CubeMX HAL + FreeRTOS에서 어떻게 구성할지 묻는 2017년 12월 스레드다. 답은 코드가 아니라 설계 방향이다: DMA와 원형 버퍼, DMA 종료 인터럽트에서 태스크 알림, 스트림 버퍼.

## 구조
- 제안 1: DMA로 UART와 원형 버퍼 사이를 오가고 DMA 인터럽트가 태스크를 깨운다(2009년 글 인용 서술).
- 제안 2: FreeRTOS 관리자가 FIFO·DMA는 칩별 사항이라 범위 밖이라 하고, ISR→태스크 스트림 버퍼 예제와 직접 태스크 알림을 권했다.
- 작성자는 CubeMX 포함 버전이 v9.0이라 세마포어 대신 태스크 알림을 선호했다. 최종적으로 스트림 버퍼 예제가 원하던 형태라고 답했다.
- 구체 수치(버퍼 크기, 우선순위)는 스레드에 없다. unverified: 실제 구현 코드.

## 검증·재현성
- 테스트벤치·CI 없음, 동작 보고 없음. 설계 논의만 있다.

## 한계·위험
- 문제·디버깅 과정이 거의 없어 실패 사례로는 약하다. 구현 검증은 없다(글에 서술 없음).
- 라이선스 미표기 → 코드 반입 금지.

## 재사용 메모
- 내 판단: "수신 DMA/원형 버퍼 + 완료 알림 → 태스크가 가변 길이 명령을 파싱"은 FPGA UART RX FIFO IP의 레지스터 모델(RX_COUNT, 임계 인터럽트, 라인 종료 감지)과 직접 대응한다.
- 개조: 옮길 부분은 FIFO·임계값 인터럽트 설계와 "ISR은 알리기만, 파싱은 태스크" 분리. 못 옮길 부분은 DMA 컨트롤러와 FreeRTOS 스트림 버퍼 API 자체.
- 같은 주제 FPGA 쪽 비교: [[stm32-community-hal-vs-ll]].
