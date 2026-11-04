# STM32 사례 종합 (atlas/stm32.md)

갱신일: 2026-11-04
카드 수: 18 (`catalog/stm32/`)
목적: STM32 HAL/LL·RTOS 사례에서 Basys3 SoC 주변장치 IP로 옮길 수 있는 구조와 패턴을 추출한다.

---

## 1. 단계별 분포

| 단계 | 카드 수 | 대표 항목 |
|------|---------|-----------|
| T0   | 1 | HAL/LL/SysTick 구조 이해 |
| T1   | 5 | 엔코더 모드, USB CDC, UART, 스택 디버그 |
| T2   | 7 | FreeRTOS UART, 보완 PWM, FDCAN, I2C 타임아웃, 엔코더 PID |
| T3   | 2 | 로봇팔(서보+I2C), LwIP+FreeRTOS UDP 에코 |
| T4   | 3 | 오픈소스 FC 2종(FeroFlyF405, pinkfluffyunic0rn), FOC |
| T5   | 0 | — |

---

## 2. 주제별 사례 표

### 2.1 모터 제어 (actuator-servo, sensor)

| 카드 | 보드 | 단계 | 주변장치 | 한계/재사용 포인트 |
|------|------|------|----------|--------------------|
| deepbluembedded-stm32-timer-encoder-mode | Nucleo-F446RE | T1 | 직교 엔코더(TIM x2/x4·DIR) | MCU TIM 전용; x2/x4·필터·DIR 비트 → FPGA 엔코더 IP 레지스터 설계 근거 |
| stm32-community-encoder-rollover-management | Nucleo 계열 | T1 | 엔코더 롤오버 처리 | 사분면 델타로 롤오버 경계 처리 → FPGA 32비트 카운터 오버플로 처리 패턴 |
| deepbluembedded-stm32-complementary-pwm-dead-time | F446RE | T2 | 보완 PWM + 데드타임(TIM1) | ARR·PSC·CCR·BDTR 레지스터 구조 → FPGA PWM IP 레지스터 설계 참고 |
| st-community-tim1-complementary-no-deadtime | 복수 Nucleo | T2 | 보완 PWM(TIM1 고급 타이머) | MOE bit 미설정 시 출력 없음 → IP 활성화 레지스터 필수 |
| kael2209-stm32-speed-position-control-pid | Nucleo-F411 | T2 | PID 속도·위치 (소프트웨어) | 100 ms 창 계수·비보호 적분 → FPGA PI IP의 창 계수·클램프 설계 근거 |
| kevinzhang109-stm32-compact-robotic-arm | STM32F405/F407 | T3 | 서보 4채널 + I2C + (Ethernet) | PCA9685 I2C 서보 드라이버 → Pmod SPI/I2C 경유 서보 채널 확장 패턴 |
| makiuto-stm32-foc-from-scratch | STM32G431 | T4 | BLDC FOC(SVM, ADC) | 클락 도메인·인터럽트 타이밍이 코어 의존 → FPGA에서는 클락 enable 버스로 대체; L2 |
| circuitdigest-feroflyf405-open-source-fc | STM32F405RGT6 | T4 | 센서+UART+CAN+PWM | PID 이득·믹서 구조 → 모터 제어 사다리 T4 패키지 근거 |
| pinkfluffyunic0rn-stm32flight | STM32F405/H723 | T4 | 센서+CRSF+Dshot+MSP | 모드별 센서 조합 사다리(자이로→GNSS) → FPGA 자세 추정 IP 사다리 근거; L2 |

### 2.2 통신 (comm-uart, comm-can, comm-eth, USB)

| 카드 | 보드 | 단계 | 주변장치 | 한계/재사용 포인트 |
|------|------|------|----------|--------------------|
| st-community-usb-cdc-transmit-stuck-l452 | STM32L452 | T1 | USB CDC | TX busy/완료 비트 미노출 → FPGA UART IP TX STATUS 레지스터 설계 근거 |
| stm32-community-hal-vs-ll | 복수 | T1 | UART, I2C | HAL/LL 오버헤드 차이 → FPGA에서는 HAL 없이 레지스터 직접 접근 |
| freertos-forum-stm32-cubemx-uart-example | STM32F446 | T2 | UART(FreeRTOS 큐) | UART 인터럽트→FreeRTOS 큐 패턴 → FPGA RX FIFO + 인터럽트 IP 설계 참고 |
| st-community-fdcan-8mbps-nucleo | Nucleo 6종 | T2 | CAN FD | 중재/데이터 BTR 2벌 구조 → FPGA CAN IP BTR 레지스터 2벌 설계 근거 |
| st-community-lwip-freertos-udp-echo-f767 | NUCLEO-F767ZI | T3 | Ethernet(LwIP, UDP에코) | 링크 콜백·소켓 1개·RX 메타데이터 구조 → FPGA UDP 에코 IP STATUS·RX메타 레지스터 설계 참고 |

