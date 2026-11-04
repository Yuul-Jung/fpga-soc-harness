---
name: abelectronics-rpi-spi-tutorial
url: https://www.abelectronics.co.uk/kb/article/1136/spi-communication-with-raspberry-pi
source_type: article
vendor: neutral
board: [RPi]
fit_basys3: needs-port
cpu: none(Linux 호스트 소프트웨어)
language: Python
tools: [spidev, raspi-config]
bus: SPI
peripherals: [comm-spi]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev: 
sources: [https://www.abelectronics.co.uk/kb/article/1136/spi-communication-with-raspberry-pi]
---

## 요약

Raspberry Pi에서 SPI 버스를 활성화하고 Python `spidev` 라이브러리로 외부 장치와 통신하는 방법을 단계별로 설명한 튜토리얼. 커널 드라이버 활성화부터 Python 전송 예제까지 커버하며 2015년 초판, 2025년 최신 Pi OS 기준으로 갱신됨.

## 구조

### SPI 드라이버 활성화 절차
1. `raspi-config → 3 Interface Options → I4 SPI → Yes`로 커널 모듈 활성화, 재부팅
2. 대안: `/boot/config.txt`(Pi 4 이하) 또는 `/boot/firmware/config.txt`(Pi 5·최신 OS)에 `dtparam=spi=on` 추가
3. `ls /dev/spidev*` 로 `/dev/spidev0.0`(CE0), `/dev/spidev0.1`(CE1) 노드 확인

### Python spidev 설치 및 기본 사용
- `apt-get install python3-spidev` 또는 `pip install spidev`
- `SpiDev()` 객체 생성 → `open(0, 0)` (bus=0, CE=0) → 전송 → `close()`
- 주요 호출: `writebytes([0x01, 0x02])`, `readbytes(2)`, `xfer2([0xAB])` (전송+수신 동시)

### SPI 버스 하드웨어 사양
- RPi GPIO 핀 배치: MOSI(GPIO10), MISO(GPIO9), SCLK(GPIO11), CE0(GPIO8), CE1(GPIO7)
- 하드웨어 SPI 최대 속도: 32 MHz (BCM2835 데이터시트 기준), 실사용 권장 최대 약 8 MHz (기사 언급)
- 전압 레벨: 3.3 V 로직 (5 V 장치 연결 시 레벨 변환 필요)

## 검증·재현성

- 기사 형식, 단계별 스크린샷과 예제 코드 포함
- 별도 CI/테스트벤치 없음. 절차 자체가 검증 역할

## 한계·위험

- RPi/Linux 전용: Basys3 직접 적용 불가
- 라이선스: 기사이므로 명시 없음(unknown). 절차 설명을 참조하는 것은 무방 (내 판단)
- `/boot/config.txt` 경로가 Pi OS 버전에 따라 다름 — 최신 Pi 5는 `/boot/firmware/config.txt`

## 재사용 메모

- `open(bus, device)` → `max_speed_hz`, `mode` 설정 → `xfer2(data)` → `close()` 시퀀스는 MicroBlaze V의 AXI SPI IP 초기화 순서(`XSpi_Initialize → XSpi_SetOptions → XSpi_Transfer`)와 1:1 대응 (내 판단).
- SPI 버스 번호(0)와 CE 번호(0,1)를 `open(bus, device)`로 선택하는 방식은 Basys3의 SPI 슬레이브 선택(CS 신호 디코딩)과 같은 추상화 단계임 (내 판단).
- `개조:` 이 튜토리얼의 SPI 활성화→속성 설정→전송 흐름은 Basys3의 AXI SPI master IP를 위한 MicroBlaze V BSP 드라이버 작성 순서의 직접 참조 모델이 된다. 하드웨어 SPI 최대 속도(32 MHz) 및 실용 권장값(8 MHz)은 Basys3 SPI IP의 `SCK_RATIO` 파라미터 선택 기준으로 활용 가능. RPi 전용 커널 드라이버(/dev/spidev) 계층은 옮길 수 없고, 프로토콜 타이밍과 CS 의미론만 RTL 설계에 적용한다 (내 판단).
