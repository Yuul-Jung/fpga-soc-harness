# 수집 주제 목록

자동 수집 모드가 위에서부터 `[ ]` 항목을 하나씩 소비한다. 끝나면 `[x]`로 바꾼다.


## 보드 등급 범례
| 태그 | 보드 | FPGA | BRAM | 외부 메모리 |
|------|------|------|------|-------------|
| `[B3]` | Basys3 | XC7A35T | 225 KB | 없음 |
| `[NA7+]` | Nexys A7 이상 | XC7A100T | 4.86 MB | DDR3 128 MB |
| `[PZ2+]` | Pynq-Z2 이상 | XC7Z020 (ARM+FPGA) | 630 KB | DDR3 512 MB |
| `[ZCU+]` | ZCU104 이상 | XCZU7EV (AI Engine) | — | DDR4 4 GB |
> 표기 없음 = 완료된 항목. 태그는 최소 요구 보드를 뜻한다.

- [x] Basys3 오디오·I2S 주변장치 (Pmod I2S2, PWM 오디오)
- [x] Basys3 SD 카드 (SPI 모드) 저장장치
- [x] Basys3 카메라 (OV7670, SCCB) 파이프라인
- [x] Basys3 PS/2·USB HID 키보드/마우스 입력
- [x] Basys3 UART/SPI/I2C 센서 허브 (Arduino 모듈 우선)
- [x] Basys3 이더넷·Bluetooth·CAN 통신 (Pmod 기반) — 2026-11-02 16:16 사이클에서 CAN·무선 카드 작성, 이더넷은 자료 부족으로 미착수
- [x] MicroBlaze/MicroBlaze V Basys3 사용자 AXI 주변장치
- [x] PicoRV32 Basys3 SoC (PicoSoC 포팅 사례) — 2026-11-02 18시대 사이클: 카드 3건(L2), raw 열람 권한 미응답으로 L3 승격은 /verify로 — 제작은 보류, 자료는 수집하고 개조 메모로 MicroBlaze V 기준에 연결 (config/project_profile.json cpu_tracks)
- [x] Intel/Altera 캡스톤: DE10-Nano·DE1-SoC 주변장치 프로젝트 — 2026-11-02 19시대 사이클: 모터 제어 중심 카드 3건(L3), Cornell 페이지 열람은 권한 미응답
- [x] Lattice iCE40/ECP5 RISC-V SoC 주변장치 — 2026-11-02 19시대 2차 사이클: RISC-V SoC 직접 자료는 열람 불가로 모터 주변장치 카드 3건 작성, SoC 자체는 큐에 남김
- [x] 한국어 FPGA 종합설계·캡스톤 보고서 — 2026-11-02 20시대 사이클: 국내 블로그형 보고서는 검색에서 못 찾아 국내 학회 논문 2건 중심, 후속 질의 필요

## 모터 제어 사다리 (A 트랙, 2026-11-02 추가, 위에서부터 소비)
- [x] 입문: Basys3 서보·DC 모터 PWM 구동과 H-브리지 모듈(TB6612, L298N, DRV8833) 인터페이스, 모터 전원 분리·역기전력 보호
- [x] 입문: 직교 엔코더 디코더 RTL(4배 해독, 입력 거르기)과 속도·위치 측정 사례 (Verilog, FPGA) — 2026-11-02 22시대 사이클: 카드 3건(L3), 엔코더 4체배 직접 Basys3 사례는 못 찾음
- [x] 중급: FPGA 정수·고정소수점 PID 속도·위치 제어 (엔코더 + PWM), 계단 응답 측정과 이득 조정 — 2026-11-02 23시대 사이클: 카드 3건(DE2 PID, 무명 Verilog PID L2, Microchip AN532), Basys3 직접 PID 사례는 못 찾음, 계단 응답 정량 자료 부족
- [x] 중급: 스텝모터 제어 FSM (28BYJ-48/ULN2003, A4988/DRV8825) 가속 곡선·원점 찾기 — 2026-11-02 마지막 사이클: 카드 3건(L3), Basys3 직접 사례와 원점 복귀 자료는 못 찾음
- [x] 고급: IMU(MPU-6050/6500) 자세 추정 상보·칼만 필터를 FPGA/소프트코어로 (I2C 읽기, 고정소수점) — 2026-11-03 02시대 사이클: 카드 3건(L3 2, L2 1), 개선 Mahony 논문은 열람 권한 미응답, Basys3 직접 사례 못 찾음
- [x] 고급: 2륜 자가 균형 로봇 (IMU + 엔코더 + PID) FPGA 구현 사례 — 2026-11-03 사이클: 카드 3건(L3 2, L2 1)+jie-2011 L2→L3, Basys3 직접 사례 못 찾음
- [x] 전문: 도립진자(Inverted Pendulum) 제어 FPGA 구현 사례 (상태 되먹임, LQR) — 2026-11-03 03시대 사이클: 카드 3건(L3 1, L2 2), Basys3 LQR 논문 본문은 robots 차단, 국내 사례 못 찾음
- [x] 전문: 적응 제어·자동 튜닝 PID (릴레이 피드백, 모델 기준 적응) 하드웨어 구현 — 2026-11-03 04시대 사이클: 카드 3건(L3 2, L2 1), 릴레이 FPGA 직접 구현·MRAC 하드웨어 사례는 못 찾음
- [x] 최상: BLDC/PMSM 홀센서·FOC 입문 FPGA 구현 (3상 PWM, 전류 센싱, 데드타임) — 2026-11-03 사이클: 카드 3건(L3 2, L2 1), Basys3 직접 사례와 FpOC SHA는 못 찾음/unverified
- [x] 입출력 조합: 마이크·가속도·카메라 입력 + 도트 매트릭스(MAX7219)·음성(DFPlayer)·영상 출력 모듈 조합 사례 — 2026-11-03 사이클: 카드 3건(L3), Verilog MAX7219·DFPlayer FPGA 직접 사례와 카메라 조합은 못 찾음, DFPlayer 프레임 명세는 데이터시트 열람 필요
- [x] CPU 중립화 개조: PicoRV32·VexRiscv·NEORV32 SoC의 주변장치 레지스터·인터럽트·부트 흐름 중 AXI4-Lite IP 표준 래퍼로 옮길 수 있는 부분 (전략 S1) — 2026-11-03 07시대 사이클: 카드 3건(NEORV32 L2, Basys3 강의 L3, PicoRV32 L2), 원본 저장소·LICENSE 직접 열람 못 함, VexRiscv는 미착수

