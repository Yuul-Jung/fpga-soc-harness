# 수집 주제 목록

자동 수집 모드가 위에서부터 `[ ]` 항목을 하나씩 소비한다. 끝나면 `[x]`로 바꾼다.

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
- [ ] ESP32 FreeRTOS + 멀티코어: Core0/1 핀닝, Task Watchdog, Inter-Core 통신
- [ ] ESP32 카메라·오디오: ESP32-CAM OV2640 스트리밍, I2S 마이크·스피커 (MAX98357)
- [ ] ESP32 엣지 AI: TFLite Micro 제스처·키워드 인식, ESP-IDF AI 예제 캡스톤

## Raspberry Pi 도메인 (2026-11-03 추가, 위에서부터 소비)
- [ ] RPi GPIO: pigpio/gpiozero 기초, SPI/I2C 커널 드라이버와 Python 바인딩
- [ ] RPi 카메라 파이프라인: Picamera2 + libcamera, OpenCV 실시간 영상 처리
- [ ] RPi 실시간성: PREEMPT_RT 패치, isolcpus, 사이클릭 테스트 (모터 제어 목표)
- [ ] RPi FPGA 연동: RPi SPI/I2C로 FPGA 제어, AXI 스트림 데이터 전송 사례
- [ ] RPi OS 프로젝트: Buildroot 최소 이미지, 부트 시간 최적화, 임베디드 배포

## 임베디드 공통 도메인 (2026-11-03 추가, 위에서부터 소비)
- [ ] RTOS 비교: FreeRTOS vs Zephyr vs ThreadX — 태스크 모델·메모리·포팅 난이도
- [ ] 프로토콜 심화: CAN FD 프레임 구조, MODBUS RTU/TCP, EtherCAT 기초
- [ ] 디버그 기법: JTAG/SWD 트레이스, OpenOCD, Segger RTT, 논리 분석기 활용
- [ ] 펌웨어 OTA: MCUboot 부트로더, 이중 파티션 업데이트, 서명 검증
- [ ] 안전 기능: MISRA C, 워치독, 스택 카나리, CRC 검사, FMEA 예시

## 전자기술 도메인 (2026-11-03 추가, 위에서부터 소비)
- [ ] 모터 드라이버 회로: H-브리지 MOSFET 선택·게이트 드라이버·데드타임·역기전력 보호
- [ ] 전력 공급: DC-DC 벅/부스트 컨버터 설계, LDO vs 스위칭 레귤레이터 선택 기준
- [ ] 인버터 기초: 단상 풀브리지 SPWM, 게이트 격리(포토커플러/게이트 드라이버 IC)
- [ ] 센서 신호 처리: ADC 입력 필터링, 차동 증폭, 홀 전류 센서 보정
- [ ] PCB 설계 체크리스트: 전류 경로, GND 플레인 분리, EMC 디커플링, 레이아웃 규칙

## 도메인 보충 4 (2026-11-03 §12.2-3: stm32/esp32/rpi/embedded/electronics 카드 0건, 위에서부터 소비)
- [x] STM32 모터 제어: 타이머 엔코더 모드 + PWM + PID (HAL/LL) 사례와 FPGA 엔코더/PWM IP 레지스터로의 개조 (stm32 카드 0건, S3) — 2026-11-03 23시대 사이클: 카드 3건(L3), catalog/stm32/ 신설, PID 이득·샘플 주기 공개 자료와 LL 드라이버 직접 자료는 못 찾음, mbed 32비트 확장은 리다이렉트로 열람 못 함
- [x] ESP32 센서 허브: Wi-Fi/BLE 텔레메트리 + FreeRTOS 센서 태스크, Basys3 UART 브리지 조합 (esp32 카드 0건) — 2026-11-03 사이클: 카드 3건(L3, esp32 신설 2건+ICE-V Wireless), Basys3 직접 ESP32 브리지 사례와 소스·SHA 열람은 못 함, 큐에 tinytapeout Basys3 UART 링크 등 후보
- [ ] Raspberry Pi GPIO/SPI 호스트로 Basys3 주변장치 IP를 제어·시험하는 사례 (rpi 카드 0건)
