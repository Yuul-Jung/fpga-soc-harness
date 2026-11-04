# Raspberry Pi 도메인 종합

갱신: 2026-11-05 (/verify 12차). 카드 15건 기준. GPIO/SPI/I2C Python 소프트웨어·Buildroot 이미지·RT Linux·FPGA SPI 제어 호스트·카메라·비전.

## 개요

Raspberry Pi 도메인 카드 15건: GPIO/SPI/I2C Python 소프트웨어 3건 + Buildroot 최소 이미지·부트 최적화 3건 + RT Linux 3건 + FPGA SPI 제어 호스트 4건 + 카메라·비전 2건. 대부분 Linux 호스트 소프트웨어이며 `fit_basys3: needs-port`. Basys3 재사용은 "프로토콜 타이밍·CS 의미론·계층 구조, OS 이미지 최소화, RT 레이턴시 임계, SPI FPGA 버스 마스터 패턴"만 가져오며 커널 드라이버·/dev 노드는 이식 불가다.

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

### RT Linux (PREEMPT_RT 실시간 제어)

| 항목 | 카드 | 보드 | 도구 | 단계 | 한계 |
|---|---|---|---|---|---|
| RPi4/5 PREEMPT_RT 가이드 | applied-ee-rpi-realtime-linux | RPi4/5 | PREEMPT_RT 패치, isolcpus, chrt, taskset | T1 | BLDC 20kHz PWM 불가 → FPGA/MCU 필요 |
| Óbuda 대학 RT 레이턴시 측정 튜토리얼 | obuda-preempt-rt-latency-tutorial | RPi4 | cyclictest, trace-cmd, ftrace | T0 | 교육용, 측정 환경 의존성 |
| CVUT RT 모터 제어 (ppisa) | ppisa-rpi-rt-control | RPi4 | RTEMS, Simulink, IRC 엔코더 커널 드라이버 | T2 | L2(소스 미직접 열람), DC servo/PMSM/BLDC 혼합 |

### FPGA SPI 제어 호스트

| 항목 | 카드 | 보드 | CPU/버스 | 주변장치 | 한계 |
|---|---|---|---|---|---|
| iCE40 FPGA HAT for RPi (ice4pi) | lightside-instruments-ice4pi | RPi (HAT) | none(SPI/I2C slave Verilog) / SPI | comm-spi, iCE40HX-1K FPGA | L2, 라이선스 unknown |
| RPi Zero → FPGA Wishbone SPI | michalstc-rpi-zero-fpga-spi-wishbone | RPi Zero | none(Linux SPI master) / SPI | comm-spi, Wishbone | L2, 3.2 MHz SPI, 2.6 kHz 명령 처리율 |
| RP2040 SPIBone → iCEBreaker FPGA | enjoy-digital-litex-rp2040-pmod-test | iCEBreaker | none(RP2040 SPI host) / SPIBone→Wishbone | SPI-master-RP2040, SPIBone, Wishbone | iCEBreaker 전용, Basys3 포팅 필요 |
| RPi SPI master → FPGA → VGA (DE0) | rpshredow-fpga-raspberry-image-display | DE0 | none(RPi SPI master) / SPI | comm-spi, video-vga | L2, DE0 전용, 라이선스 unknown, 제3자 IP(Knuckles·SpongeBob) 주의 |

### 카메라·비전

| 항목 | 카드 | 보드 | 도구 | 단계 | 한계 |
|---|---|---|---|---|---|
| RPi CM5 YOLO11n 객체 탐지 | automaticdai-rpi-object-detection | RPi CM5 | TFLite, OpenCV, Picamera2 ZSL DMA | T3 | CM5 전용 2.1 FPS, MIT, GPU 없으면 추론 느림 |
| libcamera + OpenCV RPi4 Bullseye | qengineering-libcamera-opencv-rpi-bullseye-64os | RPi4 | libcamera, OpenCV, GStreamer | T2 | Bullseye 64-bit 전용, L2, BSD-3-Clause |

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

