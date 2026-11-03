---
name: espressif-idf-gatt-server-walkthrough
url: https://github.com/espressif/esp-idf/blob/v3.1.5/examples/bluetooth/gatt_server/tutorial/Gatt_Server_Example_Walkthrough.md
source_type: article
vendor: neutral
board: [ESP32-DevKitC]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: [ESP-IDF 3.x, Bluedroid BLE stack]
bus: GATT (ATT over BLE)
peripherals: [BLE-GATT-server]
stage: T2
license: Apache-2.0
stats: {stars: N/A, commits: N/A, last_update: 2018}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://github.com/espressif/esp-idf/blob/v3.1.5/examples/bluetooth/gatt_server/tutorial/Gatt_Server_Example_Walkthrough.md]
---

unverified: source_rev — v3.1.5 태그 기준이나 커밋 SHA 미확인

## 요약 (3줄 이내)

Espressif 공식 ESP-IDF v3.1.5의 BLE GATT 서버 구현 단계별 해설 문서. 두 개의 Application Profile을 Bluedroid 스택 위에 구축하고, 광고·연결·읽기·쓰기·CCCD(notify/indicate) 흐름을 이벤트 콜백 순서로 설명한다. ESP32 BLE 주변장치 IP 설계의 개념적 기준으로 활용 가능하다.

## 구조

- **Application Profile 배열**: 클라이언트 앱별로 독립된 `gatts_profile_inst` 구조체를 배열(`profile_tab[]`)에 저장하고, `gatts_if`로 이벤트를 분기한다.
- **각 프로파일 구성**: Service 1개(16비트 UUID, 핸들 4개) + Characteristic 1개(Properties: READ/WRITE/NOTIFY) + CCCD 1개.
- **초기화 순서**: NVS → BT 컨트롤러 → Bluedroid 스택 → GAP/GATTS 콜백 등록 → `esp_ble_gatts_app_register(PROFILE_A/B_APP_ID)` → MTU 512 설정.
- **광고 파라미터**: `adv_int_min` 0x20(40 ms), `adv_int_max` 0x40(80 ms), `ADV_IND`, 공용 주소, 전 채널.
- **이벤트 흐름**:
  1. `REG_EVT` → 기기명·광고 데이터·스캔 응답 설정
  2. `CREATE_EVT` → 서비스 시작, `esp_ble_gatts_add_char()` 호출
  3. `ADD_CHAR_EVT` → 특성 핸들 저장, BLE2902 디스크립터 추가
  4. `CONNECT_EVT` → `esp_ble_gap_update_conn_params()`(프로파일 A만: 20–40 ms, 4000 ms 타임아웃)
  5. `READ_EVT` → 더미 4바이트 `esp_ble_gatts_send_response()`
  6. `WRITE_EVT` → CCCD 값 해석(0x0001 notify, 0x0002 indicate, 0x0000 off) 및 데이터 전송
  7. `EXEC_WRITE_EVT` → Prepare Write 버퍼 확정·해제

## 검증·재현성

- Espressif 공식 예제이며 ESP-IDF v3.1.5에서 빌드·동작이 확인된 문서다.
- 테스트 앱으로 nRF Connect (Android/iOS)를 권장한다.
- Write Long 처리(Prepare/Execute Write 시퀀스)와 연결 파라미터 갱신 절차를 완전히 다루고 있다.

## 한계·위험

- ESP-IDF v3.x 기준이라 v5.x의 `esp_bt_gap_set_device_name()` 등 최신 API 이름과 차이가 있을 수 있다.
- Bluedroid 기반이며, NimBLE(IDF 4.x 이후 옵션) 사용 시 API가 달라진다.
- 외부 IP(코드) 복사 불필요; 구조·흐름만 참조한다.

## 재사용 메모

- BLE GATT 서버의 이벤트 디스패치 구조(프로파일 배열 + `gatts_if` 분기)는 MicroBlaze V AXI-Lite 슬레이브의 레지스터 맵 주소 디코딩과 비교할 수 있다. CCCD(enable/disable notify) 개념은 AXI Stream TREADY 흐름 제어와 역할이 유사하다.
- 개조: GATT Characteristic 속성(READ/WRITE/NOTIFY)과 CCCD 디스크립터 활성화 로직은 AXI4-Lite 슬레이브의 상태 레지스터 + 인터럽트 마스크 레지스터 설계로 1:1 대응 가능하다. CPU 코어(ESP32 BT 컨트롤러)와 Bluedroid 스택은 옮길 수 없다. 주변장치 흐름(read/write 이벤트 → 응답 함수 호출)만 추출해 AXI-Lite FSM 상태 머신으로 재현한다.
---
*내 판단: BLE GATT 이벤트 흐름이 AXI-Lite 트랜잭션 처리 방식과 구조적으로 유사해 ESP32 IP 설계 참고로 가치가 높다.*
