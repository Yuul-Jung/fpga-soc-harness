---
name: hideakitai-esp32spislave
url: https://github.com/hideakitai/ESP32SPISlave
source_type: repo
vendor: neutral
board: [ESP32 계열 (칩별 SPI 버스 수가 다름)]
fit_basys3: needs-port
cpu: none(MCU 라이브러리, ESP32)
language: C++ (Arduino/PlatformIO)
tools: [Arduino IDE 2.0.11 이상, PlatformIO 5.0.0 이상]
bus: none (SPI 슬레이브)
peripherals: [comm-spi]
stage: T2
license: MIT
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/hideakitai/ESP32SPISlave/blob/main/README.md]
---
unverified: source_rev — 커밋 SHA 열람 권한이 응답 없이 철회되어 확인 못 함

## 요약
ESP32가 SPI 슬레이브가 되어 외부 마스터(여기서는 FPGA 쪽 SPI 마스터 IP를 상정, 내 판단)와 바이트 버퍼를 주고받게 하는 Arduino 라이브러리의 README를 읽었다. 한 번에 한 트랜잭션, 큐 후 대기, 큐 후 백그라운드 실행의 세 방식이 있다.

## 구조
- 방식: `transfer()`(블로킹 1건), `queue()`+`wait()`, `queue()`+`trigger()`(백그라운드). 상태 조회 함수와 `setDataMode()`·`setQueueSize()` 등 설정은 `begin()` 이전에 호출(README 서술).
- 기본 버스는 ESP32에서 HSPI, 다른 칩에서 FSPI. ESP32 HSPI 기본 핀(12~15)은 보드 기본 SPI 핀과 다르다(README 서술).
- 이 라이브러리는 DMA를 쓰지 않으며 32바이트 초과 전송은 별도 ESP32DMASPI를 가리킨다(README 서술).
- 최대 클럭은 README에 없다. 오류 시 1 MHz 이하로 낮추라는 조언만 있다.

## 검증·재현성
- 열람 범위는 README뿐. 예제 코드·테스트·CI는 unverified: 열람하지 않음. v0.4.0부터 API가 깨지는 변경이 있다고 README가 경고한다.

## 한계·위험
- 비블로킹 전송 중에는 버퍼를 건드리면 안 된다. ESP32-C3 등은 쓸 수 있는 SPI 버스가 하나뿐(README 서술).
- 모드 불일치·긴 배선·접지 공유 누락이 흔한 오류 원인으로 적혀 있다.
- Basys3 쪽: Pmod는 3.3V, ESP32 GPIO도 3.3V라 레벨 변환은 불필요로 보이나, ESP32 보드 전원·핀 허용치는 unverified.

## 재사용 메모
- 내 판단: 32바이트·낮은 클럭 한계는 FPGA SPI 마스터 IP의 프레임 길이(≤32바이트)와 클럭 분주(≤1 MHz 기본값)를 정하는 근거가 된다.
- 개조: 옮길 부분은 "버퍼 단위 전송 + 완료 후 결과 처리" 모델을 AXI4-Lite 레지스터(`TX_BUF`, `RX_BUF`, `LEN`, `STATUS.done`)와 인터럽트 1개로 바꾸는 것. 못 옮길 부분은 ESP32 SPI 드라이버와 DMA 정책. CPU 비종속 드라이버 구조상 ESP32는 호스트 측이다.
- 관련 카드: [[cvonk-fpga-spi]] (FPGA SPI 슬레이브 쪽 대응).
