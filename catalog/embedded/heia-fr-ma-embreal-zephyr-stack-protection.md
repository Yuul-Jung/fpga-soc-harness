---
name: heia-fr-ma-embreal-zephyr-stack-protection
url: https://embreal.isc.heia-fr.ch/codelabs/robust-patterns-part4/
source_type: course
vendor: neutral
board: [nRF5340dk]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M33 대상)
language: C
tools: [Zephyr RTOS, west, GCC ARM, Kconfig]
bus: none
peripherals: []
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://embreal.isc.heia-fr.ch/codelabs/robust-patterns-part4/]
---

## 요약

HEIA-FR(스위스 프리부르 응용과학대학) 임베디드 실습(ma_embreal) 시리즈의 4부.
ARM Cortex-M33(nRF5340dk) + Zephyr RTOS 환경에서 스택 오버플로를 의도적으로 발생시키고,
소프트웨어·하드웨어 4가지 보호 계층이 각각 어떻게 감지하는지 단계적으로 실습한다.

## 구조

### 4가지 스택 보호 계층 (난이도 순)

| 계층 | 메커니즘 | Kconfig 플래그 | 설명 |
|------|---------|----------------|------|
| 1 | 소프트웨어 센티넬 | `CONFIG_STACK_SENTINEL=y` | 스택 맨 아래에 매직 값 기록, 주기적 검사; Cortex-M 비필수 |
| 2 | ARMv8-M 프로세서 한계 레지스터 | `CONFIG_HW_STACK_PROTECTION=y` (부분) | PSPLIM 레지스터로 스택 포인터 하한 하드웨어 감시 |
| 3 | MPU 가드 영역 | `CONFIG_HW_STACK_PROTECTION=y` | 스택 하단에 MPU로 보호된 가드 페이지 설정; 접근 시 MemManage Fault |
| 4 | 스레드 워터마크 분석기 | `CONFIG_INIT_STACKS=y` + `CONFIG_THREAD_ANALYZER=y` | 스택 초기화 시 패턴으로 채우고 최대 사용량을 주기적 출력 |

### 실습 구조
- `stackOverflow()` 함수를 명시적으로 호출해 오버플로 유발
- 각 보호 계층을 한 번에 하나씩 활성화해 반응 비교
- `StackChecker` C++ 클래스: 저우선순위 스레드, 60초마다 각 스레드의 스택 워터마크 로그
- C++ 래퍼 `zpp_lib` 사용 (Zephyr 위의 얇은 C++ 추상화)
- 빌드: `west build -b nrf5340dk_nrf5340_cpuapp . --pristine`
- GitHub 저장소: `heia-fr/ma_embreal` (직접 열람은 PROVENANCE_REQUIRED로 차단됨)

### 연관 시리즈
- Part 1·3: 워치독 타이머 패턴 (별도 파트)
- Part 2: 사용자 공간 격리

## 검증·재현성

- Codelab 페이지 직접 열람 (L3). GitHub 저장소(`heia-fr/ma_embreal`)는 PROVENANCE_REQUIRED로 열람 불가 (L2 미달, unverified: 프록시 차단).
- nRF5340dk + west 환경 필요; Basys3에서는 직접 실행 불가.
- Kconfig 플래그와 Zephyr 빌드 절차는 codelab에 단계별로 명시됨.

## 한계·위험

- ARM Cortex-M33 전용 보호 계층(PSPLIM, MPU)은 MicroBlaze V에 없음.
- STACK_SENTINEL은 소프트웨어 패턴 검사이므로 패턴이 덮어 쓰인 뒤 검사 전에 충돌할 수 있음.
- 워터마크 분석기는 사후 진단 도구이며 실시간 보호가 아님.
- GitHub 저장소 라이선스 불명 (열람 차단으로 미확인): 코드 복사 전 라이선스 확인 필요.

## 재사용 메모

- 임베디드 안전 교육 자료로 활용 가능: Zephyr/MCU 스택 보호 4계층 개념은 FPGA SoC 메모리 보호 설계에 직접 대응됨.
- `개조:` MicroBlaze V에는 PSPLIM/MPU가 없으나, AXI4-Lite 슬레이브 IP로 "소프트웨어 스택 감시 IP"를 구현 가능. 예: 스택 포인터를 주기적으로 읽어 하한과 비교하는 하드웨어 감시 블록, 임계치 위반 시 인터럽트 발생. STACK_SENTINEL 개념(매직 값 체크)은 MicroBlaze V 펌웨어에 소프트웨어로 그대로 적용 가능. 옮길 수 없는 것: ARMv8-M PSPLIM 레지스터 직접 사용, Zephyr-specific Kconfig 플래그 (대신 FreeRTOS/MicroBlaze V 동등 메커니즘 필요).
