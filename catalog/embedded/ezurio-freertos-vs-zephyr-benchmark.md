---
name: ezurio-freertos-vs-zephyr-benchmark
url: https://www.ezurio.com/resources/blog/freertos-vs-zephyr
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
stats: {stars: 0, commits: 0, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.ezurio.com/resources/blog/freertos-vs-zephyr]
---

## 요약

FreeRTOS와 Zephyr RTOS를 메모리 풋프린트·성능·생태계 관점에서 비교한 Ezurio(제조사) 블로그 글. STM32F4 168 MHz 기준 벤치마크 수치가 포함되어 있어 두 RTOS의 정량 비교 근거로 쓸 수 있다.

## 구조

**FreeRTOS 메모리 (IAR STR71x ARM7, 4우선순위 기준):**
- 스케줄러 RAM: 236 B
- 태스크당 추가: 64 B (TCB) + 스택
- ROM: 5~10 KB (기능에 따라 다름)
- 큐 1개: 76 B + 저장 영역

**Zephyr 메모리 최소값:**
- RAM: 8 KB
- 커널 이미지: 2 KB

**벤치마크 — STM32F4 168 MHz (UL Solutions 2022 기준, 사이클 단위):**

| 항목 | FreeRTOS | Zephyr |
|---|---|---|
| 협력형 컨텍스트 전환 | 223 | 524 |
| 인터럽트 지연 | 101 | 143 |
| 뮤텍스 (태스크 블록) | 1,964 | 969 |
| 큐 수신 (블록) | 1,660 | 710 |

**라이선스:**
- FreeRTOS: MIT (AWS FreeRTOS) — 최신 버전 완전 MIT
- Zephyr: Apache 2.0 (Linux Foundation 프로젝트)

**생태계:**
- FreeRTOS: 단순 커널, MCU 벤더(ST·NXP·Espressif 등)가 SDK에 포함
- Zephyr: 600+ 보드 지원, devicetree + Kconfig 빌드 시스템, POSIX 일부 지원

## 검증·재현성

- 출처: Ezurio 엔지니어링 블로그 (임베디드 모듈 제조사), 2024년 경 작성
- 벤치마크 수치는 "UL Solutions, 2022" 인용. 직접 측정값이 아닌 인용 수치
- 메모리 수치는 FreeRTOS 공식 FAQ(`freertos.org/FAQMem.html`)와 교차 확인됨 → 일치
- 직접 실행 환경 없음; 수치는 원문에서 가져온 것으로 "원문 수치"임을 명시

## 한계·위험

- 벤치마크가 STM32F4(Cortex-M4, 168 MHz) 기준이므로 다른 MCU에서 그대로 적용 금지
- 뮤텍스·큐 수치가 뒤집힘(FreeRTOS > Zephyr): 작업 복잡도와 커널 최적화 차이로 항목마다 결과가 다름. 단순히 "FreeRTOS가 빠르다"로 단정 불가
- Zephyr 메모리 최소값(8 KB RAM, 2 KB 커널)은 HAL·드라이버 없는 최소 구성 기준
- ThreadX(Eclipse) 비교 수치는 이 출처에 없음 — 별도 출처 필요

## 재사용 메모

FreeRTOS와 Zephyr 두 RTOS의 정량적 비교 근거로 임베디드 공통 카드로서 가치가 높다. SoC 주변장치 드라이버 계층을 설계할 때 인터럽트 지연(ISR 반응성)과 컨텍스트 전환 오버헤드가 설계 제약이 되므로, 이 수치가 타이밍 여유를 계산하는 기준이 된다.

개조: Basys3·MicroBlaze V SoC 관점에서 직접 이식하는 항목은 없다(MCU 전용 RTOS). 그러나 ① AXI 슬레이브 IP의 인터럽트 서비스 루틴 지연을 얼마나 허용할지 결정할 때 Cortex-M 벤치마크가 하한 참고값이 된다. ② MicroBlaze V + FreeRTOS 조합(Vitis에서 지원)의 태스크 오버헤드를 추정할 기준으로 쓸 수 있다. ③ 사용자 MCU 보조 프로세서(STM32/ESP32)와 Basys3 FPGA 간 협력형 설계 시 MCU 쪽 RTOS 선택 근거로 직접 활용.
- **라이선스 확인 필요**: 출처 라이선스 unknown. 벤치마크 수치는 사실로 인용 가능하나 코드 복사 금지.
