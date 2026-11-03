# SoC 기술 트리 (단계별 카드 연결)

갱신: 2026-11-04 (/verify). 카드 141건 기준. 비 FPGA 도메인(STM32 18건·ESP32 11건·Arduino·임베디드·전자기술 포함).

---

## FPGA·SoC 단계별 연결 (Basys3 직접 연결 가능 카드)

| 단계 | 주요 카드 | 비고 |
|---|---|---|
| T0 | zipcpu-pmodamp2-project-ladder (T0-T2) | 핀 확인과 단음 단계 |
| T1 | wangxuan95-fpga-sdcard-file, element14-security-camera-2-sd-card-interfacing | CPU 없이 FSM으로 SD·카메라 |
| T2 | digilent-forum-pmodamp3-basys3-i2s, zipcpu-sdspi, zipcpu-pmodamp2-project-ladder | I2S 송신, Wishbone 주변장치 |
| T3 | (FPGA 카드 없음) | gap: 프레임워크 기반 SoC에 주변장치를 붙인 Basys3 사례 미확보 |
| T4 | columbia-4840-audio-visualizer | DE1-SoC HPS 기반 — Basys3 직접 이식 불가 |
| T5 | (카드 없음) | gap: DRAM 보드 필요, 현 카탈로그 범위 밖 |

---

## 개조 참고 — MCU·임베디드 도메인 (needs-port)

비 FPGA 도메인 카드는 "FPGA SoC 주변장치 IP로 옮길 수 있는 구조"를 기준으로 연결한다. 카드의 `개조:` 줄 참조.

### T1 단계 개조 참고

| 카드 (도메인) | 개조 대응 IP |
|---|---|
| espressif-idf-watchdog-timers (ESP32) | AXI4-Lite WDT IP (WDT_EN, WDT_TIMEOUT, WDT_RESET 레지스터) |
| deepbluembedded-stm32-complementary-pwm-dead-time (STM32) | 상보 PWM + 데드타임 RTL (카운터 기반 N 클럭 지연) |

### T2 단계 개조 참고

| 카드 (도메인) | 개조 대응 IP |
|---|---|
| espressif-idf-freertos-smp-multicore (ESP32) | AXI4-Lite DMA 채널 우선순위 분리 구조 (Core0/Core1 역할 분담 → DMA/MMIO 분리) |
| espressif-idf-ringbuf-ipc (ESP32) | AXI4-Stream FIFO 모드 선택 근거, MicroBlaze V SWI 패턴 |
| rcaelers-esp32-beacon-scanner (ESP32) | BLE→UART 패킷 형식 (UART 수신 FSM 근거) |
| hideakitai-esp32spislave (ESP32) | SPI CS·데이터 타이밍 (FPGA SPI 마스터 IP 타이밍) |

### T3 단계 개조 참고

| 카드 (도메인) | 개조 대응 IP |
|---|---|
| espressif-ota-updates-framework (ESP32) | 이중 슬롯 부트 FSM — FPGA ICAP 멀티부트 흐름 비교 |
| espressif-esp-ble-mesh (ESP32) | BLE Mesh 노드에 센서 공급하는 UART 인터페이스 설계 근거 |

---

## gap 목록 (내 판단)

- gap T1→T2: 오디오·SD를 AXI4-Lite 레지스터 맵으로 감싼 Basys3 완성형 카드 미확보.
- gap T2→T4: FPGA 내부 FFT (BRAM 제약) 사례 없음 — Columbia는 HW FFT 포기.
- gap T2: 모터 제어(엔코더 + PID) 를 Basys3 AXI4-Lite IP로 구현한 FPGA 카드 없음; STM32 도메인에 모터 제어 카드 다수 → 개조 경로는 있으나 Basys3 이식 카드 아직 없음(내 판단).
- gap T3: ESP32 BLE/Wi-Fi를 UART로 Basys3에 붙인 통합 SoC 카드 없음.
- gap T5: DRAM 보드 필요, 수집 대상 밖.
