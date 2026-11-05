# SoC 기술 트리 (단계별 카드 연결)

갱신: 2026-11-06 (/verify 20차). 카드 244건 기준. 비 FPGA 도메인(STM32 18건·ESP32 14건·RPi·Arduino·임베디드·전자기술 14건·papers 포함). 10차: 전자기술 도메인 14건 추가(SPWM 인버터·게이트 드라이버·전원 설계·XADC 아날로그 프런트엔드). 13차: I-082·I-083 ready 승격(PCB 설계 체크리스트), 감사 경고 수정 3건(라이선스 주석 추가). 20차: VGA·7세그·프레임버퍼·카메라·LED·PWM 카드 9건 추가(video-vga 그룹 6건+camera 1건+pwm-rgb 2건). atlas/video-vga.md 신규 작성.

---

## FPGA·SoC 단계별 연결 (Basys3 직접 연결 가능 카드)

| 단계 | 주요 카드 | 비고 |
|---|---|---|
| T0 | zipcpu-pmodamp2-project-ladder (T0-T2) | 핀 확인과 단음 단계 |
| T1 | wangxuan95-fpga-sdcard-file, element14-security-camera-2-sd-card-interfacing | CPU 없이 FSM으로 SD·카메라 |
| T2 | digilent-forum-pmodamp3-basys3-i2s, zipcpu-sdspi, zipcpu-pmodamp2-project-ladder, argrabowski-fpga-vga-display, itsnotjiaching-ec311project | I2S 송신, Wishbone 주변장치, VGA+7세그 동시 표시 |
| T3 | (FPGA 카드 없음) | gap: 프레임워크 기반 SoC에 주변장치를 붙인 Basys3 사례 미확보 |
| T4 | columbia-4840-audio-visualizer, byu-ecen423-lab10-riscv-vga-7seg | DE1-SoC HPS 기반·BYU RISC-V VGA 텍스트+7세그 (소스 비공개) |
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

## RPi 도메인 단계 연결 (개조 참고)

Buildroot·Linux 이미지 카드는 Basys3 LiteX Linux·MicroBlaze V BSP 개발에 개조 경로가 있다.

| 단계 | 카드 | 개조 대상 |
|---|---|---|
| T0 | sujan-coder-buildroot-linux-rpi3 | Buildroot 구성 → LiteX Linux 최소 rootfs 패턴 |
| T0 | obuda-buildroot-mini-linux-tutorial | 이미지 크기·부팅 시간 비교 측정 절차 → LiteX 환경 적용 |
| T1 | smartmechatronics-embedded-linux-boot-time-reduction | U-Boot 딜레이 제거·SD 로드·커널 모듈화 → LiteX U-Boot 이식(I-059), BusyBox init(I-060) |

## 임베디드 도메인 단계 연결 (RTOS, 개조 참고)

FreeRTOS·Zephyr 비교 카드는 MicroBlaze V + AXI INTC RTOS 설계에 개조 경로가 있다.

| 단계 | 카드 | 개조 대상 |
|---|---|---|
| T2 | freertos-org-faq-memory | 스케줄러 236B + 태스크 64B → MicroBlaze V BSP BRAM 할당 계획 |
| T2 | ezurio-freertos-vs-zephyr-benchmark | STM32F4 협력형/뮤텍스 사이클 비교 → MicroBlaze V ISR 반응성 타이밍 계획 근거 |
| T2 | beningo-freertos-to-zephyr-migration | API 대응표·ISR 포팅 함정 → FreeRTOS→Zephyr 이식 경로 참고 (Vitis BSP FreeRTOS 경로 권장) |

---

## 필드버스 도메인 단계 연결 (CAN · MODBUS · EtherCAT, 개조 참고)

필드버스 프로토콜 카드는 MicroBlaze V에 AXI4-Lite 래퍼로 붙일 수 있는 통신 IP 개발에 개조 경로가 있다.

| 단계 | 카드 | 개조 대상 |
|---|---|---|
| T1 | isluckyhui-fpga-modbus-rtu (임베디드) | FC 0x03 FSM + CRC16 → AXI4-Lite MODBUS RTU 슬레이브 IP (DE/RE 추가, free_slots 1슬롯) |
| T2 | csselectronics-can-fd-frame-guide (papers) | CAN FD 프레임 구조(FDF·BRS·ESI·DLC·CRC) → CAN FD 파서 FSM 설계 근거 |
| T2 | wangxuan95-fpga-can (vendor-neutral) | CAN 2.0 Verilog RTL → CAN FD 확장 기점 (FDF 감지 FSM 분기 추가 필요) |
| T3 | egerobotics-esp32s3-ethercat-soes (esp32) | 소프트 ESC 구조 (W5500 SPI, SOES, TwinCAT 연동) → MicroBlaze V EtherCAT 슬레이브 개조 (사이클 타임 미검증, 가장 복잡) |

