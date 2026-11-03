# ESP32 사례 종합 (atlas/esp32.md)

갱신일: 2026-11-04
카드 수: 11 (`catalog/esp32/`)
목적: ESP32 Wi-Fi·BLE·FreeRTOS 사례에서 Basys3 SoC 주변장치 IP로 옮길 수 있는 구조와 패턴을 추출한다.

---

## 1. 단계별 분포

| 단계 | 카드 수 | 대표 항목 |
|------|---------|-----------|
| T0   | 0 | — |
| T1   | 3 | FreeRTOS 멀티태스킹, DHT+딥슬립, Watchdog 타이머 |
| T2   | 5 | MQTT FAQ, GATT 서버, SPI 슬레이브, FreeRTOS SMP, Ring Buffer IPC |
| T3   | 2 | BLE Mesh, OTA 업데이트 |
| T4   | 0 | — |
| T5   | 0 | — |
| (T2) | 1 | BLE 패시브 스캔→MQTT (rcaelers, archived 2025) |

---

## 2. 주제별 사례 표

### 2.1 무선 통신 (MQTT, BLE)

| 카드 | CPU | 단계 | 주변장치 | 한계/재사용 포인트 |
|------|-----|------|----------|--------------------|
| espressif-faq-mqtt | ESP32 | T2 | MQTT(Wi-Fi) | 연결·재연결·QoS·토픽 필터 패턴 → FPGA 측 Wi-Fi 모듈(ESP32 보조 MCU)과 주고받을 직렬 명령 프로토콜 근거 |
| modestos-esp32-dht-mqtt-deepsleep | ESP32 | T1 | DHT22 센서 + MQTT + 딥슬립 | 슬립→측정→발행→슬립 사이클 → 센서 허브 IP(I-009)의 1회 측정 후 인터럽트 패턴 참고 |
| rcaelers-esp32-beacon-scanner | ESP32 | T2 | BLE 패시브 스캔 + MQTT | MAC/RSSI 패킷을 UART로 내보내는 구조 → Basys3에서 ESP32를 보조 MCU로 붙여 BLE 데이터를 UART로 받는 패턴; 아카이브(2025-10-16) |
| espressif-idf-gatt-server-walkthrough | ESP32 | T2 | BLE GATT 서버 | ATT 속성·핸들·콜백 구조 → FPGA 측에서 필요한 항목은 UUID 필터와 고정 속성 테이블 (소프트 BLE 스택은 옮기기 어려움) |
| espressif-esp-ble-mesh | ESP32 | T3 | BLE Mesh(프로비저닝·릴레이·로우파워) | 대규모 Mesh는 FPGA로 옮길 수 없음; FPGA는 BLE Mesh 노드에 센서 데이터를 공급하는 역할 |

### 2.2 OTA·펌웨어 업데이트

| 카드 | CPU | 단계 | 주변장치 | 한계/재사용 포인트 |
|------|-----|------|----------|--------------------|
| espressif-ota-updates-framework | ESP32 | T3 | OTA(듀얼 슬롯, Wi-Fi) | 이중 슬롯 부트로더 구조 → FPGA 비트스트림 업데이트 흐름(ICAP IP) 비교 참고 |

### 2.3 SPI·FreeRTOS·디버그

| 카드 | CPU | 단계 | 주변장치 | 한계/재사용 포인트 |
|------|-----|------|----------|--------------------|
| hideakitai-esp32spislave | ESP32 | T2 | SPI 슬레이브 | DMA 기반 비블로킹 SPI → FPGA SPI 마스터 IP의 CS·데이터 타이밍 참고 |
| controllerstech-esp32-freertos-multitasking | ESP32 | T1 | FreeRTOS 태스크·뮤텍스·세마포어 | 태스크 간 동기화 패턴 → FPGA에서는 handshake 레지스터(READY/ACK 비트)로 대응 |
| espressif-idf-freertos-smp-multicore | ESP32 (듀얼코어) | T2 | FreeRTOS SMP, 코어 고정 | Core0=Wi-Fi, Core1=FPGA/UART 분리 구조 → AXI4-Lite DMA 채널 우선순위 분리 근거; 듀얼코어 한정(S2/C3 불가) |
| espressif-idf-ringbuf-ipc | ESP32 (듀얼코어) | T2 | Ring Buffer(FIFO), IPC | No-Split/Allow-Split/Byte Buffer 타입 선택 기준 → AXI4-Stream FIFO 모드 선택 근거; IPC 패턴 → MicroBlaze V 소프트 인터럽트(SWI) 대응 |
| espressif-idf-watchdog-timers | ESP32 | T1 | Watchdog(TWDT, IWDT) | WDT 등록→리셋→타임아웃 패닉 흐름 → AXI4-Lite WDT IP(WDT_EN, WDT_TIMEOUT, WDT_RESET 레지스터) 설계 근거; S6 실패 사례 포함 |

