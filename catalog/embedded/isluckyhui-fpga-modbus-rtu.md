---
name: isluckyhui-fpga-modbus-rtu
url: https://github.com/IsLuckyHui/FPGA_Modbus_RTU-MasterAndSlave-
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(순수 RTL)
language: Verilog
tools: [Xilinx]
bus: RS485 반이중 UART
peripherals: [comm-uart]
stage: T1
license: MIT
stats: {stars: 1, commits: 4, last_update: null}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://github.com/IsLuckyHui/FPGA_Modbus_RTU-MasterAndSlave-]
---

## 요약

Xilinx Artix-7(XC7A100T) 대상 MODBUS RTU 슬레이브 Verilog 구현. 순수 RTL로 타사 IP 없이 작성했으며 MIT 라이선스. 50 MHz 클럭·115200 bps RS485 반이중 인터페이스, FC 0x03 읽기 레지스터 슬레이브 경로만 구현됨.

## 구조

- **최상위**: `rs485_top` → `rs485_rx` + `slave` + `rs485_tx`
- **CRC 모듈**: `crc16_modbus` (CRC-16 Modbus 별도 모듈화)
- **선택적 마스터**: `master_send` — 프레임 버퍼링·CRC 추가·인터프레임 타이밍 처리. 최상위에 연결되지 않은 선택 모듈.
- **클럭/시리얼 포맷**: 50 MHz 입력, 115200 bps 8N1
- **레지스터**: 보유 레지스터(holding register) 16개. `initial` 블록으로 초기화(Xilinx 전용).
- 파일: 6개 `.v` 파일 + `rs485/` 폴더. README 기준 root에 배치.

## 검증·재현성

README에서 직접 열람(L3). 테스트벤치 없음. CRC 모듈은 온라인 CRC 계산기로 검증 벡터 1건 확인(`10 03 10 00 00 03` → `4A02`). Vivado 프로젝트·xdc 파일 존재 여부 미확인.

## 한계·위험

- **FC 0x03만 지원**: 쓰기(FC 0x06, 0x10) 미구현. 0x10은 파라미터만 정의되고 FSM 없음. 예외 응답(0x83) 없음.
- **CRC 미검증**: 요청 CRC 수신 후 검사하지 않음. 응답에도 CRC 미포함.
- **최대 6레지스터 읽기** 제한(16개 보유 레지스터).
- **인터프레임 간격**: 정확한 3.5자 간격 대신 4바이트 시간으로 근사.
- **DE/RE 방향 제어** 없음: 수동 추가 필요.
- **`initial` 블록**: Xilinx 이외 툴체인에서 레지스터 초기화 재작성 필요.

## 재사용 메모

- 단순한 RTL 구조(6개 모듈)로 Basys3(XC7A35T)에 포팅 가능. `needs-port` 근거: Artix-7 시리즈 RTL, Basys3 xdc·클럭·핀 교체 필요. LUT/FF 소모는 소규모 예상(내 판단).
- FC 0x03 슬레이브 FSM + CRC16 모듈은 Basys3 MODBUS 센서 허브 IP 기초로 가져올 수 있음. MIT 라이선스이므로 구조 참고 가능.
- 개조: MicroBlaze V SoC에 MODBUS RTU 슬레이브 IP로 붙이려면 ① RS485 방향 제어(DE/RE) 로직 추가 ② FC 0x06·0x10 쓰기 경로 FSM 추가 ③ AXI4-Lite 슬레이브 래퍼(holding register ↔ AXI 레지스터) 작성 ④ CRC 요청 검증 추가. 현 RTL은 AXI 없이 직결 UART 방식이므로 래퍼는 신규 작성해야 함(내 판단). `free_slots` 64 KB 1슬롯 배정.