## 빈 곳 보충 (2026-11-03 §12.2-3, 위에서부터 소비)
- [x] 이더넷: Arduino 호환 SPI 이더넷 모듈(ENC28J60, W5500)과 Pmod NIC100을 Basys3에서 구동하는 UDP/ARP 사례 (comm-eth 카드 0건) — 2026-11-03 08시대 사이클: 카드 3건(L3), W5500·Pmod NIC100 중심, ENC28J60 Verilog 직접 사례와 Basys3 W5500 사례는 못 찾음, Pmod-NIC100 저장소 카드는 큐
- [x] 영상 제약 역전: 프레임 버퍼 없는 VGA 라인 버퍼 스트리밍·타일맵 (video-vga, S4, no-dram) — 2026-11-03 09시대 사이클: 카드 3건(L3), Basys3 직접 타일/라인 버퍼 사례와 raybox SHA·라이선스는 못 찾음/unverified
- [x] 서보 액추에이터 조합: 서보 PWM IP와 입력 장치(조이스틱·XADC·카메라) 연동 로봇팔 사례 (actuator-servo) — 2026-11-03 사이클: 카드 3건(L3), Basys3 조이스틱 서보 직접 사례와 서보 PWM RTL 저장소는 못 찾음, 카메라 연동은 UAlberta 사례를 큐에

## 빈 곳 보충 2 (2026-11-03 §12.2-3, 위에서부터 소비)
- [x] 디스플레이 사다리: HD44780 LCD1602 → SSD1306 OLED(SPI/I2C) → ST7789 SPI 컬러 LCD 구동 FSM (display 카드 0건, S7) — 2026-11-03 11시대 사이클: 카드 3건(L3), Basys3 직접 사례와 I2C 백팩 FPGA 사례는 못 찾음, HD44780 두 글은 큐에 남김
- [x] 1-wire 온도 센서(DS18B20)·DHT11 단선 프로토콜 FSM과 Basys3 구현 (devices/1-wire 비어 있음) — 2026-11-03 사이클: 카드 3건(L3 2, L2 1)+devices/1-wire/ds18b20.md, DHT11 FSM 직접 자료는 열람 못 함(Dibya·Elich PDF 열람 불가), Basys3 직접 사례 못 찾음
- [x] Bluetooth HC-05/HC-06 UART 브리지: AT 설정과 FPGA 텔레메트리 — 2026-11-03 13시대 사이클: 카드 3건(L3), Basys3 HC-05 직접 사례와 제조사 데이터시트는 못 찾음/unverified, 보조 devices/bluetooth/hc-05.md(L2)

## 빈 곳 보충 3 (2026-11-03 §12.2-3, 위에서부터 소비)
- [x] Basys3 XADC 아날로그 센서 입력(가변저항·조이스틱·조도, 0~1 V 앞단) — 2026-11-03 14시대 사이클: 카드 3건(L3), 센서 모듈(LM35·조도)과 Basys3 직접 응용 사례는 못 찾음, UG480 원문은 일부만 열람
- [x] I2C 시계·메모리(DS3231 RTC, 24LC EEPROM) 마스터 FSM과 Basys3 사례 (devices/i2c 비어 있음, S3) — 2026-11-03 15시대 사이클: 카드 3건(L3)+devices/i2c/ds3231.md, Basys3 직접 사례와 DS3231 Verilog 직접 사례는 못 찾음, I2C 마스터 저장소 3건은 큐(L1)
- [x] IR 리모컨(NEC 프로토콜) 수신 디코더 FSM과 로봇 조종 조합 (HID 계열, S2) — 2026-11-03 16시대 사이클: 카드 3건(L3), Basys3 직접 사례와 반복 코드 구현·로봇 조종 조합 자료는 못 찾음, OpenCores 코어는 코드 미열람

## Arduino 도메인 (2026-11-03 추가, 위에서부터 소비)
- [x] Arduino 모터 제어: TB6612FNG/L298N H-브리지 + 엔코더 PID 속도 제어 (아두이노 생태계 우선) — 2026-11-03 17시대 사이클: 카드 3건(L3, catalog/arduino/ 신설), L298N 엔코더 PID 자료는 열람 못 함(큐), 정수·고정소수점 PID AVR 사례는 못 찾음
- [x] Arduino 통신 모듈: HC-05 BT 앱 제어, NRF24L01 무선, LoRa SX1278 기초 — 2026-11-03 사이클: 카드 3건(L3: nRF24 튜토리얼, SX1278 2건), HC-05는 기존 카드 활용, nRF24·LoRa FPGA 직접 구현과 SX1278 데이터시트·레지스터 자료는 못 찾음/미열람
- [x] Arduino 센서 허브: MPU-6050 IMU + BMP280 기압 + GPS NEO-6M 조합 사례 — 2026-11-03 사이클: 카드 3건(L3), devices/i2c/bmp280.md, Basys3·FPGA BMP280/NEO-6M 직접 Verilog 사례는 못 찾음, Digilent GPS 토론·tor1kk/neo-6m은 큐
- [x] Arduino 디스플레이: SSD1306 OLED + ST7789 SPI LCD + MAX7219 매트릭스 구동 — 2026-11-03 20시대 사이클: 카드 3건(L3: OLED 실패 사례 2, MAX7219 튜토리얼 1), ST7789 Arduino 직접 자료는 열람 못 함(기존 FPGA 카드로 대체), MAX7219 레지스터 맵은 데이터시트 필요
- [x] Arduino 캡스톤급: 자율주행 RC카·로봇 팔·스마트 홈 제어 시스템 완성 프로젝트 — 2026-11-03 21시대 사이클: 카드 3건(L3: 가르치기 로봇 팔, 장애물 회피 차, IR+회피 차), 스마트 홈 완성 프로젝트와 국내 보고서는 열람 못 함/큐, 카드의 코드는 반입 안 함
- [x] Arduino FPGA 연동: 아두이노 모듈을 Basys3 Pmod와 연결하는 인터페이스 변환 사례 — 2026-11-03 22시대 사이클: 카드 3건(L3), Arduino↔Basys3 직접 변환 어댑터 사례와 Basys3 Pmod 5V 허용치 공식 수치는 못 찾음(Basys3 레퍼런스 페이지에 전기 사양 없음)

