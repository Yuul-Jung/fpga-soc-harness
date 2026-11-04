# Raspberry Pi GPIO 소프트웨어 스택 종합

갱신: 2026-11-04 (verify 사이클, 초판)

## 개요

Raspberry Pi의 GPIO/SPI/I2C 하드웨어를 Python 소프트웨어로 제어하는 사례 3건. 모두 Linux 호스트 소프트웨어이며 `fit_basys3: needs-port`. Basys3 재사용은 "프로토콜 타이밍과 CS 의미론, 계층 구조"만 가져오며 커널 드라이버·/dev 노드는 이식 불가다. 재사용 판단의 근거는 각 카드 `재사용 메모`에 있다.

## 카드 목록

| 항목 | 카드 | 보드 | CPU/버스 | 주변장치 | 한계 |
|---|---|---|---|---|---|
| Linux spidev Python C 확장 | doceme-py-spidev | RPi | none(Linux 호스트) / spidev 커널 | comm-spi | Linux/spidev 전용, /dev/spidev* 필요, root 권한 |
| GPIO 소프트웨어 스택 비교 | zbotic-rpi-gpio-stack-guide | RPi | none(Linux 호스트) / GPIO | comm-spi, comm-i2c, sensor, actuator-servo | RPi/Linux 전용, lgpio는 Pi 버전 의존 |
| SPI 활성화+spidev 튜토리얼 | abelectronics-rpi-spi-tutorial | RPi | none(Linux 호스트) / spidev 커널 | comm-spi | RPi/Linux 전용, /boot/config.txt 경로 버전별 상이 |

## 소프트웨어 계층 구조

```
gpiozero(고수준 디바이스 API: LED, Servo, Motor)
  ↓ 핀 팩토리 교체 가능
pigpio / RPi.GPIO / lgpio(GPIO 레지스터 직접 접근)
  ↓
spidev / smbus2(Linux 커널 드라이버, /dev/spidev*, /dev/i2c-*)
  ↓
BCM2835 하드웨어 SPI / I2C 컨트롤러
```

MicroBlaze V BSP의 대응 계층 (내 판단, zbotic-rpi-gpio-stack-guide 재사용 메모 참조):
```
C 디바이스 추상화(응용 드라이버)
  ↓
AXI4-Lite HAL(IP 종류별 교체 가능)
  ↓
Verilog AXI SPI/I2C IP(커스텀 RTL)
  ↓
Basys3 FPGA 하드웨어 로직
```

## 패턴

**SPI 초기화 시퀀스 대응:** Python spidev `open → max_speed_hz, mode 설정 → xfer2 → close` 는 MicroBlaze V `XSpi_Initialize → XSpi_SetOptions → XSpi_Transfer` 와 1:1 대응한다. 속도(`max_speed_hz` ↔ `SCK_RATIO`), 모드(`mode 0~3` ↔ `CPHA/CPOL`), 비트 수(`bits_per_word` ↔ 프레임 크기)가 각각 AXI SPI IP 파라미터에 대응한다(내 판단, abelectronics-rpi-spi-tutorial·doceme-py-spidev 재사용 메모).

**CS 의미론:** `xfer()`는 각 바이트 사이에 CS 토글, `xfer2()`는 전체 전송 동안 CS 유지. Basys3 AXI SPI IP의 `MANUAL_SS` 비트 의미와 같다. 혼동하면 슬레이브가 프레임 경계를 잘못 인식한다(내 판단, doceme-py-spidev 한계·위험).

**gpiozero 핀 팩토리 패턴 → AXI IP 추상화:** gpiozero가 핀 팩토리를 교체해도 같은 API를 제공하듯, MicroBlaze V BSP에서 SPI IP 종류(AXI SPI vs AXI Quad SPI)를 바꿔도 응용 코드가 같은 HAL 인터페이스를 보도록 드라이버를 설계할 수 있다(내 판단, zbotic-rpi-gpio-stack-guide 재사용 메모).

## 교훈

- RPi SPI 최대 속도 32 MHz(BCM2835) / 실용 권장 8 MHz는 Basys3 AXI SPI IP의 `SCK_RATIO` 파라미터 선택 기준으로 사용 가능하다(abelectronics-rpi-spi-tutorial).
- xfer3()의 청크 분할(커널 버퍼 4096 바이트 한계)은 Basys3 DMA 또는 AXI Burst 연동 설계 시 버퍼 크기 결정 참조가 된다(doceme-py-spidev).
- smbus2의 `write_byte_data(addr, reg, val)` / `read_byte_data(addr, reg)` 는 AXI I2C master IP의 커맨드 레지스터 인터페이스(슬레이브 주소+레지스터 오프셋+데이터)와 동일한 의미론이다(zbotic-rpi-gpio-stack-guide).

## 관련 아이디어

- I-048: RPi SPI 마스터 → Basys3 AXI SPI 슬레이브 IP 테스트 하네스 (vetted, 5점, T2)
- I-049: pigpio 비트뱅킹 → Basys3 비표준 프로토콜 IP 타이밍 검증 (vetted, 5점, T2)
- I-050: gpiozero 디바이스 추상화 패턴 → MicroBlaze V C 드라이버 API 설계 참조 (vetted, 6점, T3)
