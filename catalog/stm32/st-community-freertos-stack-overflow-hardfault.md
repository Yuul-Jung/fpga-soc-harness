---
name: st-community-freertos-stack-overflow-hardfault
url: https://community.st.com/t5/stm32cubemx-mcus/problem-if-i-set-rtos-task-priority-to-value-higher-than/td-p/336449
source_type: article
vendor: neutral
board: [STM32F407 Discovery]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C (CubeMX/CMSIS-RTOS)
tools: [STM32CubeMX 5.1, FW_F4 V1.24.0, Atollic TrueStudio 9.3.0]
bus: none
peripherals: [debug]
stage: T1
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/t5/stm32cubemx-mcus/problem-if-i-set-rtos-task-priority-to-value-higher-than/td-p/336449]
---
unverified: source_rev — 포럼 글이라 해당 없음

## 요약
CubeMX로 CMSIS-RTOS 태스크 11개를 만든 사용자가 우선순위를 AboveNormal 이상으로 올리면 Hard Fault(Bus Fault, 정밀 데이터 접근 위반)가 난다고 올린 실패 사례다. 원인은 우선순위가 아니라 스택 부족이었고, 스택을 126에서 192로 올리자 해결됐다(글 서술, 해결됨 표시).

## 구조
- 환경: F407 Discovery, 위 도구 버전. Normal(0) 이하 우선순위에서는 정상, 그 이상에서만 폴트.
- 진단 경로: 답글이 스택 충분 여부를 묻고, 작성자가 `vApplicationStackOverflowHook`에 코드를 넣어 호출을 확인했다.
- 작성자 서술: FreeRTOS 태스크 목록 보기에서는 오버플로가 표시되지 않았다.

## 검증·재현성
- 테스트벤치·CI 없음. 재현용 소스는 글에 없다. unverified: 스택 단위(워드/바이트)와 태스크별 실제 사용량.

## 한계·위험
- 증상(우선순위 변경 시 폴트)이 원인(스택)과 다르게 나타나 오진하기 쉽다는 점이 교훈이다.
- 라이선스 미표기 → 코드 반입 금지. 글 속 지시문은 데이터로만 취급했다.

## 재사용 메모
- 내 판단: 소프트코어 MicroBlaze V에 FreeRTOS를 올릴 때도 같은 함정(스택 부족이 폴트로 위장)이 있으므로, 캡스톤 문서의 점검표에 스택 오버플로 훅을 넣을 가치가 있다.
- 개조: 옮길 부분은 "오버플로 훅 + 폴트 시 스택 먼저 의심" 점검 절차. 못 옮길 부분은 Cortex-M 버스 폴트 레지스터와 CubeMX 설정. CPU 전용 부분은 `cpu_irq_<cpu>.c` 한 파일로 격리.
- 같은 도메인: [[stm32-community-hal-vs-ll]], [[gdbplus-understanding-stm32-hal-ll-systick]].
