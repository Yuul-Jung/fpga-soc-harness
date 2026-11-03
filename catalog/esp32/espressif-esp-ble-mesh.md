---
name: espressif-esp-ble-mesh
url: https://docs.espressif.com/projects/esp-idf/en/release-v4.2/esp32/api-guides/esp-ble-mesh/ble-mesh-index.html
source_type: article
vendor: neutral
board: [ESP32-DevKitC, ESP-WROVER-KIT]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: [ESP-IDF 4.x]
bus: BLE Mesh (ADV Bearer, GATT Bearer)
peripherals: [BLE-Mesh]
stage: T3
license: Apache-2.0
stats: {stars: N/A, commits: N/A, last_update: 2020}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://docs.espressif.com/projects/esp-idf/en/release-v4.2/esp32/api-guides/esp-ble-mesh/ble-mesh-index.html, https://github.com/espressif/esp-idf/blob/3a71941/docs/en/api-reference/bluetooth/esp-ble-mesh.rst]
---

unverified: source_rev — release/v4.2 문서 기준이나 커밋 SHA 미확인

## 요약 (3줄 이내)

Espressif 공식 ESP-BLE-MESH 가이드. Bluetooth Mesh Profile v1.0.1 기반으로 조명·센서 등 IoT 망을 구성하며, Zephyr BLE Mesh 스택 위에 구현된다. 프로비저닝·릴레이·로우파워·프록시 노드 역할을 모두 지원하고, 100대 기기를 60초 이내 프로비저닝하는 Fast Provisioning 예제를 포함한다.

## 구조

- **구현 기반**: Zephyr Bluetooth Mesh 스택 위에 Espressif가 추가 레이어를 올린 구조.
- **네트워크 토폴로지**: "managed flooding mesh"—ADV Bearer로 메시지를 범람 전달하고, Relay 노드가 증폭한다.
- **노드 역할**: Proxy(GATT 연결 허용), Relay(범위 연장), Low Power(딥슬립+Friend 사용), Friend(LP 노드 메시지 버퍼링). 하나의 노드가 여러 역할을 동시에 수행 가능.
- **지원 모델 범주**: Configuration, Health, Generic, Sensor, Time and Scenes, Lighting Server/Client 각 쌍.
- **프로비저닝 절차**:
  1. Scanner가 미등록 기기를 BLE 광고에서 발견
  2. GATT 연결 → Mesh GATT 서비스 확인
  3. IDENTIFY → PROVISION (ProvisioingCapabilities·PublicKey 교환)
  4. 연결 재수립 → Composition Data 취득 → AppKey 추가 → 모델 바인딩
- **Fast Provisioning**: 100대를 60초 이내 등록하는 예제 존재.
- **Wi-Fi+BLE 공존**: 별도 예제에서 coexistence 모드 지원을 명시.

## 검증·재현성

- Espressif 공식 문서이며 ESP-IDF release/v4.2 기준이다.
- Bluetooth Mesh Profile SIG v1.0.1 인증을 목표로 구현되었다.
- API 구성은 Definitions, Core API(6개 하위 영역), Models API로 나뉜다.
- 메모리 요구량은 이 페이지에 없음. `unverified: 메모리(RAM/FLASH) 수치`.
- 보드 동작 확인: ESP32-DevKitC, ESP-WROVER-KIT를 공식 지원 보드로 명시.

## 한계·위험

- release/v4.2 기준으로 최신 v5.x API와 차이 가능.
- RAM 요구량이 명시되지 않아 Mesh 활성화 시 메모리 압박 불명확.
- 아키텍처 세부(레이어별 역할, 메시지 큐 크기)는 별도 문서(ble-mesh-architecture)에 있으며 이번 열람 범위 외.
- Low Power 노드와 Friend 노드 간 메시지 큐 오버플로 위험은 별도 튜닝 필요.

## 재사용 메모

- BLE Mesh의 프로비저닝 절차(노드 발견 → 등록 → 모델 바인딩)는 Basys3 SoC의 AXI 버스에서 IP 코어 발견(주소 맵 스캔)과 개념적으로 대응된다. Sensor Model Server/Client 구조는 AXI-Lite 센서 레지스터 맵 설계(데이터 레지스터, 상태 레지스터, 인터럽트 마스크)와 역할이 유사하다.
- 개조: Mesh 계층(ADV Bearer, Relay 플러딩)은 BLE 고유 기능이라 FPGA로 옮길 수 없다. Generic OnOff Server/Client 개념(enable/disable → GPIO 출력)은 AXI-Lite 제어 레지스터 비트 설계로 직접 이식 가능하다. Sensor Data Model의 데이터 형식 협상(Property ID)은 AXI-Lite ID 레지스터 패턴과 유사해 IP 표준 `INFO_REG` 설계에 참고할 수 있다.
---
*내 판단: BLE Mesh의 계층적 모델 등록(AppKey 바인딩→모델 바인딩)이 AXI-Lite IP 디스커버리 시나리오와 구조적으로 유사해 IP 표준 설계 참고 가치가 있다.*
