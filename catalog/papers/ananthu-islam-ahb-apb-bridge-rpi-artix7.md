---
name: ananthu-islam-ahb-apb-bridge-rpi-artix7
url: https://arxiv.org/abs/2501.01147
source_type: paper
vendor: amd
board: [Artix-7 100TCSG324]
fit_basys3: needs-port
cpu: none(SPI-host-driven)
language: Verilog
tools: [Vivado, Design Compiler, ICC2]
bus: AMBA AHB-Lite → AHB-APB-Bridge → AMBA APB
peripherals: [SPI-slave, AHB-to-APB-bridge, APB-peripheral]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://arxiv.org/html/2501.01147v1, https://arxiv.org/abs/2501.01147]
---

## 요약

라즈베리파이 4B가 SPI 마스터로서 Artix-7 100TCSG324 FPGA에 연결해 AHB-APB 브리지 IP를 구동·검증한다. University of Maryland Baltimore County(UMBC) 2025년 논문. RPi가 100비트를 MOSI로 직렬 전송하면 FPGA 내 SPI 슬레이브→Mapper1→AHB-APB 브리지→Mapper2 체인을 거쳐 104비트 처리 결과가 MISO로 반환된다.

## 구조

- RPi4 역할: Python 스크립트로 SPI 마스터, MOSI에 100비트 직렬 입력 전송, MISO에서 104비트 출력 수신
- FPGA Verilog 모듈 체인:
  - `spi_slave`: 직렬→병렬 변환, 100비트 입력 수신
  - `Mapper1`: AHB 신호 조립(HTRANS, HWDATA, HADDR, HSIZE, HBURST, HPROT)
  - `Bridge_Top`: AHB 슬레이브 인터페이스 + APB FSM 컨트롤러 + APB 인터페이스(PENABLE, PSEL, PWRITE, PWDATA, PRDATA)
  - `Mapper2`: APB 출력→104비트 직렬화→MISO
- I/O 매핑: RPi GPIO와 FPGA 사이 SPI 4-wire(CLK, MOSI, MISO, CS) 직결 (Table I)
- 클럭: 별도 명시 없음; 타이밍 슬랙 0.34 ns MET(Design Compiler 기준)

## 검증·재현성

- Xilinx Vivado에서 Verilog 행동 시뮬레이션 파형(Fig. 4–7): AHB-APB FSM, 전체 브리지, SPI 통합 설계 검증
- 합성: Design Compiler + ICC2 사용. 면적 785.24 단위, 전력 344.7 µW(Table II–III)
- 타이밍: 슬랙 0.34 ns MET(Table IV)
- 보드 동작: 논문이 명시하지 않음; RPi-FPGA 연결도와 waveform만 제시
- 소스 코드: GitHub 링크 없음. 논문 본문에서 사양 추출(§16.3 G3)

## 한계·위험

- 소스 코드 미공개: 카드에 사양만 기록, 코드 복사 불가
- 100T 디바이스(Nexys A7 등)에서 검증; Basys3(35T)는 별도 포팅 필요
- SPI 프레임 폭이 100/104비트 고정: 범용 AXI-Lite R/W 주소맵 접근 아님(단일 테스트 패킷)
- Hresp 비일치: 본문에서 "에러 없음"이라 하나 Table I에서 `0b10`(HRESP ERROR)으로 기재 — 내 판단: 논문 내부 불일치
- 라이선스 미명시

## 재사용 메모

- SPI→병렬 변환→버스 프로토콜 변환→주변장치 체인 구조: AXI4-Lite SPI 슬레이브 IP 설계의 개념 참조 가능
- RPi4 Python SPI 마스터 패턴: Basys3 Pmod 헤더(3.3V)에 RPi GPIO를 직결하는 테스트 환경 구성에 적용 가능
- 개조: AHB→APB 브리지 대신 AXI4-Lite 슬레이브를 SPI 프레임 디코더에 직결하면 MicroBlaze V `free_slots` 주소맵과 바로 연결. SPI 프레임을 "1바이트 R/W opcode + 4바이트 주소 + 4바이트 데이터"로 단순화하면 고정 100비트 프레임 한계 제거 가능. 클럭 도메인은 RPi SPI CLK(최대 ~32 MHz)와 Basys3 AXI 클럭(50 MHz) 사이 2플립플롭 동기화 삽입 필요.
