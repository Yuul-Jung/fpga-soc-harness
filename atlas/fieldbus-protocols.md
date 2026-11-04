# 필드버스 프로토콜 비교 (CAN · CAN FD · MODBUS RTU · EtherCAT)

갱신: 2026-11-04 (/verify 4차). 카드 8건 기준 (wangxuan95-fpga-can, dpiegdon-verilog-can, csselectronics-can-fd-frame-guide, st-community-fdcan-8mbps-nucleo, isluckyhui-fpga-modbus-rtu, egerobotics-esp32s3-ethercat-soes, ppisa-rpi-rt-control, circuitdigest-feroflyf405-open-source-fc).

---

## 비교표

| 항목 | 카드 | 프로토콜 | 플랫폼 | 핵심 수치/특성 | 한계 |
|---|---|---|---|---|---|
| CAN 2.0 Verilog IP | wangxuan95-fpga-can | CAN 2.0 | FPGA (범용 Verilog) | CAN 컨트롤러 단독 RTL, iVerilog 시뮬레이션 | 최대 1 Mbit/s, 8 B 페이로드, Basys3 xdc 미포함(needs-port) |
| CAN 2.0 Verilog IP | dpiegdon-verilog-can | CAN 2.0 | FPGA (Verilog) | 컨트롤러 모듈 분리, C++ 테스트 드라이버 | AXI 인터페이스 없음, Basys3 포팅 필요(needs-port) |
| CAN FD 프레임 구조 | csselectronics-can-fd-frame-guide | CAN FD | (참조 기사) | 최대 64 B 페이로드, 데이터 비트율 최대 5 Mbit/s, 17·21비트 CRC, DLC 테이블 | 에러 프레임 상세 없음, 비트 타이밍 미포함 |
| CAN FD MCU 구현 | st-community-fdcan-8mbps-nucleo | CAN FD | STM32 Nucleo (Cortex-M) | 8 Mbit/s FDCAN, STM32H7 하드 FDCAN 컨트롤러, ST HAL | 하드 IP 전용; FPGA 소프트 구현에 직접 이식 불가 |
| MODBUS RTU Verilog | isluckyhui-fpga-modbus-rtu | MODBUS RTU | Artix-7 (XC7A100T) | FC 0x03 슬레이브, CRC16-Modbus, 115200 bps RS485, MIT | FC 0x06·0x10 미구현, CRC 요청 검증 없음, AXI 없음(needs-port) |
| EtherCAT 소프트 슬레이브 | egerobotics-esp32s3-ethercat-soes | EtherCAT | ESP32-S3 + W5500 | SOES 오픈소스 스택, TwinCAT 3 연동 성공, 소프트 ESC | 성능(사이클 타임) 미측정, I/O 3+3 개념증명, 라이선스 미확인 |
| CAN 모터 제어 (참고) | ppisa-rpi-rt-control | CAN + SPI | RPi 실시간 제어 | CAN 버스 모터 명령, SPI 엔코더 | FPGA 직접 이식 불가, 개조 경로 참고용 |
| CAN 드론 FC (참고) | circuitdigest-feroflyf405-open-source-fc | CAN + UART | STM32F405 | ESC DSHOT, CAN/SPI/I2C 주변장치 다수 | MCU 펌웨어, needs-port |

---

## 프로토콜 특성 요약

| 프로토콜 | 최대 속도 | 최대 페이로드 | 버스 위상 | Basys3 적합성 | 카드 |
|---|---|---|---|---|---|
| CAN 2.0 | 1 Mbit/s | 8 B | 차동(반이중) | needs-port (Verilog RTL 존재) | wangxuan95-fpga-can, dpiegdon-verilog-can |
| CAN FD | 명목 1 Mbit/s / 데이터 5 Mbit/s | 64 B | 차동(반이중) | needs-port (기사 기준 FSM 설계 필요) | csselectronics-can-fd-frame-guide |
| MODBUS RTU | 115200 bps RS485 | 최대 252 B | 반이중 UART | needs-port (Artix-7 RTL, xdc 교체) | isluckyhui-fpga-modbus-rtu |
| EtherCAT | 100 Mbit/s | 프레임 가변 | 이더넷 (전이중) | 복잡 (소프트 ESC + SPI-W5500 + SOES 포팅) | egerobotics-esp32s3-ethercat-soes |

---

## 패턴

### P1: "FPGA CAN 2.0 → CAN FD 확장" 패턴

내 판단: 기존 Verilog CAN 2.0 RTL(wangxuan95-fpga-can, dpiegdon-verilog-can)은 FDF 비트를 인식하지 못해 그대로 CAN FD 버스에 붙이면 에러 프레임을 발생시킨다. CAN FD 대응 FSM은 FDF 감지(중재 단계) → BRS 분기(데이터 단계 고속 전환) → ESI 처리(에러 패시브 표시) → DLC 디코더(9→12 B, …, 15→64 B) → 17/21비트 CRC 검사 모듈로 구성된다. 100 MHz 클럭 기준 5 Mbit/s 데이터 비트율은 20 샘플/비트 오버샘플링으로 가능하다. 근거: csselectronics-can-fd-frame-guide, wangxuan95-fpga-can.

### P2: "MODBUS RTU 최소 슬레이브 → AXI4-Lite 래퍼" 경로

내 판단: isluckyhui-fpga-modbus-rtu의 FC 0x03 FSM + CRC16 모듈을 가져다가 ① RS485 DE/RE 방향 제어 ② FC 0x06·0x10 쓰기 경로 FSM ③ AXI4-Lite 래퍼(holding register ↔ AXI 레지스터)를 추가하면 MicroBlaze V에 붙일 수 있는 MODBUS RTU 슬레이브 IP를 만들 수 있다. MIT 라이선스이므로 구조 참고 가능. `free_slots`에서 64 KB 1슬롯 배정 필요. 근거: isluckyhui-fpga-modbus-rtu.

### P3: 필드버스 난이도 사다리

내 판단: Basys3에서 필드버스를 붙이는 순서는 MODBUS RTU(RS485 Pmod, UART FSM 확장, MIT) → CAN 2.0(CAN Pmod 아두이노 호환 가능, Verilog RTL 존재) → CAN FD(CAN 2.0 RTL 확장, FSM 복잡도 증가) → EtherCAT(W5500 SPI, SOES 포팅, 가장 복잡)이다. EtherCAT 소프트 ESC는 MicroBlaze + FreeRTOS 사이클 타임(100 μs) 충족 여부 미검증으로 개념증명 단계 이상의 위험이 있다. 근거: isluckyhui-fpga-modbus-rtu, egerobotics-esp32s3-ethercat-soes, csselectronics-can-fd-frame-guide.

---

## 교훈

- CAN 2.0 Verilog RTL이 2종 존재하지만 AXI 인터페이스 없이 직결 UART 방식이다. MicroBlaze V 연결에는 AXI4-Lite 래퍼 신규 작성이 공통 과제다(내 판단).
- MODBUS RTU는 RS485 반이중 특성상 DE/RE 방향 제어가 필수이나 현 RTL에 없다. 아두이노 호환 RS485 모듈(SN65HVD75 계열)이 Pmod로 연결 가능해 하드웨어 비용이 낮다(내 판단).
- EtherCAT 소프트 ESC는 "전용 하드웨어 ESC IC 없는 개념증명"으로서 가능성은 보여 주지만, 사이클 타임과 SOES 포팅 절차가 미검증이다. 가장 복잡한 산업 프로토콜 캡스톤 후보(I-066 dropped → 재등록 조건 필요).
