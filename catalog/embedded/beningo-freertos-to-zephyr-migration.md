---
name: beningo-freertos-to-zephyr-migration
url: https://www.beningo.com/migrating-from-freertos-to-zephyr/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: []
bus: none
peripherals: []
stage: T2
license: unknown
stats: {stars: 0, commits: 0, last_update: 2023-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.beningo.com/migrating-from-freertos-to-zephyr/]
---

## 요약

FreeRTOS에서 Zephyr RTOS로 마이그레이션하는 방법을 API 매핑 테이블과 함께 설명한 Jacob Beningo(임베디드 컨설턴트)의 블로그 글. 태스크·세마포어·큐의 FreeRTOS↔Zephyr API 대응표와 주요 포팅 함정(우선순위 역전, 스택 단위 차이, ISR API 차이)을 명시함.

## 구조

**API 매핑 테이블 (주요 항목):**

| FreeRTOS | Zephyr |
|---|---|
| `xTaskCreate()` | `K_THREAD_DEFINE()` |
| `vTaskDelay()` | `k_msleep()` |
| `xSemaphoreCreateBinary()` | `K_SEM_DEFINE()` |
| `xSemaphoreTake()` | `k_sem_take()` |
| `xSemaphoreGive()` | `k_sem_give()` |
| `xQueueCreate()` | `K_MSGQ_DEFINE()` |
| `xQueueSend()` | `k_msgq_put()` |
| `xQueueReceive()` | `k_msgq_get()` |
| `vTaskSuspend()` | `k_thread_suspend()` |
| `pvTaskGetThreadLocalStoragePointer()` | 없음 (Zephyr 미지원) |

**포팅 함정 3가지:**

1. **우선순위 반전 (Priority Inversion)**
   - FreeRTOS: 숫자 클수록 높은 우선순위 (예: 10 > 5)
   - Zephyr: 숫자 작을수록 높은 우선순위 (예: 0 > 5)
   - 포팅 시 `configMAX_PRIORITIES - 1 - old_priority`로 변환 필요

2. **스택 단위 차이**
   - FreeRTOS: 스택 크기 단위 = 워드 (4B, Cortex-M 기준)
   - Zephyr: 스택 크기 단위 = 바이트
   - 포팅 시 FreeRTOS 스택 × 4 = Zephyr 스택 (Cortex-M 기준)

3. **ISR API 차이**
   - FreeRTOS: `xSemaphoreGiveFromISR()`, `xQueueSendFromISR()` (ISR 전용 함수군 존재)
   - Zephyr: 일반 `k_sem_give()`, `k_msgq_put()`을 ISR에서 그대로 사용 가능. 단, ISR에서 블로킹 대기 불가

**Zephyr 빌드 시스템 (FreeRTOS와 차이점):**
- 프로젝트 설정: `prj.conf` (Kconfig 텍스트 파일), `CMakeLists.txt`
- 하드웨어 추상화: devicetree `.dts/.overlay` 파일에서 보드 하드웨어 선언
- 멀티플랫폼 빌드: `west build -b <board> --` 명령

## 검증·재현성

- 출처: Jacob Beningo 임베디드 컨설팅 블로그 (beningo.com). 저자는 임베디드 소프트웨어 컨설턴트 겸 강사
- API 매핑 테이블은 FreeRTOS 10.x와 Zephyr 3.x 기준으로 추정 (버전 명시 없음)
- 직접 실행 없음; 코드 예시 형태로 제공된 내용을 카드에 포함
- 함정 항목(우선순위, 스택, ISR)은 FreeRTOS·Zephyr 공식 문서에서 교차 확인 가능한 사실

## 한계·위험

- API 매핑이 완전하지 않음; 타이머, 이벤트 그룹, 스트림 버퍼 등 항목은 별도 확인 필요
- `pvTaskGetThreadLocalStoragePointer()` 등 FreeRTOS 전용 기능은 Zephyr에 대응 없음 — 설계 변경 필요
- Zephyr의 devicetree 추상화 계층은 FreeRTOS에 없는 개념이므로 드라이버 계층 완전 재작성이 필요한 경우 있음
- 버전 명시가 없어 특정 FreeRTOS/Zephyr 버전 간 차이 반영 여부 불명확

## 재사용 메모

RTOS 간 포팅 비용을 정량화하는 근거 카드. MCU 보조 프로세서(STM32, ESP32)가 FreeRTOS에서 Zephyr로 전환될 때 얼마나 큰 코드 변경이 필요한지 사전 평가 기준이 된다.

개조: MicroBlaze V SoC 직접 이식 대상은 없다(MCU 전용 RTOS). 그러나 ① AXI 슬레이브 IP 드라이버를 MCU 보조 프로세서에서 구동할 때 FreeRTOS와 Zephyr 중 어느 쪽에서 더 간단하게 쓸 수 있는지 선택 근거가 된다. ② "우선순위 반전" 함정은 MicroBlaze V + FreeRTOS 조합에서도 동일하게 발생 — Vitis에서 태스크 우선순위 설정 시 주의 사항으로 메모 필요. ③ ISR에서 세마포어 give/큐 send 패턴은 AXI 인터럽트 핸들러(ISR) → FreeRTOS 태스크 통지 패턴에 그대로 적용됨. MicroBlaze V XPS 인터럽트 핸들러에서 `xSemaphoreGiveFromISR()` 호출하는 패턴 설계에 활용.
- **라이선스 확인 필요**: 블로그 글 라이선스 미명시(unknown). 코드 스니펫을 직접 복사하기 전에 라이선스를 확인한다. 패턴·개념 참고만 허용.
