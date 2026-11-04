---
name: lightside-instruments-ice4pi
url: https://github.com/lightside-instruments/ice4pi
source_type: repo
vendor: neutral
board: [iCE40HX-1K custom RPi HAT]
fit_basys3: needs-port
cpu: none(FPGA fabric)
language: Verilog
tools: [Yosys, arachne-pnr, icestorm, flashrom, icepll]
bus: SPI (RPi master → FPGA slave), I2C (RPi master → FPGA slave)
peripherals: [SPI-slave, I2C-slave, GPIO, PLL-example]
stage: T2
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://hackster.io/lightside-instruments/the-ice4pi-ice40-raspberry-pi-hat-b24c2f]
---

## 요약

RPi Zero 폼팩터의 오픈소스 하드웨어 iCE40 FPGA HAT. RPi의 모든 GPIO 핀을 iCE40HX-1K에 연결하고, SPI로 비트스트림을 플래시에 쓰거나 FPGA를 직접 프로그래밍한다. I2C 슬레이브 예제와 SPI 슬레이브 예제로 RPi↔FPGA 양방향 통신 패턴을 보여 준다.

## 구조

- FPGA: iCE40HX-1K (Lattice, 1K LUT), 단일 PLL로 12 MHz → 120 MHz 변환 가능
- RPi 연결: 전체 GPIO 연결. SPI0.1(`/dev/spidev0.1`)로 FPGA SPI 슬레이브 접근, I2C로 FPGA I2C 슬레이브 접근
- SPI 플래시 경로: RPi SPI로 SPI 플래시에 비트스트림 저장 → FPGA 부팅 시 자동 로드 (RPi 실행 중에도 가능)
- I/O: PMOD 8핀, LED 5개
- 빌드 도구: Yosys(합성), arachne-pnr(배치배선), icestorm(비트스트림), icepll(PLL 설정)
- KiCad 회로도와 PCB 설계 포함, OSHWA 인증(UID NO000002)
- 예제 저장소: `ice4pi-example-i2cslave`(브랜치로 SPI 슬레이브·PLL 예제도 포함)

## 검증·재현성

- Hackster.io 프로젝트 페이지에 전체 단계 설명, KiCad 파일과 Verilog 예제 코드 연결
- 빌드 환경: make, i2c-tools, spi-tools(spi-pipe)로 PC-RPi-FPGA 전체 흐름 검증 가능
- 라이선스: GitHub에서 미확인(hackster.io에 명시 없음)
- unverified: GitHub README 직접 열람 불가 (PROVENANCE_REQUIRED)

## 한계·위험

- iCE40HX-1K는 Basys3의 XC7A35T(33K LUT)보다 크기가 훨씬 작아 RTL 규모 제한이 큼
- arachne-pnr(구 P&R)은 현재 nextpnr로 대체 추세; 빌드 스크립트 갱신 필요 가능성
- 라이선스 미확인으로 코드 복사 전 확인 필요
- RPi 전압(3.3V) ↔ iCE40(3.3V) 직결이므로 레벨 변환 불필요, 단 Basys3 Pmod(3.3V)도 동일 조건

## 재사용 메모

- SPI 슬레이브와 I2C 슬레이브 Verilog 예제를 카드 목적으로 사양 추출 가능(§16.3)
- RPi `/dev/spidev0.1` → 1 CS핀으로 FPGA 레지스터 R/W 패턴은 MicroBlaze V 디버그 창구 설계에 직접 참고됨
- 개조: SPI 슬레이브 FSM(CPOL/CPHA 설정, CS 극성, 바이트 프레임)을 Verilog-2001로 재작성하여 Basys3 Pmod(JA1=MOSI, JA2=MISO, JA3=SCK, JA4=CS)에 연결. iCE40 PLL 설정은 Basys3 MMCM/PLL_BASE로 교체. Yosys 합성 흐름은 Vivado 대체 필요. MicroBlaze V AXI4-Lite 슬레이브로 감싸면 동결 맵의 `free_slots`에 배치 가능.