---

## 기능 안전 도메인 단계 연결 (IEC 61508, 개조 참고)

안전 관련 카드는 AXI4-Lite 워치독 IP·CRC 검사 IP·스택 센티넬 소프트웨어 패턴 개발에 개조 경로가 있다. 상세는 `atlas/functional-safety.md` 참조.

| 단계 | 카드 | 개조 대상 |
|---|---|---|
| T0 | heia-fr-ma-embreal-zephyr-stack-protection (embedded) | Zephyr 스택 보호 4계층 → MicroBlaze V 소프트웨어 센티넬(C) + AXI4-Lite 감시 IP |
| T0 | tum-industrial-es-2015-functional-safety (papers) | IEC 61508 개념(FMEA/FMEDA/CRC) → 캡스톤 보고서 안전 분석 절 근거 |
| T1 | rtime-cvut-openmsp430-watchdog (embedded) | openMSP430 WDT FSM → AXI4-Lite WDT IP (패스워드 보호, 비트-탭 타임아웃, free_slots 배정) |

---

## gap 목록 (내 판단)

- gap T1→T2: 오디오·SD를 AXI4-Lite 레지스터 맵으로 감싼 Basys3 완성형 카드 미확보.
- gap T2→T4: FPGA 내부 FFT (BRAM 제약) 사례 없음 — Columbia는 HW FFT 포기.
- gap T2: Basys3 MicroBlaze V AXI4-Lite VGA 텍스트 IP 카드 없음 — I-108(vetted)이 채울 예정. 근거: argrabowski, byu-ecen423, itsnotjiaching 카드.
- gap T2: 듀얼포트 BRAM 프레임버퍼 AXI4-Lite 슬레이브 IP 카드 없음. 근거: fcayci, talsania, projf 카드.
- gap T1: RGB LED Basys3 AXI4-Lite 슬레이브 IP 카드 없음 — I-030(ready), I-031(ready)이 채울 예정. 근거: maplesilicon, mit-6205, olivier-le-sage 카드.
- gap T2: 모터 제어(엔코더 + PID) 를 Basys3 AXI4-Lite IP로 구현한 FPGA 카드 없음; STM32 도메인에 모터 제어 카드 다수 → 개조 경로는 있으나 Basys3 이식 카드 아직 없음(내 판단).
- gap T3: ESP32 BLE/Wi-Fi를 UART로 Basys3에 붙인 통합 SoC 카드 없음.
- gap T3: Basys3 LiteX Linux 부트 최적화(U-Boot, BusyBox init) 사례 없음; RPi Yocto·Buildroot 사례 → 개조 경로 있음(I-059, I-060, 내 판단).
- gap T5: DRAM 보드 필요, 수집 대상 밖.
- gap T2: MODBUS RTU AXI4-Lite 슬레이브 IP 카드 없음; isluckyhui-fpga-modbus-rtu(FC 0x03 슬레이브)가 기초, AXI 래퍼 신규 작성 필요(I-065 vetted).
- gap T2: CAN FD 파서 FPGA Verilog 카드 없음; wangxuan95-fpga-can(CAN 2.0)에서 FDF 분기 추가 경로(I-064 vetted).
- gap T3: EtherCAT 소프트 슬레이브 Basys3 MicroBlaze V 사례 없음; egerobotics-esp32s3-ethercat-soes 개조 경로 있으나 사이클 타임 미검증(I-066 dropped, 재등록 조건 필요).
- gap T1: Basys3 MicroBlaze V에 연결된 AXI4-Lite 워치독 IP 카드 없음; rtime-cvut-openmsp430-watchdog 개조 경로 있음(I-070 vetted, 7점).
- gap T2: Basys3 BRAM 명령 메모리 CRC 검사 AXI IP 카드 없음(I-071 vetted, 5점, I-070 선행 필요).
- gap T2: 전자기술 도메인에 SPWM·XADC 카드가 14건 추가되었으나, Basys3+MicroBlaze V AXI4-Lite SPWM IP 카드 없음 — I-077(ready 후보)이 채울 예정.
- gap T2: XADC 전원 모니터 AXI-Lite IP 카드 없음 — I-075(ready)가 채울 예정.

---

## VGA·카메라·LED·PWM 도메인 단계 연결 (개조 참고)

VGA 출력·프레임버퍼·카메라 파이프라인·LED PWM 카드. 상세는 `atlas/video-vga.md` 참조.

