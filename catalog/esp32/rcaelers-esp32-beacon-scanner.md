---
name: rcaelers-esp32-beacon-scanner
url: https://github.com/rcaelers/esp32-beacon-scanner
source_type: repo
vendor: neutral
board: [ESP32]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (ESP-IDF)
tools: [ESP-IDF, CMake, Travis CI]
bus: BLE (passive scan), MQTT over Wi-Fi (TCP/IP)
peripherals: [BLE-scanner, MQTT-publisher]
stage: T2
license: MIT
stats: {stars: 116, commits: 223, last_update: 2025-10-16}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://github.com/rcaelers/esp32-beacon-scanner]
---

unverified: source_rev — 아카이브 저장소라 현재 커밋 SHA 미확인

## 요약 (3줄 이내)

다수의 ESP32가 주변 BLE 기기(iBeacon 포함)를 수동 스캔해 감지된 MAC 주소·RSSI 값을 MQTT로 전송하는 실내 측위 인프라 프로젝트. ESP-IDF + CMake 기반이며 MIT 라이선스 공개 소스다. 2025-10-16 아카이브(읽기 전용).

## 구조

- `main/` 하위에 BLE 스캔과 MQTT 전송 로직이 있으며, `components/loopp` 디렉터리에 비동기 이벤트 루프 컴포넌트를 포함한다(추정: README 미열람, 디렉터리 목록 기준).
- 주요 설정 파일: `CMakeLists.txt`, `sdkconfig.defaults`, `partitions.csv`.
- CI: Travis CI (`.travis.yml`, `travis-build.sh`)—`travis-ci.org` 도메인 기준이라 현재 CI 동작 여부 미확인.
- BLE passive scan → 기기 MAC·RSSI 수집 → MQTT 메시지 발행(형식 미확인).
- 최종 목표: 여러 ESP32 노드가 같은 비콘의 RSSI를 각자 보고하면 서버가 삼변측량으로 위치를 계산함.

## 검증·재현성

- 스타 116, 커밋 223으로 활발히 개발된 이력이 있다.
- ESP-IDF + CMake 빌드 구조로 현대적인 ESP-IDF 프로젝트 배치를 따른다.
- Travis CI 빌드 뱃지 링크가 있으나 `travis-ci.org`는 서비스 종료로 현재 상태 미확인.
- README에 "work in progress"라고 명시; 실제 측위 정확도 데이터는 없음.
- 소스 코드 본문은 열람하지 않음(GitHub MCP 범위 외 저장소, WebFetch 미시도).

## 한계·위험

- 아카이브 저장소라 유지보수 없음; 최신 ESP-IDF(v5.x)와 API 호환성 미확인.
- Travis CI 의존 CI는 현재 동작하지 않음.
- README에 MQTT 메시지 형식, 브로커 설정, 위치 계산 서버 코드가 별도 저장소에 있는지 불명확. `unverified: MQTT 형식·위치 계산 서버 코드 위치`.
- `components/loopp`의 성격(자체 비동기 프레임워크 추정)은 미확인.

## 재사용 메모

- BLE passive scan + MQTT 보고 구조는 Basys3 없이 독립 센서 노드로 활용 가능하다. FPGA-SoC 연동 아이디어: ESP32가 BLE 비콘 RSSI를 수집해 UART/SPI로 Basys3에 전달하고, Basys3가 삼변측량 연산(고정소수점)을 수행하는 가속기 역할을 할 수 있다.
- 개조: BLE 스캔 데이터를 UART 패킷으로 Basys3에 보내는 인터페이스는 devices/uart/의 수신 FSM으로 처리 가능하다. 측위 연산(거리 계산, 가중 평균)은 고정소수점 DSP 블록 IP로 구현할 수 있다. ESP32 BLE 스택 자체(BT 컨트롤러, Bluedroid)는 Basys3로 옮길 수 없다.
---
*내 판단: BLE→MQTT 파이프라인 구조가 ESP32↔FPGA 하이브리드 측위 시스템 아이디어의 하드웨어 근거로 적합하다.*