## STM32 도메인 (2026-11-03 추가, 위에서부터 소비)
- [x] STM32 HAL 기초: GPIO/UART/SPI/I2C HAL 드라이버 구조와 큐브MX 코드 생성 — 2026-11-04 01시대 사이클: 카드 3건(L3: CubeMX 생성 코드 구조, HAL vs LL 2건), SPI/I2C HAL 개별 드라이버 자료와 ST 공식 UM1725는 못 찾음/미열람
- [x] STM32 FreeRTOS: 태스크·큐·세마포어·타이머, CMSIS-RTOS v2 래퍼 사례 — 2026-11-04 사이클: 카드 3건(L3: 스택 오버플로 폴트, HAL 타임아웃·SysTick, UART 설계 스레드), ST FAQ는 CMSIS-RTOS v2 내용 없음, 래퍼 공식 문서·타이머 자료는 못 찾음
- [x] STM32 모터 제어: TIM PWM + 엔코더 모드 + FOC 기초 (G0/G4/F4 계열) — 2026-11-04 03시대 사이클: 상보 PWM·데드타임·FOC 카드 3건(L3 2, L2 1), G0/G4 CORDIC·FMAC 자료와 FOC 저장소 SHA는 미착수
- [x] STM32 통신: CAN FD, USB CDC, Ethernet LwIP, BLE(WB55) 통합 사례 — 2026-11-04 04시대 사이클: 카드 3건(L3: FDCAN 8 Mb/s, USB CDC 송신 정지, LwIP UDP 에코), BLE WB55는 큐(L1), ST 공식 매뉴얼·CAN FD 파형 자료는 못 찾음/미열람
- [x] STM32 캡스톤급: 드론 FC, 산업용 PLC 대체, 로봇 조인트 제어 완성 프로젝트 — 2026-11-04 05시대 사이클: 카드 3건(L3 2, L2 1: stm32flight, FeroFlyF405, 서보 6축 팔), PLC 대체·엔코더 관절 폐루프 사례는 못 찾음, Pulse FC·ArduPilot 지터 스레드는 큐

## ESP32 도메인 (2026-11-03 추가, 위에서부터 소비)
- [x] ESP32 Wi-Fi + MQTT: MQTT 브로커 연결, OTA 업데이트, 전력 절약 딥슬립 — 2026-11-03 사이클: 카드 3건(L3: DHT→MQTT 딥슬립 블로그, Espressif OTA 프레임워크, Espressif MQTT FAQ), 딥슬립 전류 가이드는 큐(L3 열람·카드 미작성), 브로커 연결 TLS·실측 전력 자료는 못 찾음/unverified
- [x] ESP32 BLE: GATT 서버·클라이언트, BLE Mesh, 비콘 스캐너 — 2026-11-04 07시대 사이클: 카드 3건(L3: GATT 서버 워크스루, 비콘 스캐너, BLE Mesh), GATT 클라이언트·iBeacon 직접 비교·BLE5.x 자료는 못 찾음
- [x] ESP32 FreeRTOS + 멀티코어: Core0/1 핀닝, Task Watchdog, Inter-Core 통신 — 2026-11-04 사이클: 카드 3건(L3), Ring Buffer·IPC·TWDT 카드 작성, esp32.com 포럼·최신 WDT v5.4 문서는 열람 차단(PROVENANCE_REQUIRED), Arduino 포럼 S6 실패 사례 활용
- [x] ESP32 카메라·오디오: ESP32-CAM OV2640 스트리밍, I2S 마이크·스피커 (MAX98357) — 2026-11-04 09시대 사이클: 카드 3건(L3: espressif-esp32-camera, nopnop2002-esp-idf-websocket-camera, randomnerdtutorials-esp32-inmp441-i2s), rzeldent·Neumi PROVENANCE_REQUIRED 차단, MAX98357 스피커 카드 미작성(큐에 적재)
- [x] ESP32 엣지 AI: TFLite Micro 제스처·키워드 인식, ESP-IDF AI 예제 캡스톤 — 2026-11-04 10시대 사이클: 카드 3건(L3: zediot 키워드, alibukharai ESP-DL 제스처, espressif-esp-tflite-micro), 소스 코드 없는 기사 위주라 정량 수치 미검증, 실시간 추론 사례 없음

