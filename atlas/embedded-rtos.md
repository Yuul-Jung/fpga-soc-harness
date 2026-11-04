# 임베디드 RTOS 비교 (FreeRTOS · Zephyr · ThreadX)

갱신: 2026-11-04 (/verify 8차). 카드 3건 기준 (beningo-freertos-to-zephyr-migration, ezurio-freertos-vs-zephyr-benchmark, freertos-org-faq-memory). 8차: beningo·ezurio·promwad 3건 재사용 메모에 라이선스 확인 필요 고지 추가(unknown 라이선스 경고 해소).

---

## 비교표

| 항목 | 카드 | RTOS | 플랫폼 | 핵심 수치/특성 | 한계 |
|---|---|---|---|---|---|
| 메모리 풋프린트 | freertos-org-faq-memory | FreeRTOS | 범용 | 스케줄러 236B, 태스크 64B, ROM 5~10KB | Heap 구현 선택(heap_1~5)에 따라 증가 |
| 협력형 컨텍스트 전환 | ezurio-freertos-vs-zephyr-benchmark | FreeRTOS | STM32F4 168MHz | 223 사이클 (Zephyr 524 대비 2.3× 빠름) | 협력형에 한정; 선점형 미측정 |
| 협력형 컨텍스트 전환 | ezurio-freertos-vs-zephyr-benchmark | Zephyr | STM32F4 168MHz | 524 사이클 | 협력형 단일 태스크 한정 |
| 뮤텍스 오버헤드 | ezurio-freertos-vs-zephyr-benchmark | FreeRTOS | STM32F4 168MHz | 1964 사이클 (Zephyr 969 대비 2× 느림) | 우선순위 상속 없음 항목에서 역전 |
| 뮤텍스 오버헤드 | ezurio-freertos-vs-zephyr-benchmark | Zephyr | STM32F4 168MHz | 969 사이클 | 뮤텍스 항목에서 FreeRTOS보다 2× 빠름 |
| API 이식성 | beningo-freertos-to-zephyr-migration | FreeRTOS→Zephyr | 범용 | xTaskCreate → k_thread_create, xSemaphoreGive → k_sem_give 등 1:1 대응 | ISR 포팅 함정: portYIELD_FROM_ISR 에 해당하는 Zephyr 패턴이 다름 |

---

## 패턴

### P1: "항목별 역전" 패턴

내 판단: RTOS 선택은 작업 유형에 따라 역전된다. 협력형 단일 전환에서는 FreeRTOS가 빠르고, 뮤텍스(우선순위 상속)에서는 Zephyr가 빠르다. MicroBlaze V + AXI INTC 환경에서 ISR 반응성이 중요하면 협력형 전환 사이클을 기준으로 선택하되, 뮤텍스를 많이 쓰는 구조라면 Zephyr도 고려할 수 있다. 근거: ezurio-freertos-vs-zephyr-benchmark.

### P2: 최소 메모리 패키지

내 판단: Basys3 XC7A35T의 BRAM 한계(1,800Kb)에서 소프트 CPU 위 RTOS를 올리려면 스케줄러·태스크 메모리 풋프린트를 먼저 추정해야 한다. FreeRTOS는 스케줄러 236B + 태스크당 64B + 스택으로, 태스크 4개 + 스택 2KB×4 = 약 9KB TCB. BRAM 1블록(36Kb=4KB) 하나에 들어가는 수준. 근거: freertos-org-faq-memory.

### P3: FreeRTOS → Zephyr 이식 경로

내 판단: 기존 FreeRTOS C 코드가 있을 때, beningo 카드의 API 대응표가 직접 이식 근거가 된다. ISR 포팅 함정(portYIELD_FROM_ISR vs Zephyr 패턴)을 카드에 명시해 두어 버그를 사전에 차단할 수 있다. MicroBlaze V의 경우 Vitis FreeRTOS BSP → Zephyr는 비공식이므로 현재는 FreeRTOS 경로 권장. 근거: beningo-freertos-to-zephyr-migration.

---

## 교훈

1. **단일 벤치마크로 RTOS를 단정하지 않는다**: 협력형 전환에서 FreeRTOS가 Zephyr의 2배 빠르지만, 뮤텍스에서는 역전된다. 측정 항목을 명시하지 않은 성능 비교는 그대로 쓸 수 없다.
2. **MicroBlaze V에서 FreeRTOS는 Vitis BSP 경로로 검증됨**: Zephyr는 공식 BSP 없음; ThreadX는 Vitis BSP 지원 여부 미확인(I-063 dropped 사유).
3. **메모리 계획 먼저**: RTL에 FreeRTOS를 붙이기 전에 태스크 수·스택 크기로 TCB 메모리를 추정하고 BRAM 슬롯을 배정한다.

---

## 관련 카드

- [beningo-freertos-to-zephyr-migration](../catalog/embedded/beningo-freertos-to-zephyr-migration.md)
- [ezurio-freertos-vs-zephyr-benchmark](../catalog/embedded/ezurio-freertos-vs-zephyr-benchmark.md)
- [freertos-org-faq-memory](../catalog/embedded/freertos-org-faq-memory.md)

## 관련 아이디어

- I-061: MicroBlaze V + FreeRTOS + AXI INTC 최소 인터럽트 예제 (vetted, 6점)
- I-062: FreeRTOS vs Zephyr 컨텍스트 전환 오버헤드 비교 측정 카드 (vetted, 6점)
- I-063: ThreadX 결정론적 인터럽트 패턴 (dropped, 4점 — Vitis BSP 지원 미확인)
