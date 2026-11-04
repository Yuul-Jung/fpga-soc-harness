# Raspberry Pi 도메인 종합

갱신: 2026-11-04 (8차 verify: zbotic-rpi-gpio-stack-guide 재사용 메모 라이선스 고지 추가)

## 개요

Raspberry Pi 도메인 카드 6건: GPIO/SPI/I2C Python 소프트웨어 3건 + Buildroot 최소 이미지·부트 최적화 3건. 모두 Linux 호스트 소프트웨어이며 `fit_basys3: needs-port`. Basys3 재사용은 "프로토콜 타이밍·CS 의미론·계층 구조, OS 이미지 최소화 패턴"만 가져오며 커널 드라이버·/dev 노드는 이식 불가다.

## 카드 목록

### GPIO/SPI/I2C Python 소프트웨어

| 항목 | 카드 | 보드 | CPU/버스 | 주변장치 | 한계 |
|---|---|---|---|---|---|
| Linux spidev Python C 확장 | doceme-py-spidev | RPi | none(Linux 호스트) / spidev 커널 | comm-spi | Linux/spidev 전용, /dev/spidev* 필요, root 권한 |
| GPIO 소프트웨어 스택 비교 | zbotic-rpi-gpio-stack-guide | RPi | none(Linux 호스트) / GPIO | comm-spi, comm-i2c, sensor, actuator-servo | RPi/Linux 전용, lgpio는 Pi 버전 의존 |
| SPI 활성화+spidev 튜토리얼 | abelectronics-rpi-spi-tutorial | RPi | none(Linux 호스트) / spidev 커널 | comm-spi | RPi/Linux 전용, /boot/config.txt 경로 버전별 상이 |

### Buildroot·Linux 이미지·부트 최적화

| 항목 | 카드 | 보드 | 도구 | 단계 | 한계 |
|---|---|---|---|---|---|
| Buildroot 최소 이미지 (RPi3) | sujan-coder-buildroot-linux-rpi3 | RPi3 | Buildroot, BusyBox 1.37, GCC | T0 | SSH·네트워크만 포함, 부팅 시간 미측정 |
| Buildroot 실습 튜토리얼 (RPi4) | obuda-buildroot-mini-linux-tutorial | RPi4 AArch64 | Buildroot, dropbear, systemd-analyze | T0 | 교육용, 라이선스 unknown |
| 임베디드 Linux 부팅 시간 단축 (Yocto) | smartmechatronics-embedded-linux-boot-time-reduction | RPi4 | Yocto/BitBake, U-Boot, Grabserial, bootgraph.pl | T1 | 라이선스 unknown, 미완성 과제(커널 크기 축소) |

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

## Buildroot 최소 이미지·부트 최적화 패턴

**공통 접근법**: Buildroot `make menuconfig`로 BusyBox·dropbear SSH·spidev/i2c-dev 커널 모듈만 포함한 최소 rootfs를 만들면 부팅 시간 3~10 s, 이미지 크기 30~100 MB 수준. stock RPi OS(70~250 s, 수백 개 서비스) 대비 큰 차이다(내 판단, obuda·sujan 카드).

**부트 단계별 최적화**(smartmechatronics 카드 기준):
| 단계 | 주요 기법 | 단축 |
|---|---|---|
| 사용자 공간 | systemd 제거 → 최소 init 스크립트 | 3.56 → 0.55 s |
| 커널 | 드라이버 모듈화(지연 로드), 비필수 제거 | 1.3 s (미완성 과제) |
| U-Boot | 딜레이 제거(`bootdelay=0`), SD 직접 로드 스크립트 | 약 2.4 s |

**Basys3 IP 외부 검증 호스트 패턴**: Buildroot RPi 이미지에 spidev·i2c-dev 추가 후 Basys3 Pmod(3.3V 직결)와 연결하면 JTAG 없이 현장 레지스터 R/W 가능. I-058이 이를 패키지화 대상으로 삼는다(내 판단).

**MicroBlaze V·LiteX Linux 개조 경로**(내 판단):
- U-Boot 딜레이 제거·SD 로드 스크립트는 LiteX Linux U-Boot에도 적용 가능(I-059).
- BusyBox init + 최소 init 스크립트는 BRAM 제한 Basys3의 initramfs에 특히 유효(I-060, S4 역전).
- Grabserial·bootgraph.pl 측정 절차는 도구 의존 없이 이식 가능.

## 관련 아이디어

- I-048: RPi SPI 마스터 → Basys3 AXI SPI 슬레이브 IP 테스트 하네스 (vetted, 5점, T2)
- I-049: pigpio 비트뱅킹 → Basys3 비표준 프로토콜 IP 타이밍 검증 (vetted, 5점, T2)
- I-050: gpiozero 디바이스 추상화 패턴 → MicroBlaze V C 드라이버 API 설계 참조 (vetted, 6점, T3)
- I-055: RPi SPI 디버그 콘솔 — MicroBlaze V 레지스터 R/W 창구 (vetted, 6점, T2)
- I-056: RPi I2C 클럭 스트레칭 버그 → FPGA I2C 슬레이브 무클럭스트레칭 패턴 (vetted, 5점, T2)
- I-057: RPi SPI 이미지 스트리밍 + VGA 출력 (vetted, 5점, T3)
- I-058: Buildroot 최소 이미지(dropbear SSH) RPi 검증 호스트 (vetted, 7점, T2)
- I-059: U-Boot 딜레이 제거·SD 직접 로드 → LiteX Linux 부트 최적화 (vetted, 5점, T3)
- I-060: BusyBox init + 최소 init 스크립트 → BRAM 제한 FPGA SoC Linux 부트 가속 (vetted, 5점, T3)