**RPi SPI → FPGA AXI4-Lite 버스 마스터 패턴:** RPi4 Linux spidev가 Basys3 Pmod(MOSI/MISO/CLK/CS, 3.3V)에 직결해 FPGA 내부 AXI4-Lite 슬레이브 IP를 R/W하는 구조. 프로토콜 선택지:
- airhdl SPI-to-AXI4-Lite 브리지(11바이트 프레임: 1B instr + 4B addr + 4B data + 1B dummy + 1B status) — fit_basys3=yes, Apache-2.0.
- SPIBone 프로토콜(9바이트: 1B cmd + 4B addr + 4B data) — `spibone_gen.py --mode hybrid-axi-lite`로 순수 Verilog 추출 가능.
두 패턴 모두 MicroBlaze V 없이 RPi4가 AXI4-Lite 버스 마스터가 되어 Basys3 IP를 pytest 등으로 자동 테스트하는 CI 하네스를 구성할 수 있다(내 판단, enjoy-digital-litex-rp2040-pmod-test·airhdl-spi-to-axi-bridge·ananthu-islam-ahb-apb-bridge-rpi-artix7, I-085·I-086).

**RT 레이턴시 임계:** RPi4 PREEMPT_RT에서 평균 지터 ~10 µs, 최대 50-80 µs. 1 kHz PID 루프(1 ms 주기)는 가능하나 20 kHz PWM(50 µs 주기)은 불가. 고속 PWM·엔코더 카운팅은 MicroBlaze V FPGA 측(100 kHz 이상)에서 처리하고 RPi4는 1 kHz PID 계산·목표값 송신 역할로 나누는 것이 최적(내 판단, applied-ee-rpi-realtime-linux·obuda-preempt-rt-latency-tutorial).

**CS 의미론:** `xfer()`는 각 바이트 사이에 CS 토글, `xfer2()`는 전체 전송 동안 CS 유지. Basys3 AXI SPI IP의 `MANUAL_SS` 비트 의미와 같다. 혼동하면 슬레이브가 프레임 경계를 잘못 인식한다(내 판단, doceme-py-spidev 한계·위험).

**gpiozero 핀 팩토리 패턴 → AXI IP 추상화:** gpiozero가 핀 팩토리를 교체해도 같은 API를 제공하듯, MicroBlaze V BSP에서 SPI IP 종류(AXI SPI vs AXI Quad SPI)를 바꿔도 응용 코드가 같은 HAL 인터페이스를 보도록 드라이버를 설계할 수 있다(내 판단, zbotic-rpi-gpio-stack-guide 재사용 메모).

## 교훈

- RPi SPI 최대 속도 32 MHz(BCM2835) / 실용 권장 8 MHz는 Basys3 AXI SPI IP의 `SCK_RATIO` 파라미터 선택 기준으로 사용 가능하다(abelectronics-rpi-spi-tutorial).
- xfer3()의 청크 분할(커널 버퍼 4096 바이트 한계)은 Basys3 DMA 또는 AXI Burst 연동 설계 시 버퍼 크기 결정 참조가 된다(doceme-py-spidev).
- smbus2의 `write_byte_data(addr, reg, val)` / `read_byte_data(addr, reg)` 는 AXI I2C master IP의 커맨드 레지스터 인터페이스(슬레이브 주소+레지스터 오프셋+데이터)와 동일한 의미론이다(zbotic-rpi-gpio-stack-guide).
- SPI 명령 처리율(3.2 MHz SPI에서 2.6 kHz) 한계는 AXI4-Lite 슬레이브 레이턴시 + SPI 클럭 ÷ 프레임 비트 수로 계산된다(michalstc-rpi-zero-fpga-spi-wishbone). airhdl 11바이트 프레임(88비트) 기준 8 MHz SPI에서 이론 최대 90 kHz 거래이고 실제는 Linux 스케줄링 지연으로 훨씬 낮다. 내 판단: 테스트 자동화(pytest 10~100건 거래) 용도라면 충분.
- RPi PREEMPT_RT는 1 kHz 제어 루프를 보장하나 20 kHz PWM은 불가하다. FPGA(MicroBlaze V)가 고속 주변장치를, RPi가 감시·명령을 담당하는 역할 분담이 올바른 설계 패턴이다(applied-ee-rpi-realtime-linux).

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