| 단계 | 카드 | 개조 대상 |
|---|---|---|
| T1 | maplesilicon-mapleled-core (vendor-neutral) | 감마 LUT BRAM 초기화 패턴 → AXI4-Lite 슬레이브 감마-PWM IP (I-030) |
| T1 | mit-6205-rgb-pwm-week01 (papers) | PWM glitch 방지 패턴(래치-at-reset), cocotb 테스트벤치 → AXI4-Lite RGB PWM IP (I-030) |
| T2 | argrabowski-fpga-vga-display (amd) | VGA 타이밍 + 7세그 멀티플렉서 분리 패턴 → AXI4-Lite VGA IP (I-108) |
| T2 | itsnotjiaching-ec311project (amd) | Pong VGA+7세그 score.v 멀티플렉서 패턴 → AXI4-Lite VGA IP + MBV C 드라이버 (I-109) |
| T2 | fcayci-xilinx-vga-framebuffer-ip-core (amd) | 듀얼포트 BRAM 포트A=CPU·포트B=VGA 스캔 → AXI4-Lite 프레임버퍼 IP |
| T2 | talsania-fpga-image-buffer (vendor-neutral) | UART→BRAM 로더 → no-dram 환경에서 MBV 소프트웨어 memcpy 패턴으로 이식 |
| T2 | projf-projf-explore (vendor-neutral) | BRAM 타일·스프라이트 패턴 → Basys3 VGA 그래픽 IP (SV→Verilog-2001 변환 필요) |
| T4 | byu-ecen423-lab10-riscv-vga-7seg (amd) | MMIO VGA 텍스트+7세그 소프트웨어 드라이버 패턴 → MBV C 드라이버 설계 참고 (소스 비공개) |
| T4 | olivier-le-sage-camera-filters (vendor-neutral) | 시프트 근사 감마+YUV 변환 패턴 → AXI4-Lite 색공간 처리 IP |

---

## 전자기술 도메인 단계 연결 (전력전자·XADC·전원, 개조 참고)

SPWM·게이트 드라이버·XADC 아날로그 프런트엔드 카드는 MicroBlaze V + AXI4-Lite 전력전자 IP 개발에 개조 경로가 있다. 상세는 `atlas/electronics.md` 참조.

| 단계 | 카드 | 개조 대상 |
|---|---|---|
| T2 | arxiv-1002340-spartan3e-spwm-inverter (electronics) | SPWM 삼각파-기준파 비교 RTL → AXI4-Lite 래퍼 추가, 데드타임 FSM 결합 (I-077) |
| T2 | element14-cumps-deadtime-vhdl-pynqz2 (electronics) | 보완 출력·데드타임 삽입 FSM → Verilog 변환·Basys3 Pmod 핀 적용 (I-077, I-078) |
| T2 | industrialmonitordirect-irs2110-half-bridge (electronics) | HIN/LIN 타이밍·부트스트랩 → Pmod 버퍼 추가 후 IRS2110 연결 (I-078) |
| T2 | amd-ug480-xadc-external-inputs (electronics) | XADC 차동 입력 범위·RC 필터 → AXI4-Lite 슬레이브 IP (I-075, I-079, I-081) |
| T2 | xilinx-xapp795-driving-xadc (electronics) | 소스 임피던스·앤티앨리어싱 → ACS712 신호 조건화 (I-081) |
| T2 | sparkfun-acs712-current-sensor (electronics) | 감도·분압 → XADC 입력 조건화, 소프트웨어 오프셋 보정 (I-081) |
| T1 | epdtonthenet-xadc-digitally-enhanced-analogue (electronics) | 오프셋·게인 보정 RTL, 이동 평균 필터 → library/rtl/ 범용 LPF 블록 (I-080) |
| T0 | vishay-fpga-power-supply-consideration (electronics) | FPGA 전원 순서화·디커플링 → 외부 보조 전원 보드 가이드 (I-076) |
| T0 | wevolver-buck-converter-design-guide (electronics) | 벅 컨버터 설계·계산 → 외부 12V→5V 전원 보드 (I-076) |
| T2 | ema-eda-fpga-pcb-design-guide (electronics) | 3W 규칙·차동 쌍·via-in-pad → Pmod 확장 보드 PCB 설계 체크리스트 (I-082 ready) |
| T2 | rfessentials-split-ground-plane-emi (electronics) | 스타 접지·GND 분리 → H-브리지-FPGA 경계 PCB 설계 체크리스트 (I-082, I-083 ready) |
| T2 | jlcpcb-decoupling-capacitor-guide (electronics) | 디커플링 계층(100nF/1µF/10µF) → Pmod·모터 드라이버 PCB (I-082, I-083, I-084 vetted) |
