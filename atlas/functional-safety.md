# 기능 안전 (Functional Safety) — FPGA SoC 구현 사례 및 개조 경로

갱신: 2026-11-04 (/verify 6차). 카드 3건 기준.

---

## 개요

기능 안전(Functional Safety) 패턴은 MCU·RTOS 환경에서 주로 구현되며, IEC 61508 Class B 수준의 하드웨어/소프트웨어 중복 보호를 목표로 한다. 이 문서는 카탈로그에서 수집한 안전 관련 카드를 정리하고, MicroBlaze V + Basys3 환경에서 AXI4-Lite IP로 이식하는 경로를 기록한다.

---

## 카드 목록

| 카드 | 도메인 | 보드/플랫폼 | 언어 | 단계 | 등급 | 주요 기능 |
|---|---|---|---|---|---|---|
| rtime-cvut-openmsp430-watchdog | embedded | openMSP430 SoC | Verilog | T1 | L3 | 워치독 타이머 FSM, 패스워드 보호, NMI |
| heia-fr-ma-embreal-zephyr-stack-protection | embedded | nRF5340dk (ARM Cortex-M33) | C/Zephyr | T0 | L3 | 스택 보호 4계층, 소프트 센티넬, MPU 가드 |
| tum-industrial-es-2015-functional-safety | papers | 없음(강의 자료) | 없음 | T0 | L3 | IEC 61508 개념, FMEA/FMEDA, CRC 검사 |

---

## 주요 패턴과 MicroBlaze V 개조 경로

### 1. 워치독 타이머 (Watchdog Timer, WDT)

**근거 카드**: [[rtime-cvut-openmsp430-watchdog]]

openMSP430의 `omsp_watchdog.v`는 단일 Verilog 파일(약 250줄)로, 아래 핵심 패턴을 보여 준다:
- 패스워드 보호 쓰기(`WDTPW = 0x5A`): 상위 바이트 불일치 시 `wdtpw_error` 신호
- 카운터 비트-탭 타임아웃 선택(2비트 WDTIS → 비트 15/13/9/6 선택)
- KICK(`WDTCNTCL` 비트 쓰기) → 카운터 리셋
- NMI 감지 경로(3단계 동기화기 + 에지 감지)

**개조 경로**: MSP430 주변 버스(`per_addr`/`per_din`)를 AXI4-Lite `S_AXI_*` 포트로 교체. 타임아웃 비트-탭 선택은 AXI 레지스터의 `TIMEOUT_SEL` 필드로 직접 이식. `wdtifg_set` → MicroBlaze V AXI INTC 연결. `free_slots` 중 하나에 64KB 배정 필요. 단일 클럭 도메인으로 단순화(MSP430의 `aclk_en`/`smclk_en` 체계 불필요).

**내 판단**: 비트-탭 WDT는 LUT 소모 최소(< 100 LUT 추정). I-070 1단계(기본 WDT) 캡스톤의 직접 근거.

### 2. 스택 보호 (Stack Protection)

**근거 카드**: [[heia-fr-ma-embreal-zephyr-stack-protection]], [[tum-industrial-es-2015-functional-safety]]

Zephyr의 4계층 스택 보호 접근법:

| 계층 | 메커니즘 | Zephyr Kconfig | Basys3 대응 |
|---|---|---|---|
| 소프트웨어 센티넬 | 스택 하단 매직 값 + 주기적 체크 | `CONFIG_STACK_SENTINEL=y` | MicroBlaze V C 코드로 그대로 적용 가능 |
| 프로세서 한계 레지스터 | PSPLIM(ARMv8-M) | `CONFIG_HW_STACK_PROTECTION=y` | MicroBlaze V에 없음; AXI 감시 IP로 대체 가능 |
| MPU 가드 영역 | 스택 하단 보호 페이지 | `CONFIG_HW_STACK_PROTECTION=y` | MPU 없음; 소프트웨어 한계 비교로 부분 대체 |
| 워터마크 분석기 | 패턴 채우기 + 사용량 로그 | `CONFIG_THREAD_ANALYZER=y` | 사후 진단; FreeRTOS `uxTaskGetStackHighWaterMark()` 대응 |

**개조 경로**: MicroBlaze V에서 소프트웨어 센티넬(계층 1)은 C 코드로 직접 이식 가능. 하드웨어 감시가 필요하면 AXI4-Lite IP로 스택 포인터 주기 감시 블록을 추가하고, 임계치 위반 시 인터럽트 발생. I-071 캡스톤의 근거.

### 3. CRC 메모리 무결성 검사

**근거 카드**: [[tum-industrial-es-2015-functional-safety]]

TUM 강의는 IEC 61508 Class B의 CRC 검사 개념을 설명한다:
- 모듈로-2 다항식(CRC16/CRC32): 단일 비트 오류 100% 감지, 버스트 오류(CRC 길이 이하) 100%
- 주기적 CRC 재계산 → 기준값 비교 → 불일치 시 인터럽트/리셋

**개조 경로**: MicroBlaze V + Basys3에서 BRAM 명령 메모리 내용의 CRC를 주기적으로 계산하는 AXI4-Lite CRC 검사 IP 구현 가능. CRC FSM은 LUT 소모 최소(< 200 LUT 추정). I-071 캡스톤의 근거.

---

## gap 목록 (내 판단)

- gap: Basys3 MicroBlaze V에 연결된 AXI4-Lite 워치독 IP 카드 없음. openMSP430 WDT(T1 개조 경로 있음). I-070(vetted, 7점)이 근거.
- gap: 스택 센티넬 소프트웨어 패턴을 MicroBlaze V C 코드로 구현하고 AXI GPIO로 경보를 출력하는 완성 카드 없음. I-071(vetted, 5점)이 근거.
- gap: Basys3 BRAM 명령 메모리 CRC 검사 AXI IP 카드 없음.
- gap: 윈도우 WDT(Window Watchdog Timer, WWDT) FPGA Verilog 카드 없음; openMSP430은 기본 WDT만 구현.
- gap: IEC 61508 FMEA/FMEDA 절차를 적용한 Basys3 SoC 캡스톤 없음(TUM 강의 자료는 개념만).

---

## 관련 카드와 아이디어

- 근거 카드: [[espressif-idf-watchdog-timers]] (T1, ESP32 WDT → AXI4-Lite WDT 개조 경로)
- 아이디어: I-070(AXI4-Lite WDT 사다리, vetted 7점), I-071(CRC+스택 센티넬, vetted 5점)
- 연관 atlas: [[atlas/embedded-rtos.md]] (FreeRTOS·Zephyr 비교)
