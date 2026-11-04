---
name: zbotic-rpi-gpio-stack-guide
url: https://www.zbotic.in/raspberry-pi-gpio-advanced-guide/
source_type: article
vendor: neutral
board: [RPi]
fit_basys3: needs-port
cpu: none(Linux 호스트 소프트웨어)
language: Python
tools: [pigpio, spidev, smbus2, gpiozero, lgpio]
bus: SPI, I2C, GPIO
peripherals: [comm-spi, comm-i2c, sensor, actuator-servo]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev: 
sources: [https://www.zbotic.in/raspberry-pi-gpio-advanced-guide/]
---

## 요약

Raspberry Pi의 GPIO 제어 소프트웨어 스택 전체를 pigpio·spidev·smbus2·gpiozero·lgpio 다섯 계층으로 정리한 중급자 대상 기사. 각 라이브러리의 활성화 방법, 역할, 한계를 비교하고 SPI/I2C 커널 드라이버 활성화 절차를 함께 설명한다.

## 구조

### SPI 활성화
- `raspi-config → Interface Options → SPI → Enable` 또는 `/boot/config.txt`(구) / `/boot/firmware/config.txt`(신) 에 `dtparam=spi=on` 추가 후 재부팅
- `/dev/spidev0.0`(CE0), `/dev/spidev0.1`(CE1) 노드 생성 확인

### I2C 활성화
- `/boot/config.txt`에 `dtparam=i2c_arm=on` 추가
- `i2c-tools` 패키지의 `i2cdetect -y 1`로 장치 주소 스캔

### 라이브러리 계층
- **pigpio**: joan2937의 C 라이브러리 + `pigpiod` 데몬. 마이크로초 단위 GPIO 타이밍, 하드웨어 PWM, 비트뱅킹 SPI/I2C 지원. Python `pigpio` 모듈은 소켓으로 데몬에 연결
- **spidev**: Linux 커널 spidev 드라이버의 Python 바인딩(`/dev/spidev*` 노드 경유)
- **smbus2**: I2C/SMBus 레지스터 R/W용 Python 라이브러리. `/dev/i2c-*` 노드 경유. `write_byte_data(addr, reg, val)`, `read_byte_data(addr, reg)` 형태
- **gpiozero**: 고수준 추상화. `LED`, `Button`, `Servo`, `Motor` 등 디바이스 클래스 제공. 내부 핀 팩토리를 pigpio/RPi.GPIO/lgpio/native로 교체 가능
- **lgpio**: Pi 5 권장 라이브러리. gpiod 계열, 그룹 GPIO 조작 지원. gpiozero 핀 팩토리 백엔드로도 사용

## 검증·재현성

- 기사 형태로 실행 예제 코드가 포함됨. 테스트벤치나 CI 없음
- 라이브러리 각각의 `pip install` 절차와 간단한 GPIO 토글/SPI 전송 예제 포함

## 한계·위험

- 출처 미상(unknown 라이선스): 기사 본문이므로 코드 조각 외 라이선스 미표기
- RPi/Linux 전용 스택: Basys3 직접 사용 불가
- lgpio 활성화 조건이 Pi 버전에 따라 다를 수 있음(Pi 4 이하에서는 RPi.GPIO가 여전히 사용됨, 기사 기준)

## 재사용 메모

- GPIO 소프트웨어 스택 계층화 패턴이 Basys3 MicroBlaze V BSP 설계와 직접 대응: gpiozero(고수준 디바이스 API) → pigpio/RPi.GPIO(레지스터 접근) → spidev/smbus2(커널 드라이버) → 하드웨어. MicroBlaze V에서는 C 디바이스 추상화 → AXI4-Lite HAL → RTL 주변장치 순서로 같은 구조 적용 가능 (내 판단).
- smbus2의 `write_byte_data(addr, reg, val)` / `read_byte_data(addr, reg)` 는 AXI I2C master IP의 커맨드 레지스터 인터페이스(슬레이브 주소 + 레지스터 오프셋 + 데이터)와 동일한 의미론 (내 판단).
- `개조:` pigpio 데몬의 마이크로초 타이밍 정밀도는 Basys3 100 MHz 클럭(10 ns 분해능)에서는 클럭 카운터 IP로 훨씬 정밀하게 대체 가능. gpiozero의 핀 팩토리 교체 패턴은 Basys3 C BSP에서 SPI/I2C 드라이버를 AXI IP 종류에 따라 교체하는 구조로 옮길 수 있다. OS·데몬 의존 부분(pigpiod 소켓, /dev 노드, udev)은 직접 이식 불가 (내 판단).
- **라이선스 확인 필요**: 출처 라이선스 unknown. 코드 직접 복사 금지. 아키텍처 패턴·계층화 개념 참고만 허용.
