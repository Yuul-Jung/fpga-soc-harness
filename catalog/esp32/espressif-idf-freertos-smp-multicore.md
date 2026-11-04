---
name: espressif-idf-freertos-smp-multicore
url: https://docs.espressif.com/projects/esp-idf/en/release-v5.4/api-reference/system/freertos_idf.html
source_type: article
vendor: neutral
board: [ESP32 (Xtensa LX7 듀얼코어), ESP32-S3]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa LX7)
language: C (ESP-IDF)
tools: [ESP-IDF v5.4]
bus: none
peripherals: [comm-uart]
stage: T2
license: Apache-2.0 (ESP-IDF 소스 코드, 문서 열람만)
stats: {last_update: 2024}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://docs.espressif.com/projects/esp-idf/en/release-v5.4/api-reference/system/freertos_idf.html]
---

## 요약
ESP-IDF v5.4 공식 FreeRTOS SMP 문서. xTaskCreatePinnedToCore로 태스크를 Core0/Core1에 고정하는 방법, 듀얼코어 스핀락, Idle 태스크 구조, FPU 사용 제약을 명시한다.

## 구조
- **코어 고정 API**: `xTaskCreatePinnedToCore(func, name, stackBytes, param, prio, handle, coreID)`. coreID = 0(PRO_CPU), 1(APP_CPU), `tskNO_AFFINITY`.
- **스택 단위**: vanilla FreeRTOS의 워드 단위와 달리 **바이트 단위**다.
- **관례적 역할 분담**: Core0(PRO_CPU)은 Wi-Fi·Bluetooth 프로토콜 처리 전용; Core1(APP_CPU)은 애플리케이션 태스크.
- **스케줄러**: 각 코어가 독립적으로 태스크를 선택한다. 틱 카운트는 Core0만 관리 → Core0 블로킹 시 전체 시간 관리 지연.
- **스핀락**: `portMUX_TYPE` + `taskENTER_CRITICAL(&lock)` / `taskEXIT_CRITICAL(&lock)`. ISR에서는 `_ISR` 접미사 버전. 중단 비활성화만으로 SMP 상호 배제 불가.
- **Idle 태스크**: 각 코어마다 1개씩 생성됨.
- **FPU 제약**: float 사용 태스크는 현재 코어에 자동 고정됨; ISR에서 FPU 사용은 `CONFIG_FREERTOS_FPU_IN_ISR` 옵션 필요.
- **double**: 하드웨어 가속 없음 → 소프트웨어 처리, float보다 CPU 비용 큼.

## 검증·재현성
- 공식 Espressif 문서. 직접 열람(L3). 코드 샘플은 없고 API 계약만 명시함.
- unverified: 실제 타이밍 측정, 실제 커밋 SHA.

## 한계·위험
- 같은 우선순위 태스크 간 라운드로빈은 "best effort" — 완전한 라운드로빈이 필요하면 같은 코어에 고정해야 함.
- 다른 코어에서 실행 중인 태스크를 `vTaskDelete()`로 삭제하면 뮤텍스나 메모리 해제가 덜 된 상태일 수 있음 → 본인 삭제(`vTaskDelete(NULL)`) 또는 `vTaskSuspend()` 먼저 권장.
- 중첩 스핀락은 서로 다른 `portMUX_TYPE`을 쓰면 데드락 위험.
- **듀얼코어 한정**: ESP32-S2, C3, C6, H2는 싱글코어라 `coreID=1` 사용 불가.

## 재사용 메모
- 내 판단: Core0=Wi-Fi 전용, Core1=FPGA/UART 데이터 수집으로 나누면 Wi-Fi 지연 없이 실시간 센서 처리 가능. FPGA 측 AXI4-Lite 레지스터를 Core1에서 SPI 슬레이브로 읽고, Core0에서 큐를 거쳐 MQTT 전송하는 구조 (I-038 아이디어 근거).
- 개조: 옮길 부분 — "Core 역할 분담 테이블(Core0=통신, Core1=제어)"이 Basys3 MicroBlaze V IP 설계에서 DMA 채널 우선순위 분리 구조와 대응됨. AXI4-Lite 슬레이브 레지스터에 "CORE1_EXCLUSIVE" 플래그를 두면 Core1 전용 주변장치 격리 모방 가능. 못 옮길 부분 — Xtensa LX7 SMP 코어 아키텍처 자체, `portMUX_TYPE` 스핀락 구현.
