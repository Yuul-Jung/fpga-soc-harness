---
name: espressif-idf-watchdog-timers
url: https://docs.espressif.com/projects/esp-idf/en/release-v4.0/api-reference/system/wdts.html
source_type: article
vendor: neutral
board: [ESP32 (듀얼코어 포함 전 계열)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa)
language: C (ESP-IDF)
tools: [ESP-IDF v4.0]
bus: none
peripherals: [debug]
stage: T1
license: Apache-2.0 (ESP-IDF 소스, 문서 열람만)
stats: {last_update: 2020}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://docs.espressif.com/projects/esp-idf/en/release-v4.0/api-reference/system/wdts.html, https://forum.arduino.cc/t/esp32-wdt-triggered/978895]
---

## 요약
ESP-IDF v4.0 Watchdog 공식 문서 + Arduino 포럼 실패 사례. TWDT(Task Watchdog)와 IWDT(Interrupt Watchdog) 구조, 등록·리셋 API, 타임아웃 패닉 흐름을 직접 열람. 포럼 사례는 타이트 루프·스택 오버플로로 TWDT 오류가 발생한 케이스.

## 구조
- **IWDT(Interrupt Watchdog)**: 타이머 그룹 1 HW 워치독 기반. FreeRTOS 태스크 전환 인터럽트 차단 감지. 패닉 핸들러 → 레지스터 덤프. NMI 핸들러 불가 시 하드 리셋.
- **TWDT(Task Watchdog)**: 타이머 그룹 0 HW 워치독 기반. 양보 없는 태스크 실행 감지. 기본적으로 **양쪽 Idle 태스크**(CPU0, CPU1)를 자동 감시.
- **TWDT API 순서**:
  1. `esp_task_wdt_init(timeout_s, panic)` — 초기화 (스케줄러 시작 후만 가능)
  2. `esp_task_wdt_add(task_handle)` — 태스크 등록 (NULL = 현재 태스크)
  3. `esp_task_wdt_reset()` — 주기적 리셋 호출 (등록된 태스크만)
  4. `esp_task_wdt_delete(task_handle)` — 감시 해제
  5. `esp_task_wdt_deinit()` — 전체 해제 (등록 태스크 0건일 때만 성공)
- **타임아웃 동작**: 어떤 태스크가 리셋 못 했는지 경고 출력 → `panic` 플래그에 따라 패닉 핸들러 실행. 사용자 핸들러 `esp_task_wdt_isr_user_handler` 재정의 가능.
- **기본 활성**: `CONFIG_ESP_TASK_WDT` 기본 on. 두 Idle 태스크 자동 등록.

### Arduino 포럼 실패 사례 (S6)
- **원인**: 타이트 for 루프(`for(;;)`) 안에서 서보 직렬 읽기(`SCSerial::readSCS`)가 블로킹; loop()에 코드가 없어 Idle0 태스크가 실행 안 됨.
- **증상**: `EXCVADDR: 0x00000000` → 스택 오버플로 흔적. 스택 1000바이트 할당이 작았음.
- **수정 방향**: 스택 크기 증가(10000바이트 테스트), `uxTaskGetStackHighWaterMark(NULL)`로 피크 측정 후 여유 500~1000바이트 추가, 타이트 루프에 `vTaskDelay(pdMS_TO_TICKS(1))` 추가.

## 검증·재현성
- Espressif 공식 문서 직접 열람(L3). Arduino 포럼 직접 열람(L3).
- unverified: 포럼 사례의 최종 해결 확인 — 작성자의 마지막 출력이 로그 미출력 상태로 끝남.

## 한계·위험
- **JTAG 디버깅 시**: OpenOCD 연결 중 두 HW 워치독 타이머가 비활성화됨 → 디버깅 중 워치독 경고/패닉 발생 안 함. 헷갈림 주의.
- **초기화 시점**: 스케줄러 시작 전 `esp_task_wdt_init()` 호출 → 오류.
- **해제 순서**: 등록 태스크 남은 채 `esp_task_wdt_deinit()` → 실패.
- **Core0 블로킹**: Core0를 오래 점유하면 Wi-Fi 서비스 지연 + TWDT 발동. Core0 태스크는 블로킹 위주로 설계.

## 재사용 메모
- 내 판단: TWDT의 "주기적 리셋 의무(`esp_task_wdt_reset()`)" 패턴은 MicroBlaze V 소프트웨어 워치독 IP 레지스터 설계(`WDT_RESET` 레지스터에 주기적 쓰기)와 직접 대응됨. FPGA 측 하드웨어 워치독(타이머 비교 + 리셋 선) 설계 참고 사례로 활용 가능.
- 개조: 옮길 부분 — "감시 대상 등록 → 주기적 리셋 → 타임아웃 경고" 흐름이 AXI4-Lite 워치독 IP(WDT_EN, WDT_TIMEOUT, WDT_RESET 레지스터)로 그대로 옮겨짐. TWDT가 Idle 태스크를 기본 감시한다는 점에서 "유휴 상태 헬스체크" 레지스터 비트 아이디어 도출 가능. 못 옮길 부분 — 타이머 그룹 HW 블록 자체, Xtensa NMI 핸들러.
- S6 교훈: 타이트 루프·스택 부족 → TWDT 발동; FPGA 테스트벤치에서 타이트 루프 시뮬레이션 항목으로 활용.
- 라이선스 확인 필요: 포럼 코드 조각은 작성자 미표기이므로 반입 금지.