## Raspberry Pi 도메인 (2026-11-03 추가, 위에서부터 소비)
- [x] RPi GPIO: pigpio/gpiozero 기초, SPI/I2C 커널 드라이버와 Python 바인딩 — 2026-11-04 11시대 사이클: 카드 3건(L3: doceme-py-spidev, zbotic 스택 가이드, abelectronics SPI 튜토리얼), pigpio 공식 문서·gpiozero GitHub는 PROVENANCE_REQUIRED로 열람 불가, 아이디어 3건(I-048~I-050, raw)
- [x] RPi 카메라 파이프라인: Picamera2 + libcamera, OpenCV 실시간 영상 처리 — 2026-11-04 12시대 사이클: 카드 3건(L3: automaticdai-rpi-object-detection, fpgadeveloper-rpi-camera-fmc, chili-chips-ba-openeye-camsi), Picamera2 공식 PDF·libcamera API 가이드는 큐에 남김, 아이디어 3건(I-051~I-053)
- [x] RPi 실시간성: PREEMPT_RT 패치, isolcpus, 사이클릭 테스트 (모터 제어 목표) — 2026-11-04 13시대 사이클: 카드 3건(L3 2, L2 1), ppisa README 열람 불가(blocked), CVUT rtime.ciirc 페이지 blocked
- [x] RPi FPGA 연동: RPi SPI/I2C로 FPGA 제어, AXI 스트림 데이터 전송 사례 — 2026-11-04 14시대 사이클: 카드 3건(L3 1, L2 2), RPi→FPGA SPI 직접 사례(ice4pi, hackster), SPI IP 라이브러리, 아이디어 3건
- [x] RPi OS 프로젝트: Buildroot 최소 이미지, 부트 시간 최적화, 임베디드 배포 — 2026-11-04 15시대 사이클: 카드 3건(L3: sujan-coder-buildroot-linux-rpi3·obuda-buildroot-mini-linux-tutorial·smartmechatronics-embedded-linux-boot-time-reduction), romainreignier/minimal_raspberrypi_buildroot blocked(PROVENANCE_REQUIRED), 아이디어 3건(I-058~I-060)

## 임베디드 공통 도메인 (2026-11-03 추가, 위에서부터 소비)
- [x] RTOS 비교: FreeRTOS vs Zephyr vs ThreadX — 태스크 모델·메모리·포팅 난이도 — 2026-11-04 16시대 사이클: 카드 3건(L3 1·L2 2), 큐 등록 5건, ezurio·promwad·iiot-world 비교 기사, 태스크 오버헤드 수치는 미확인
- [x] 프로토콜 심화: CAN FD 프레임 구조, MODBUS RTU/TCP, EtherCAT 기초
- [x] 디버그 기법: JTAG/SWD 트레이스, OpenOCD, Segger RTT, 논리 분석기 활용 — 2026-11-04: 카드 3건(meiniki-logip L3·lekgolo167-enxor-logic-analyzer L3·enjoy-digital-litescope L2), 큐 등록 7건, S6+S4 전략
- [x] 펌웨어 OTA: MCUboot 부트로더, 이중 파티션 업데이트, 서명 검증
- [x] 안전 기능: MISRA C, 워치독, 스택 카나리, CRC 검사, FMEA 예시 — 2026-11-04: 카드 3건(L3), openMSP430 워치독 Verilog·HEIA-FR Zephyr 스택 보호·TUM IEC 61508 강의, 큐 8건, 아이디어 2건, S7 난이도 사다리+S1 인접 도메인 이식 전략

## 전자기술 도메인 (2026-11-03 추가, 위에서부터 소비)
- [x] 모터 드라이버 회로: H-브리지 MOSFET 선택·게이트 드라이버·데드타임·역기전력 보호 — 2026-11-04 사이클: 카드 3건(L3: zbotic-backem-flyback-protection, industrialmonitordirect-irs2110-half-bridge, lcsc-mosfet-selection-motor-control), 큐 8건
- [x] 전력 공급: DC-DC 벅/부스트 컨버터 설계, LDO vs 스위칭 레귤레이터 선택 기준 — 2026-11-04 사이클에서 완료(catalog/electronics/ 카드 3건: altium LDO vs switching, wevolver 벅 설계 가이드, vishay FPGA 전원 애플리케이션 노트)
- [x] 인버터 기초: 단상 풀브리지 SPWM, 게이트 격리(포토커플러/게이트 드라이버 IC)
- [x] [B3] 센서 신호 처리: ADC 입력 필터링, 차동 증폭, 홀 전류 센서 보정
- [ ] [B3] PCB 설계 체크리스트: 전류 경로, GND 플레인 분리, EMC 디커플링, 레이아웃 규칙

## 도메인 보충 4 (2026-11-03 §12.2-3: stm32/esp32/rpi/embedded/electronics 카드 0건, 위에서부터 소비)
- [x] STM32 모터 제어: 타이머 엔코더 모드 + PWM + PID (HAL/LL) 사례와 FPGA 엔코더/PWM IP 레지스터로의 개조 (stm32 카드 0건, S3) — 2026-11-03 23시대 사이클: 카드 3건(L3), catalog/stm32/ 신설, PID 이득·샘플 주기 공개 자료와 LL 드라이버 직접 자료는 못 찾음, mbed 32비트 확장은 리다이렉트로 열람 못 함
- [x] ESP32 센서 허브: Wi-Fi/BLE 텔레메트리 + FreeRTOS 센서 태스크, Basys3 UART 브리지 조합 (esp32 카드 0건) — 2026-11-03 사이클: 카드 3건(L3, esp32 신설 2건+ICE-V Wireless), Basys3 직접 ESP32 브리지 사례와 소스·SHA 열람은 못 함, 큐에 tinytapeout Basys3 UART 링크 등 후보
- [ ] [B3] Raspberry Pi GPIO/SPI 호스트로 Basys3 주변장치 IP를 제어·시험하는 사례 (rpi 카드 0건)
- [x] 모터 드라이버 회로: H-브리지 MOSFET 선택·게이트 드라이버·데드타임·역기전력 보호 — 2026-11-04 사이클: IRS2110 게이트 드라이버·역기전력 보호·MOSFET 선택 카드 3건(L3), catalog/electronics/ 신설

## Basys3 직접 확장 (2026-11-04 추가)
- [ ] [B3] Basys3 7세그 멀티플렉서 고급 활용 (밝기 PWM 제어, 소수점, 깜박임, 자리별 독립 제어)
- [ ] [B3] Basys3 스위치/버튼 디바운스 FSM + 긴 누름 감지 + 멀티 클릭 패턴
- [ ] [B3] Basys3 DMA 패턴 (BRAM 자동 전송, 인터럽트 없는 폴링, 스캐터-개더 기초)
- [ ] [B3] Basys3 하드웨어 타이머 IP (비교 출력, 캡처 입력, 오버플로 인터럽트, 원샷·주기 모드)