---

## 3. 주변장치 태그 집계

| 태그 | 카드 수 |
|------|---------|
| comm-eth(MQTT/Wi-Fi) | 3 |
| BLE(GATT·Mesh·스캔) | 3 |
| sensor | 2 |
| comm-spi | 1 |
| comm-uart(FreeRTOS SMP/IPC) | 2 |
| debug(OTA/WDT) | 2 |

---

## 4. 패턴과 교훈

### 4.1 옮길 수 있는 것
- **직렬 데이터 형식**: rcaelers BLE 스캐너의 MAC/RSSI UART 패킷 형식, modestos DHT+딥슬립의 측정→발행 흐름은 FPGA 센서 허브(I-009)가 UART로 내보낼 패킷 형식의 참고 모델이다.
- **MQTT 프로토콜 패턴**: 연결·재연결·QoS 선택·토픽 필터는 ESP32를 보조 MCU로 쓸 때 MicroBlaze V 펌웨어가 보낼 직렬 명령 집합(AT 명령 계열)을 설계하는 근거가 된다.
- **이중 슬롯 부트로더 구조**: OTA 카드의 슬롯 A/B 선택 FSM은 FPGA 비트스트림 업데이트 흐름(멀티부트 ICAP)과 대조할 수 있다.
- **handshake 레지스터**: FreeRTOS 뮤텍스·세마포어로 보호하는 공유 버퍼는 FPGA에서 READY/ACK 비트 쌍으로 대응한다.

### 4.2 옮길 수 없는 것
- Wi-Fi·BLE 무선 스택 자체(Basys3에 무선 모듈 없음). ESP32를 보조 MCU로 Pmod UART에 붙여 명령을 주고받는 방식만 현실적이다.
- BLE Mesh 프로비저닝·릴레이 프로토콜(소프트 스택 전체가 ESP-IDF 의존).
- SPI 슬레이브의 DMA 타이밍은 Xtensa 코어 버스 전용이라 Basys3 SPI 마스터 IP로 직접 옮기지 않는다.

### 4.3 내 판단
- 내 판단: ESP32 카드 11건 중 8건이 T1~T2로 단순 인터페이스가 중심이다. FPGA 관점의 활용 가치는 "ESP32를 보조 무선 MCU로 붙이는 조합"에 있고, rcaelers BLE 스캐너(UART 패킷 형식)와 modestos 딥슬립(1회 측정 사이클)이 가장 직접적인 참고가 된다.
- 내 판단: OTA 카드와 BLE Mesh 카드는 T3 수준이지만 FPGA 주변장치 IP 설계에 직접 쓰기 어렵다. ICAP 비교 참고용으로 아카이브한다.
- 내 판단: freertos-smp-multicore와 ringbuf-ipc 카드는 MicroBlaze V AXI4-Stream·DMA·소프트 인터럽트 IP 설계에 구체적인 패턴 근거를 제공한다. watchdog-timers 카드의 "등록→리셋→패닉" 흐름은 AXI4-Lite WDT IP 레지스터 설계에 직접 대응된다.

---

## 5. 관련 아이디어

| 아이디어 | 근거 카드 |
|----------|-----------|
| I-009 센서 허브 IP | modestos-esp32-dht-mqtt-deepsleep, rcaelers-esp32-beacon-scanner |

---

## 6. 연결

- 관련 atlas: atlas/stm32.md (센서·통신 패턴 공유)
- 관련 devices: `devices/uart/`(BLE UART 패킷 형식)
- soc-map: T2 센서 허브 단계에 연결
