---
name: iiot-world-freertos-threadx-zephyr-open-source
url: https://iiot-world.com/industrial-iot/connected-industry/freertos-vs-threadx-vs-zephyr-the-fight-for-true-open-source-rtos
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
sources: [https://iiot-world.com/industrial-iot/connected-industry/freertos-vs-threadx-vs-zephyr-the-fight-for-true-open-source-rtos]
---

## 요약 (3줄 이내, 내 표현으로)

IIoT World의 FreeRTOS·ThreadX·Zephyr 오픈소스 라이선스 논쟁 분석 기사. Amazon(FreeRTOS), Microsoft(ThreadX) 인수 이후 라이선스 개방성에 대한 비판과 Zephyr의 Linux Foundation 중립성을 비교한다.

## 구조

검색 요약 기준 (본문 일부 열람):

- **FreeRTOS (Amazon 인수)**: "small memory, low overhead, fast execution"을 강점으로 서술. MIT 라이선스이지만 Amazon이 프로젝트 방향을 통제한다는 비판.
- **ThreadX (Microsoft/Azure RTOS)**: 우선순위 기반 선점형 스케줄러, 빠른 인터럽트 응답, 스레드 통신·동기화. Microsoft가 "라이선스는 개방"이라고 하나 비판론 있음.
- **Zephyr**: Linux Foundation 관리, 중립 거버넌스. 주요 기여사: Intel, Nordic Semiconductor, NXP, SiFive, Synopsys, TI. 2016년 개발 시작.
- 공통: 세 RTOS 모두 넓은 MCU 아키텍처 지원을 주장.

## 검증·재현성

unverified: 본문 전체 열람 미완료 (부분 열람). 메모리 오버헤드, 타이밍 수치 없음. 라이선스 비판 내용은 기사 논조 요약 기준.

## 한계·위험

- 라이선스 비판은 기사 주관적 분석이므로 사실과 판단을 구분해야 함
- ThreadX는 2023년 이후 Eclipse ThreadX로 이전됨 — 이 기사가 최신 상태를 반영하는지 미확인
- 구체적 수치 없음

## 재사용 메모

- 내 판단: Zephyr의 Linux Foundation 중립 거버넌스 모델은 장기 임베디드 프로젝트 의존성 관리에서 고려할 가치가 있음.
- 개조: MCU 펌웨어 도메인이므로 FPGA RTL 직접 이식 없음. 오픈소스 거버넌스 모델은 하드웨어 IP 라이선스 선택(Basys3 프로젝트의 MIT vs Apache 선택)과 비교 가능.
