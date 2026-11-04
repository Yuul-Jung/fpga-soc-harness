---
name: promwad-rtos-freertos-zephyr-threadx-comparison
url: https://promwad.com/news/choosing-rtos-freertos-zephyr-threadx-comparison
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://promwad.com/news/choosing-rtos-freertos-zephyr-threadx-comparison]
---

## 요약 (3줄 이내, 내 표현으로)

Promwad의 IoT 디바이스용 RTOS 선택 가이드. FreeRTOS·Zephyr·ThreadX·기타를 비교 표로 제시한다. 비교 항목은 메모리 풋프린트, SMP 지원, 라이선스, 하드웨어 지원 등이다.

## 구조

검색 요약 기준 (본문 일부 열람):

| 항목 | FreeRTOS | Zephyr | ThreadX (Azure RTOS) |
|---|---|---|---|
| 메모리 풋프린트 | Very Low | Low | Moderate |
| SMP 지원 | 없음 | 있음 | 있음 |
| 실시간 | 있음 | 있음 | 있음(결정적 성능, 우선순위 역전 방지) |
| 하드웨어 지원 | Excellent | 600+ 보드(Broad) | Moderate |
| 라이선스 | MIT | Apache 2.0 | "Proprietary/MIT" (표 기재; 본문은 "permissive" 서술) |

- ThreadX: 우선순위 기반 선점형 스케줄러, 빠른 인터럽트 응답, 스레드 간 통신·동기화 지원
- Zephyr: Linux Foundation 관리, Intel/Nordic/NXP/SiFive/Synopsys/TI 등 기여

## 검증·재현성

unverified: 본문 전체를 열람하지 못함 (WebFetch 부분 열람). 비교 표 수치는 promwad 기사 요약 기준(검색 요약 + 부분 열람). 실측 수치 없음.

## 한계·위험

- ThreadX 라이선스: 표와 본문이 "Proprietary/MIT"와 "permissive"로 혼재. 직접 확인 필요.
- 구체적 태스크 오버헤드, 타이밍 측정값 없음
- ThreadX는 2023년 이후 Eclipse Foundation으로 이전(Azure RTOS → Eclipse ThreadX). 이 기사가 최신 상태를 반영하는지 미확인.

## 재사용 메모

- 내 판단: ThreadX의 "결정적 성능"과 SMP 지원은 멀티코어 FPGA SoC 설계에서 소프트웨어 모델 참고용. RTOS 선택 기준을 AXI 주변장치 드라이버 설계에 적용할 때, 태스크 우선순위와 ISR 구조가 핵심임.
- 개조: MCU 펌웨어 도메인이므로 Basys3 RTL 직접 이식 없음. 비교 표의 메모리 풋프린트·SMP 항목은 MicroBlaze V 위 RTOS 선택 시 참고 가능.
- **라이선스 확인 필요**: 출처 라이선스 unknown. 비교 수치는 사실로 인용 가능하나 코드 복사 금지.
