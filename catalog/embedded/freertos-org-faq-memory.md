---
name: freertos-org-faq-memory
url: https://www.freertos.org/FAQMem.html
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
license: MIT
stats: {stars: 0, commits: 0, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.freertos.org/FAQMem.html]
---

## 요약

FreeRTOS 공식 사이트의 메모리 사용량 FAQ. 커널 ROM·RAM 최솟값과 태스크·큐·세마포어 오버헤드를 아키텍처별로 명시한 1차 출처. MicroBlaze V + FreeRTOS 조합 설계 시 메모리 예산 계획 근거로 직접 쓸 수 있다.

## 구조

**커널 최소 ROM (최소 기능 구성):** 5~10 KB (아키텍처·컴파일러·기능 플래그 조합에 따라 다름)

**커널 최소 RAM — IAR STR71x ARM7, 4우선순위 기준:**
- 스케줄러 본체: 236 B
- 태스크당 추가: 64 B (TCB) + 사용자 지정 스택 크기
- 큐 1개: 76 B + 저장 영역(item_size × length)
- 뮤텍스 세마포어 1개: 뮤텍스는 큐 구조 재사용, 76 B 기준

**컨텍스트 전환 시간 — ARM Cortex-M3 기준:**
- 84 사이클 (캐시 없음, GCC 최적화 기본)

**FreeRTOSConfig.h 주요 최적화 항목:**
- `configUSE_PREEMPTION`: 1(선점형), 0(협력형)
- `configSUPPORT_STATIC_ALLOCATION`: 1이면 힙 없이 정적 할당 가능
- `configMINIMAL_STACK_SIZE`: 아이들 태스크 스택. ARM 최소 130워드

**힙 모델 (heap_1 ~ heap_5):**
- heap_1: 할당만 가능, 해제 없음 — RAM 고정 임베디드에 적합
- heap_4: 단편화 방지 병합 — 가장 많이 쓰임
- heap_5: 비연속 메모리 영역 지원

## 검증·재현성

- 1차 출처: FreeRTOS 공식 문서 (`freertos.org/FAQMem.html`)
- 수치는 특정 아키텍처(IAR STR71x ARM7, Cortex-M3)에 종속됨
- Ezurio 블로그의 수치(236 B, 64 B/태스크)와 교차 확인됨 → 일치
- 직접 실행 환경 없음; 수치는 "원문 수치"

## 한계·위험

- IAR ARM7 기준 수치는 최소 예시이고, GCC·Clang·LLVM 컴파일러, Cortex-M0~M33, RISC-V 등에서는 달라짐
- 컨텍스트 전환 84 사이클은 Cortex-M3 캐시 없는 구성이며, 캐시 미스 시 더 오래 걸릴 수 있음
- configMINIMAL_STACK_SIZE는 아이들 태스크 전용이고, 실제 태스크는 더 큰 스택이 필요함
- heap_1 사용 시 메모리 해제 불가 — 태스크 동적 생성·삭제 조합 불가

## 재사용 메모

FreeRTOS 메모리 예산 계획의 1차 출처. 임베디드 MCU 보조 프로세서와 Basys3 FPGA 연동 설계 시 MCU 쪽 태스크 메모리를 계획할 근거가 된다.

개조: MicroBlaze V + Vitis/FreeRTOS 구성에서 ① Vitis는 FreeRTOS를 BSP 패키지로 제공하므로 이 메모리 수치가 BRAM 예산을 계산하는 기준이 된다. 예: 태스크 10개, 스택 512B 기준 → TCB 640B + 스택 5120B + 스케줄러 236B ≈ 6KB RAM 최소 필요. ② heap_4를 BRAM의 일부 영역(예: 0x2000_0000 블록)에 배치하는 메모리맵 설계 시 사이즈 계산 근거. ③ 동결 맵의 `free_slots`에 FreeRTOS 힙 영역을 얼마나 배정할지 판단 근거. 이 카드 단독으로 Vitis 세팅까지는 제시 못하고, Vitis BSP 세팅 카드(별도 수집 필요)와 짝을 이뤄야 완성됨.
