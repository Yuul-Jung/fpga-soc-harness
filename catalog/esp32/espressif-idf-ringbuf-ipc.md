---
name: espressif-idf-ringbuf-ipc
url: https://docs.espressif.com/projects/esp-idf/en/v4.4/esp32/api-reference/system/freertos_additions.html
source_type: article
vendor: neutral
board: [ESP32 (Xtensa LX7 듀얼코어)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa LX7)
language: C (ESP-IDF)
tools: [ESP-IDF v4.4]
bus: none
peripherals: [comm-uart]
stage: T2
license: Apache-2.0 (ESP-IDF 소스, 문서 열람만)
stats: {last_update: 2022}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://docs.espressif.com/projects/esp-idf/en/v4.4/esp32/api-reference/system/freertos_additions.html, https://docs.espressif.com/projects/esp-idf/en/release-v3.0/api-reference/system/ipc.html]
---

## 요약
ESP-IDF의 FreeRTOS 확장 기능 두 가지를 직접 열람. ① Ring Buffer: 가변 크기 항목 FIFO로 코어 간 데이터 교환에 사용. ② IPC(Inter-Processor Call): 특정 코어에서 함수를 실행시키는 고우선순위 태스크 메커니즘.

## 구조

### Ring Buffer
- **타입 3가지**: No-Split(연속 메모리, 직접 접근), Allow-Split(감쌈 허용, 메모리 효율), Byte Buffer(스트림, 헤더 없음).
- **항목 헤더**: No-Split/Allow-Split은 항목당 8바이트 헤더 + 32비트 정렬 올림.
- **주요 API**:
  - `xRingbufferCreate(size, type)` → 핸들
  - `xRingbufferSend(handle, data, size, ticksToWait)` / `xRingbufferSendFromISR()`
  - `xRingbufferReceive(handle, itemSize, ticksToWait)` → 포인터(반드시 반환 필요)
  - `vRingbufferReturnItem(handle, item)` — 미반환 시 공간 미해제
  - `xRingbufferReceiveSplit()` (Allow-Split 전용), `xRingbufferReceiveUpTo()` (Byte Buffer 전용)
- **No-Split 최대 항목 크기**: `(buffer_size / 2) - 헤더_크기`.
- **스레드 안전성**: `xRingbufferGetCurFreeSize()`는 비원자 → 호출자가 보호 필요.

### IPC (Inter-Processor Call)
- **구조**: 각 코어에 고정된 고우선순위 IPC 태스크가 블록 대기 중. 호출하면 해당 코어에서 선점적으로 실행됨.
- **API**:
  - `esp_ipc_call(cpu_id, func, arg)` — 함수 실행 **시작**까지 호출자 블록
  - `esp_ipc_call_blocking(cpu_id, func, arg)` — 함수 실행 **완료**까지 호출자 블록
- **IPC 태스크 스택**: 기본값 제한. 스택 소비 큰 함수는 `menuconfig IPC_TASK_STACK_SIZE` 증가 필요.
- **동시 호출 불가**: 뮤텍스 보호 → 여러 IPC 호출은 순차 실행.

## 검증·재현성
- Espressif 공식 문서 직접 열람(L3). 두 출처 모두 직접 읽음.
- unverified: 실제 커밋 SHA, 각 버전 간 API 변경 사항.

## 한계·위험
- **반환 순서 필수**: Ring Buffer 수신 항목은 FIFO 순으로 반환해야 함 — 먼저 받은 것을 반환하지 않으면 뒤 항목 공간도 미해제.
- **IPC 데드락 위험**: IPC 함수 내에서 뮤텍스 획득 시 데드락 위험(문서 경고).
- **싱글코어 모드에서 IPC**: `cpu_id=1` → `ESP_ERR_INVALID_ARG`.
- **우선순위 역전**: 특정 조건(태스크 수 적음, 버퍼 용량 한계 근접)에서 세마포어 구현으로 인해 발생 가능.

## 재사용 메모
- 내 판단: Ring Buffer의 가변 크기 FIFO 구조는 MicroBlaze V AXI4-Stream 인터페이스 설계(TLAST 패킷 경계, 가변 길이 프레임)와 직접 대응됨. No-Split 타입의 "공간 먼저 확보 후 직접 채우기(`SendAcquire/Complete`)" 패턴은 DMA 더블 버퍼 구조를 소프트웨어로 모방.
- 개조: 옮길 부분 — Ring Buffer의 "No-Split/Allow-Split/Byte" 타입 선택 기준이 AXI4-Stream TUSER 패킷 모드 대 스트리밍 모드 선택 기준과 같은 맥락임; FIFO 깊이·항목 크기 계산 방법을 AXI4-Stream FIFO IP 파라미터에 적용 가능. IPC의 "고우선순위 태스크가 대상 코어에서 선점 실행" 패턴은 MicroBlaze V 소프트 인터럽트(SWI)와 대응됨. 못 옮길 부분 — Xtensa 듀얼코어 하드웨어 메커니즘 자체, `esp_ipc_call` API.
- 라이선스 확인 필요: 문서 읽기만; 소스 코드는 Apache-2.0이나 직접 복사 금지(§16.3).