## 통신 프로토콜 확장 (2026-11-04 추가)
- [ ] [B3] SPI 슬레이브 모드 FSM (Basys3가 슬레이브로 동작, 마스터 시뮬레이터 테스트벤치)
- [ ] [B3] I2C 멀티마스터·중재 로직 (버스 충돌 감지, 클럭 스트레칭)
- [ ] [B3] CRC 체크섬 하드웨어 계산기 (CRC-8/CRC-16/CRC-32, 병렬 테이블 방식)
- [ ] [B3] UART 프레이밍 프로토콜 (헤더+길이+페이로드+체크섬, 슬립 디텍트 오토 보레이트)

## 디스플레이·영상 확장 (2026-11-04 추가)
- [ ] [B3] VGA 더블 버퍼링 (BRAM 2개 핑퐁, 테어링 없는 프레임 전환)
- [ ] [B3] PWM 기반 RGB LED 색상 혼합 (감마 보정, HSV→RGB 변환 하드웨어)
- [ ] [B3] 7세그 + VGA 동시 표시 조합 (공유 데이터 버스, 우선순위 멀티플렉서)

## 시스템·아키텍처 (2026-11-04 추가)
- [ ] [B3] 인터럽트 컨트롤러 IP (우선순위 인코더, 마스크 레지스터, 벡터 테이블, AXI4-Lite 접속)
- [ ] [B3] AXI4-Lite 슬레이브 레지스터 파일 템플릿 (읽기/쓰기 스트로브, 주소 디코더 패턴)
- [ ] [B3] Watchdog 타이머 고급 패턴 (윈도우 WDT, 하트비트 핀 출력, 카운트다운 가시화)
- [ ] [B3] AXI Interconnect 베이스 주소 충돌 회피 패턴 (동결 맵, 주소 레인지 계산, 테스트벤치)

## SoC 통합 준비 (2026-11-04 추가)
- [ ] [B3] MicroBlaze V SoC 주변장치 등록 절차 (xparameters.h 자동 생성, BSP 빌드, 소프트웨어 드라이버 연결)
- [ ] [B3] 여러 AXI IP 동시 구동 타이밍 분석 (버스 경합, 레이턴시 측정, 성능 카운터)

## NPU 설계 테크트리 — Basys3 기반 (2026-11-04 추가, 위에서부터 소비)

### 입문: 수치 기초
- [ ] [B3] 고정소수점 수 체계: Q포맷(Q8.8, Q4.12), 포화 연산, 반올림 모드, Verilog 구현 패턴
- [ ] [B3] 행렬·벡터 내적 하드웨어 (MAC 어레이 1×N, 파이프라인 레이턴시, BRAM 가중치 적재)

### 중급: 기본 추론 블록
- [ ] [B3] MLP 추론 가속기: 완전연결층 순전파, ReLU/Sigmoid 근사, 2층 고정소수점 네트워크 (Basys3 LUT·BRAM 범위 내)
- [ ] [B3] CNN 컨볼루션 엔진: 3×3 커널 슬라이딩 윈도우, 라인 버퍼, MaxPooling (소형 특징 맵 기준)
- [ ] [B3] 활성화 함수 하드웨어: ReLU·LeakyReLU·GELU·Sigmoid·Tanh 근사 비교 (룩업 테이블 vs 다항식)
- [ ] [B3] 배치 정규화·층 정규화 하드웨어 근사 (스케일·오프셋 고정소수점 적용)

### 고급: 시퀀스 처리
- [ ] [B3] RNN 셀 하드웨어: 단순 RNN / LSTM 셀 순전파 (상태 레지스터, 게이트 MAC, 타임스텝 루프)
- [ ] [B3] GRU 셀 대 LSTM 셀 비교 구현: 게이트 수·BRAM 사용량·정확도 트레이드오프 (Basys3 자원 제약 분석)
- [ ] [B3] 어텐션 메커니즘 하드웨어 기초: Q·K·V 내적 스코어, Softmax 근사, 스케일된 닷-프로덕트 (소형 헤드 1개)
- [ ] [B3] 트랜스포머 블록 하드웨어 슬림화: 멀티헤드 어텐션 1~2헤드, FFN 1층, Basys3 자원 한계 내 구현 가능성 분석

### 전문: NPU 시스템 통합
- [ ] [B3] 소형 NPU SoC 설계: MicroBlaze V + AXI4-Lite NPU IP (가중치 로드, 추론 트리거, 결과 읽기 레지스터)
- [ ] [B3] 엣지 AI 추론 파이프라인: 카메라(OV7670) → CNN 특징 추출 → MLP 분류 → LED/VGA 출력 (전체 데이터 흐름)
- [ ] [B3] 양자화 인식 훈련과 하드웨어 배포: INT8/INT4 가중치, 스케일 팩터 AXI 레지스터, 정밀도 손실 측정
- [ ] [B3] 하드웨어 소프트맥스·아르그맥스: 지수 근사(Mitchell), 분류 출력 인터페이스, 10클래스 분류 데모

### 캡스톤급 NPU 과제
- [ ] [B3] NPU 캡스톤 T1: Basys3 MLP 가속기 — MNIST 추론 (784→128→10, 고정소수점, 정확도 ≥90%)
- [ ] [B3] NPU 캡스톤 T2: Basys3 CNN 가속기 — CIFAR-10 소형 모델 컨볼루션층 1~2개, 특징 맵 VGA 표시
- [ ] [B3] NPU 캡스톤 T3: Basys3 어텐션 블록 — 감성 분류 1헤드 트랜스포머, 직렬 토큰 입력(UART), 결과 출력
- [ ] [B3] NPU 캡스톤 T4: 엣지 AI 통합 — OV7670 카메라 → 소형 CNN → 실시간 제스처/물체 인식 → LED 표시