## FPGA SPI 제어 호스트 패턴

**RPi → FPGA 버스 마스터 구조:** RPi4(Linux spidev) 또는 RP2040(MicroPython machine.SPI)이 FPGA Pmod 헤더에 SPI 4-wire(CLK, MOSI, MISO, CS)로 직결해 FPGA 내부 버스 레지스터를 직접 R/W. 3.3V 레벨로 직결 가능.

| 프로토콜 | 프레임 | 사용 카드 | 속도 | 비고 |
|---|---|---|---|---|
| airhdl SPI-to-AXI4-Lite | 11바이트(1B+4B+4B+1B+1B) | airhdl-spi-to-axi-bridge | 최대 ~8 MHz | AXI4-Lite 직결, fit_basys3=yes |
| SPIBone | 9바이트(1B+4B+4B) | enjoy-digital-litex-rp2040-pmod-test | 최대 ~32 MHz | Wishbone/AXI-Lite 선택, spibone_gen.py |
| 비정형 SPI | 100비트 고정 | ananthu-islam-ahb-apb-bridge-rpi-artix7 | 미명시 | 범용 주소맵 접근 아님, 개념 참조용 |
| SPI Wishbone | 가변 | michalstc-rpi-zero-fpga-spi-wishbone | 3.2 MHz | 2.6 kHz 명령/s, Wishbone 한정 |

**단독 테스트 모드 패턴:** MicroBlaze V 없이 RPi4 또는 RP2040이 AXI4-Lite 버스 마스터 역할로 Basys3 슬레이브 IP를 테스트. `free_slots` 한 칸에 SPI 브리지를 AXI4-Lite 슬레이브로 등록하면 pytest에서 레지스터 R/W 자동 검증 가능. 단독 테스트 모드와 MicroBlaze V 운용 모드 사이에 AXI 인터커넥트 arbiter 추가 필요(내 판단).

## RT Linux · 모터 제어 패턴

**역할 분담 원칙** (내 판단, applied-ee-rpi-realtime-linux·obuda-preempt-rt-latency-tutorial):

| 처리 | FPGA (MicroBlaze V) | RPi4 (PREEMPT_RT) |
|---|---|---|
| PWM 생성 | 100 kHz 이상 가능 | 최대 ~1 kHz (소프트 PWM 불안정) |
| 엔코더 카운팅 | 하드 카운터, 무제한 속도 | 리눅스 GPIO 인터럽트, 고속 미지원 |
| PID 계산 | AXI4-Lite 슬레이브로 처리 가능 | 1 kHz 루프 안정적(avg 10 µs 지터) |
| 목표값 송신 | SPI 수신 | Python spidev로 목표값 주기 송신 |

**cyclictest 측정법:** `cyclictest -m -p 95 -n -h 400 -i 1000 -d 0 -l 1000000` → hist 파일에서 최악 레이턴시 확인. `trace-cmd record -e sched_switch -e irq_handler_entry` 로 원인 추적(obuda-preempt-rt-latency-tutorial).

## 카메라·비전 패턴

**Picamera2 ZSL DMA 버퍼:** Picamera2의 ZSL(Zero-Shutter-Lag) 모드는 DMA 버퍼를 직접 NumPy 배열로 넘겨 복사 없이 OpenCV/TFLite에 연결. RPi CM5에서 YOLO11n 2.1 FPS(automaticdai-rpi-object-detection). Basys3 카메라 파이프라인(OV7670→VGA) 패턴과 역할이 반대: Basys3는 HW 파이프라인, RPi는 SW 추론.

**libcamera + GStreamer 파이프라인:** `libcamera-vid | gst-launch-1.0`으로 H.264 스트리밍 가능. RPi4 Bullseye 64-bit 기준 호환(qengineering-libcamera-opencv-rpi-bullseye-64os). Basys3 재사용 없음; 개념 참조로만 사용.

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
- I-085: RPi4 Python spidev + airhdl SPI-to-AXI4-Lite → Basys3 테스트 하네스 (vetted, 6점, T2)
- I-086: spibone_gen.py AXI-Lite 출력 + Basys3 Pmod → RP2040 SPIBone (vetted, 7점, T2-T3)
