---
name: randomnerdtutorials-esp32-inmp441-i2s
url: https://randomnerdtutorials.com/esp32-inmp441-i2s-microphone-arduino/
source_type: article
vendor: neutral
board: [ESP32-S3 (Freenove WROVER-CAM 등), ESP32 DevKit V1 (핀 조정 필요)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32-S3 Xtensa LX7)
language: C (Arduino framework, driver/i2s.h)
tools: [Arduino IDE, ESP32 보드 패키지 (ESP-IDF 기반)]
bus: I2S (BCLK/WS/SD)
peripherals: [sensor, comm-i2c]
stage: T1
license: unknown (튜토리얼 기사, 코드 직접 복사 주의 — 라이선스 미명시)
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://randomnerdtutorials.com/esp32-inmp441-i2s-microphone-arduino/]
---

## 요약
INMP441 I2S 디지털 마이크를 ESP32-S3에 연결해 소리 에너지(peak)를 감지하고 LED를 제어하는 Arduino 예제. I2S 수신 설정, DMA 버퍼 파라미터, 핀 배선을 L3로 확인함.

## 구조
- **연결 핀 (ESP32-S3 기준, 모든 GPIO 가변)**
  | INMP441 | ESP32-S3 GPIO | I2S 신호 |
  |---|---|---|
  | WS | 40 | Word Select (LRCLK) |
  | SCK | 42 | Serial Clock (BCLK) |
  | SD | 41 | Serial Data (DOUT, 마이크→MCU) |
  | L/R | GND | 왼쪽 채널 선택 |
  | VDD | 3.3V | 전원 |
- **I2S 설정**: 샘플레이트 16 kHz, 슬롯 32비트(`I2S_BITS_PER_SAMPLE_32BIT`), 24비트 데이터는 상위 정렬 → `>> 8` 추출
- **모드**: `I2S_MODE_MASTER | I2S_MODE_RX` (ESP32가 클럭 발생, 마이크 데이터 수신)
- **DMA**: `dma_buf_count = 8`, `dma_buf_len = 512` (바이트 단위 BUFFER_LEN)
- **API**: `i2s_driver_install()` → `i2s_set_pin()` → `i2s_zero_dma_buffer()` → 루프에서 `i2s_read()`
- **I2S 포트**: `I2S_NUM_0`
- **클랩 감지 파라미터**: `CLAP_THRESHOLD = 1_000_000`, 쿨다운 250ms, 간격 700ms (두 번 박수로 토글)

## 검증·재현성
- 직접 열람(L3): 핀표, 배선도, 코드 블록, 독자 댓글 확인
- ESP32 DevKit V1에서 핀 SCK=12, WS=14, SD=35으로 조정 후 동작 확인 사례(독자 댓글, 저자 확인)
- 임계값 조정 필요: 주변 소음 레벨과 박수 peak 차이를 Serial 출력으로 측정 후 설정

## 한계·위험
- 라이선스 미명시: 코드를 그대로 복사하면 저작권 문제 가능. 구조·로직만 참고하고 자체 구현 권장
- Wi-Fi+I2S 동시 사용 시 왜곡·배경 소음 보고(ESP32-S3+앰프, 독자 댓글, 미확인)
- 32비트 슬롯에서 24비트 추출 시 `>> 8` 필수 — 빠뜨리면 전체 PCM 값이 256배 과대

## 재사용 메모
- INMP441은 3.3V I2S 디지털 마이크로 Basys3 Pmod 포트에 직접 연결 가능.
- 개조: Basys3 FPGA에서 INMP441 직접 수신 — Pmod JA의 세 핀(BCLK, LRCLK, DOUT)에 연결, AXI I2S RX 커스텀 IP로 32비트 슬롯 수신 후 >> 8 처리, AXI-Stream으로 MicroBlaze V에 전달. 샘플레이트 16 kHz → Basys3 100MHz 기준으로 분주기 계수 3125 (내 계산). 클랩 감지 임계값 로직은 C 펌웨어에서 그대로 사용 가능. I2S 클럭 발생은 MCU 대신 FPGA가 마스터로 동작하므로 `I2S_MODE_MASTER` 역할이 FPGA 측으로 옮겨온다.