## NPU 캡스톤 확장 — 추론 엔진 다양화 (2026-11-04 추가)

### 하드웨어 최적화 계열
- [ ] [B3] NPU 캡스톤: 시스톨릭 어레이 설계 — 2×2→4×4 MAC 그리드, 데이터 흐름(웨이트 스테이셔너리 vs 아웃풋 스테이셔너리), 처리량 측정
- [ ] [B3] NPU 캡스톤: 희소 행렬 가속기 — 0 가중치 스킵(CSR 포맷), 연산 절약 측정, 밀집 대비 LUT/사이클 비교
- [ ] [B3] NPU 캡스톤: 파이프라인 추론 엔진 — 컨볼루션→풀링→FC 3단 파이프라인, 스테이지 레이턴시 균형, 처리율 최대화
- [ ] [B3] NPU 캡스톤: 혼합 정밀도 추론 — 가중치 INT4/INT8, 활성화 INT8/FP16 혼합, 자리수 오버플로 감지·보정
- [ ] [B3] NPU 캡스톤: 메모리 대역폭 최적화 — 타일링(tiling) 기법, BRAM 이중 포트 활용, 오프칩 접근 최소화 패턴
- [ ] [B3] NPU 캡스톤: 하드웨어 소프트맥스 최적화 — 로그-합-지수 근사, 오버플로 방지 최대값 차감, 1/N 나눗셈 대안

### 네트워크 아키텍처 계열
- [ ] [B3] NPU 캡스톤: 깊이별 분리 컨볼루션(Depthwise Separable Conv) — MobileNet 구조 하드웨어 슬림화, Basys3 LUT 절약 측정
- [ ] [B3] NPU 캡스톤: 잔차 연결(Residual Connection) 하드웨어 — 덧셈 경로 버퍼, 1×1 보틀넥 컨볼루션, ResNet 소형 블록 1개
- [ ] [B3] NPU 캡스톤: 임베딩 레이어 하드웨어 — 단어 인덱스 → 벡터 BRAM 룩업, 어휘 크기 64~256, 임베딩 차원 8~16
- [ ] [B3] NPU 캡스톤: 위치 인코딩 하드웨어 — 사인/코사인 위치 임베딩 근사, 룩업 테이블 방식, 트랜스포머 입력 전처리
- [ ] [B3] NPU 캡스톤: 자기회귀 추론 엔진 — 토큰 1개씩 순차 생성(KV 캐시 소형), UART 출력, 간이 언어 모델 디모

### 응용 도메인 계열
- [ ] [B3] NPU 캡스톤: 음성 활성화 감지(KWS) — 간단한 MFCC 계산 하드웨어 + MLP 분류, "예/아니오" 2클래스, 마이크 ADC 입력
- [ ] [B3] NPU 캡스톤: 이상 탐지 가속기 — 오토인코더(AE) 추론, 재구성 오류 임계 비교, 센서 데이터 정상/이상 판별
- [ ] [B3] NPU 캡스톤: 강화학습 정책 추론 — Q-테이블 또는 소형 DQN 정책망 순전파, 상태 입력(스위치) → 행동 출력(LED)
- [ ] [B3] NPU 캡스톤: 시계열 이상 탐지 — LSTM 오토인코더 추론, 슬라이딩 윈도우 입력, XADC 센서 연동
- [ ] [B3] NPU 캡스톤: 포즈 추정 기초 — 2D 키포인트 히트맵 디코더, 아르그맥스 위치 계산, VGA 오버레이 표시
- [ ] [B3] NPU 캡스톤: 광학 문자 인식(OCR) 하드웨어 — 7×5 비트맵 숫자 → CNN → 10클래스 분류, VGA 디버그 오버레이

### 벤치마킹·분석 계열
- [ ] [B3] NPU 캡스톤: 추론 성능 프로파일러 — 사이클 카운터 AXI 레지스터, 레이어별 레이턴시 측정, UART 보고
- [ ] [B3] NPU 캡스톤: 정확도 vs 자원 트레이드오프 분석 — 비트 폭(4/8/16) 별 Vivado 합성 LUT·BRAM·주파수 비교표
- [ ] [B3] NPU 캡스톤: 에너지 효율 추정기 — 사이클당 연산(TOPS/W 추정), Vivado 전력 보고 파싱, AXI 성능 카운터 조합
- [ ] [B3] NPU 캡스톤: 하드웨어 vs 소프트웨어 추론 비교 — MicroBlaze V C 추론과 HW 가속기 사이클 대조, 가속 비율 측정

### SoC 통합 계열
- [ ] [B3] NPU 캡스톤: DMA 기반 가중치 로더 — DDR 없이 BRAM 멀티뱅크 순환 로드, AXI Stream 버스트 전송
- [ ] [B3] NPU 캡스톤: 인터럽트 기반 추론 완료 통지 — MicroBlaze V ISR, 폴링 대비 레이턴시 측정, 멀티 IP 이벤트 조정
- [ ] [B3] NPU 캡스톤: 다중 추론 태스크 스케줄러 — 우선순위 큐, 레이어 단위 인터리빙, 공유 MAC 어레이 중재
- [ ] [B3] NPU 캡스톤: 온칩 학습 기초 (온라인 미세 조정) — 고정소수점 SGD 1스텝, 가중치 업데이트 레지스터, 오버피팅 위험 측정