### 2.3 RTOS·디버그 (debug, comm-i2c)

| 카드 | 보드 | 단계 | 주변장치 | 한계/재사용 포인트 |
|------|------|------|----------|--------------------|
| gdbplus-understanding-stm32-hal-ll-systick | 복수 | T0 | SysTick 타이머, 인터럽트 | HAL 타임베이스 → FPGA 타이머 IP의 주기·인터럽트 모델 참고 |
| predictabledesigns-stm32cubemx-generated-code | Nucleo | T1 | UART, I2C, 센서 | CubeIDE 생성 구조 → FPGA IP 표준의 초기화 순서 비교용 |
| st-community-freertos-stack-overflow-hardfault | Nucleo | T1 | FreeRTOS 디버그 | 스택 오버플로 패턴 → FPGA SoC에서 스택 모니터 레지스터 필요성 근거 |
| st-community-freertos-hal-timeout-systick | F446RE | T2 | I2C + FreeRTOS | SysTick 대신 TIM6 타임베이스 → FPGA 멀티클락 환경에서 타임베이스 분리 패턴 |

---

## 3. 주변장치 태그 집계

| 태그 | 카드 수 |
|------|---------|
| actuator-servo | 7 |
| sensor | 7 |
| comm-uart | 6 |
| debug | 4 |
| comm-i2c | 3 |
| comm-can | 2 |
| comm-eth | 2 |
| actuator-servo(FOC/BLDC) | 2 |

---

## 4. 패턴과 교훈

### 4.1 옮길 수 있는 것
- **레지스터 설계**: ARR/PSC/CCR(PWM), 창 카운터·방향(엔코더), BTR 2벌(CAN FD)은 FPGA IP 레지스터 이름·구조로 직접 옮긴다.
- **상태 레지스터 필수**: TX busy, 링크 상태, 스택 오버플로 플래그처럼 MCU 미들웨어가 소프트웨어 폴링하는 것들은 FPGA IP의 STATUS 레지스터에 비트로 노출한다. 타임아웃 레지스터를 함께 두어 무한 대기를 막는다.
- **클락 도메인 분리**: SysTick 충돌(I2C FreeRTOS 카드, LwIP 카드) 사례는 FPGA에서도 주변장치 클락과 AXI 클락을 분리하는 이유가 된다.
- **모드별 센서 조합 사다리**: 자이로·가속도 → 기압계 → GNSS 순서의 FC 사례는 FPGA 자세 추정 IP의 단계별 확장 구조(I-019, I-020 근거)로 쓴다.

### 4.2 옮길 수 없는 것
- Cortex-M 코어, TIM 고급 타이머 하드웨어(MOE bit, BRK 입력), DMA, USB 장치 스택(Basys3는 FTDI UART).
- LwIP·MPU·디스크립터 메모리 배치(CPU 전용).
- FOC의 ADC 동기 샘플링은 Basys3 XADC 타이밍과 다르다.

### 4.3 내 판단
- 내 판단: STM32 사례의 가장 큰 가치는 레지스터 필드 이름과 비트 의미(ARR, PSC, CCR, TxState 등)에 있다. 코드가 아니라 사양을 뽑아 FPGA IP 레지스터 표의 근거로 쓴다(§16.3 G0 준수).
- 내 판단: 모터 제어(T2~T4)가 집중되어 있다. T0~T1 사례 추가로 입문 사다리를 메울 여지가 있다(I-016 엔코더 사다리 근거).

---

## 5. 관련 아이디어

| 아이디어 | 근거 카드 |
|----------|-----------|
| I-011 모터 IP 입문 세트 | deepbluembedded-stm32-complementary-pwm-dead-time, kael2209-stm32-speed-position-control-pid |
| I-013 속도 PI 폐루프 IP | kael2209-stm32-speed-position-control-pid, deepbluembedded-stm32-timer-encoder-mode |
| I-016 엔코더 난이도 사다리 | deepbluembedded-stm32-timer-encoder-mode, stm32-community-encoder-rollover-management |
| I-010 CAN 노드 IP | st-community-fdcan-8mbps-nucleo |

---

## 6. 연결

- 관련 atlas: (신설, 연결 없음)
- 관련 devices: `devices/uart/`, `devices/can/`, `devices/i2c/`
- soc-map: T2 모터 제어 IP, T3 통신 IP 단계에 연결