### 엣지 AI 통합 캡스톤 (최상급)
- [ ] [NA7+] NPU 캡스톤 T5: 완전 엣지 AI SoC — MicroBlaze V + NPU IP + 카메라 + 마이크 + VGA, 복합 멀티모달 추론
- [ ] [B3] NPU 캡스톤 T6: TinyML 호환 추론 엔진 — TensorFlow Lite 양자화 모델(.tflite) 가중치를 BRAM에 적재, 고정 연산자 집합 실행
- [ ] [B3] NPU 캡스톤 T7: 연합 학습(Federated Learning) 하드웨어 시뮬레이션 — 복수 클라이언트 모델 평균 계산기, AXI 집계 레지스터
- [ ] [B3] NPU 캡스톤 T8: 뉴로모픽 스파이킹 뉴럴 네트워크(SNN) 기초 — LIF 뉴런 FSM, 스파이크 버스, 시간 코딩 패턴, Basys3 LED 시각화


## NPU + 암호 처리 테크트리 (2026-11-04 추가)

### 대칭키 암호 하드웨어
- [ ] [B3] AES-128 암호화 엔진: SubBytes·ShiftRows·MixColumns·AddRoundKey 하드웨어, 10라운드 파이프라인, Basys3 LUT 측정
- [ ] [B3] AES-256 CBC/CTR 모드: 초기화 벡터 레지스터, 연쇄 블록 XOR, 스트림 암호 변환
- [ ] [B3] ChaCha20 스트림 암호: 32비트 쿼터라운드 FSM, 20라운드 언롤링 vs 반복 비교, 소프트코어 대비 속도

### 해시·무결성
- [ ] [B3] SHA-256 해시 엔진: 메시지 스케줄, 64라운드 압축, 패딩 처리, UART 출력 테스트벤치
- [ ] [B3] HMAC-SHA256: 키 패딩, ipad/opad XOR, 2회 해시 체인, AXI4-Lite 레지스터 인터페이스
- [ ] [B3] CRC-32 + SHA-256 비교: 오류 검출용 CRC와 보안용 해시 목적 차이, 처리율·LUT 대조

### 공개키·키 교환 기초
- [ ] [B3] RSA 모듈러 지수 연산 하드웨어: Montgomery 곱셈, 슬라이딩 윈도우 지수, 512비트 기준 사이클 측정
- [ ] [B3] ECC(타원 곡선) 점 덧셈 하드웨어: Weierstrass 곡선, 프로젝티브 좌표, 고정소수점 모듈러 산술
- [ ] [B3] Diffie-Hellman 키 교환 시뮬레이션: 하드웨어 모듈러 거듭제곱, UART로 공개값 교환 데모

### 난수·키 생성
- [ ] [B3] 진엔트로피 난수 생성기(TRNG): XADC 열잡음 샘플링, Von Neumann 디바이어싱, NIST 통계 테스트
- [ ] [B3] 의사난수 생성기(PRNG): LFSR(최대주기 다항식), Xorshift32/64, 출력 분포 균일성 검증
- [ ] [B3] PUF(물리적 복제 불가 함수): Arbiter PUF / Ring Oscillator PUF, Basys3 LUT 비율 편향 측정, 디바이스 핑거프린트

### 보안 프로토콜 하드웨어 지원
- [ ] [B3] AES-GCM 인증 암호화: GCM 갈루아 필드 곱셈기, 태그 생성, 복호화+태그 검증 일체형 IP
- [ ] [B3] TLS 1.3 하드웨어 지원 블록: HKDF 키 파생(HMAC 기반), AES-GCM 레코드 암호화, 핸드셰이크 보조 IP
- [ ] [B3] 보안 부트 검증기: 펌웨어 SHA-256 해시 비교, BRAM 적재 전 무결성 확인, 불일치 시 MicroBlaze V 정지

### NPU + 암호 통합 (보안 추론)
- [ ] [B3] 모델 가중치 AES 암호화 보호: BRAM 적재 전 복호화, 키 레지스터 쓰기 전용 잠금, 평문 노출 방지
- [ ] [B3] 추론 결과 서명: SHA-256 출력 해시 → HMAC 태그 생성, 결과 위변조 감지 데모
- [ ] [NA7+] 동형 암호 기초 하드웨어: BFV/CKKS 스킴 덧셈 연산, 다항식 링 덧셈, 암호화 상태 추론 가능성 탐색
- [ ] [B3] 차분 프라이버시 하드웨어 노이즈 추가기: 라플라스/가우시안 노이즈 TRNG 기반 생성, 추론 출력에 적용
- [ ] [B3] 암호화 가속기 벤치마크: AES vs ChaCha20 vs SHA-256 처리율·LUT·전력 3자 비교, MicroBlaze V 소프트웨어 대비

### 사이드채널 공격 방어
- [ ] [B3] 타이밍 공격 방지 상수시간 비교기: 비밀 의존 분기 제거, 마스킹 XOR 체인, 실행 시간 균일성 측정
- [ ] [B3] 전력 분석 공격(SPA/DPA) 대응: 랜덤 마스킹 AES 1차 마스킹 구현, 소비 전력 균일화 패턴
- [ ] [B3] 오류 주입 감지기: 중복 연산 비교, 체크섬 자기 검증, 불일치 시 출력 무효화 FSM


## DSP 신호처리 테크트리 — Basys3 기반 (2026-11-04 추가)
> 대분류: 디지털 신호 처리 (DSP) | 단계: 기초→중급→고급→SoC 통합

### 01. 센서 샘플링과 ADC
- [ ] [B3] DSP-01: 샘플링 이론 하드웨어 — 나이퀴스트 주파수, XADC 샘플링 클럭 분주기, 샘플 주파수 가변 레지스터, 오실로스코프 모드 VGA 출력
- [ ] [B3] DSP-01: 양자화 오차 측정 — XADC 12비트 출력 vs 8/4비트 절삭 비교, 양자화 잡음 SNR 계산 하드웨어
- [ ] [B3] DSP-01: 에일리어싱 시뮬레이터 — 테스트벤치 내 합성 신호 오버샘플→다운샘플, 폴딩 주파수 검출, 7세그 주파수 표시

### 02. 기초 필터
- [ ] [B3] DSP-02: 이동평균 필터(MA) — N탭 슬라이딩 윈도우(N=4/8/16/32), BRAM 순환 버퍼, AXI4-Lite 탭 수 가변
- [ ] [B3] DSP-02: 중앙값 필터(Median) — 버블 정렬 하드웨어 N=3/5/7, 파이프라인 단계, 임펄스 잡음 제거 테스트벤치
- [ ] [B3] DSP-02: 지수이동평균(EMA) — 고정소수점 α 계수, 단일 곱셈·덧셈 1사이클, 여러 α 비교 주파수 응답

### 03. FIR / IIR 필터
- [ ] [B3] DSP-03: FIR 필터 설계 — Windowed-Sinc 계수 생성(Python→COE), 직접형-I 하드웨어, 저역/고역/대역 선택 레지스터
- [ ] [B3] DSP-03: FIR 다중 탭 최적화 — 대칭 계수 반절 연산 절감, DSP48E1 활용, 탭 수 대 LUT/DSP 트레이드오프 측정
- [ ] [B3] DSP-03: IIR 바이쿼드(Biquad) — 직접형-II 전치, 2차 섹션 1개, Q포맷 스케일링, 불안정 조건 테스트
- [ ] [B3] DSP-03: IIR vs FIR 비교 캡스톤 — 같은 차단 주파수, LUT·DSP·레이턴시·위상 선형성 대조표, VGA 주파수 응답 그래프

### 04. 고정소수점 수치 계산
- [ ] [B3] DSP-04: Q포맷 체계 하드웨어 — Q8.8·Q4.12·Q2.14 변환기, 포화 가산기, 오버플로 플래그 AXI 레지스터
- [ ] [B3] DSP-04: 고정소수점 나눗셈·제곱근 — 복원 감산 나눗셈 FSM, Newton-Raphson 제곱근 근사, 사이클 수 측정
- [ ] [B3] DSP-04: 고정소수점 삼각함수 근사 — CORDIC 알고리즘(회전 모드), sin/cos 동시 출력, 오차 측정 테스트벤치
- [ ] [B3] DSP-04: 수치 안정성 테스트 패턴 — 극값 입력(최대·최솟값·0·NaN 경계), 포화·언더플로 처리 자동화 TB

### 05. MAC / DSP48E1 활용
- [ ] [B3] DSP-05: DSP48E1 프리미티브 직접 제어 — P=A*B+C 단일 사이클, 캐스케이드 체인, Vivado 속성 고정, 합성 추출 확인
- [ ] [B3] DSP-05: 파이프라인 MAC 어레이 — 4·8·16탭 FIR DSP48E1 매핑, 클럭당 1샘플 처리율, 타이밍 클로저
- [ ] [B3] DSP-05: 복소수 곱셈기 — (a+jb)(c+jd) 3-곱셈 Karatsuba, DSP48E1 2개 절약, IQ 신호 처리 테스트벤치
- [ ] [B3] DSP-05: 누적 오차 측정기 — MAC 반복 1000회 고정소수점 vs 부동소수점 비교, 오차 성장 그래프 UART 출력

### 06. FFT와 스펙트럼 분석
- [ ] [B3] DSP-06: 기저-2 DIT FFT — N=16/64/256 포인트, 비트 역순 주소, 버터플라이 연산, Twiddle 계수 BRAM
- [ ] [B3] DSP-06: 윈도우 함수 하드웨어 — Hann·Hamming·Blackman 계수 BRAM, FFT 전 곱셈 적용, 스펙트럼 누설 감소 측정
- [ ] [B3] DSP-06: 실시간 스펙트럼 분석기 — XADC 입력 → FFT → 주파수 빈 → VGA 막대 그래프, 오디오 신호 테스트
- [ ] [B3] DSP-06: IFFT 역변환 — FFT 결과 역순, 켤레 대칭 활용, 주파수 도메인 필터링 → 역변환 왕복 테스트
- [ ] [B3] DSP-06: STFT 단시간 푸리에 변환 — 슬라이딩 윈도우 중첩 버퍼, 시간-주파수 2D 열지도 VGA 표시

### 07. 칼만 필터 및 센서 융합
- [ ] [B3] DSP-07: 1D 스칼라 칼만 필터 — 예측·갱신 2단계 고정소수점, 프로세스·측정 잡음 Q/R 레지스터, UART 로그
- [ ] [B3] DSP-07: 2D 칼만 필터 (위치·속도) — 2×2 행렬 연산 FSM, 엔코더+가속도계 융합 시뮬 테스트벤치
- [ ] [B3] DSP-07: 상보 필터 vs 칼만 비교 — IMU(MPU-6050 모델 TB) 자세 추정, CPU 사이클·LUT·수렴 속도 대조
- [ ] [B3] DSP-07: 확장 칼만 필터(EKF) 기초 — 비선형 야코비안 고정소수점 근사, 자세 추정 1축, 오차 공분산 추적
- [ ] [B3] DSP-07: 센서 융합 SoC IP — XADC(가속도) + 엔코더 + 기압 센서 3개 융합 칼만, AXI4-Lite 출력 레지스터

### 08. Custom AXI 필터 IP — SoC 통합·실물 검증
- [ ] [B3] DSP-08: AXI4-Stream FIR IP — tdata/tvalid/tready 핸드셰이크, 연속 샘플 스트림 처리, MicroBlaze V DMA 연동
- [ ] [B3] DSP-08: AXI4-Lite 가변 계수 IIR — 런타임 계수 쓰기, 필터 전환 무음 절환, 소프트웨어 드라이버(C) 포함
- [ ] [B3] DSP-08: DSP 가속기 AXI 성능 측정 — 처리율(MSPS), 레이턴시(사이클), DMA 대역폭, MicroBlaze V 소프트 필터 대비 가속비
- [ ] [B3] DSP-08: 실물 검증 체크리스트 캡스톤 — Basys3 오실로스코프 없이 XADC 자기 루프백, 스텝 응답·임펄스 응답 측정, S2 달성 절차

