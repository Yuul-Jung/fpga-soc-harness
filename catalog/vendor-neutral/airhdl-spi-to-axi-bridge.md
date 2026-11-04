---
name: airhdl-spi-to-axi-bridge
url: https://github.com/airhdl/spi-to-axi-bridge
source_type: repo
vendor: neutral
board: []
fit_basys3: yes
cpu: none(SPI-host-driven)
language: SystemVerilog
tools: [Vivado, Riviera-Pro, OSVVM]
bus: SPI → AXI4-Lite
peripherals: [SPI-slave, AXI4-Lite-master, register-bridge]
stage: T2
license: Apache-2.0
stats: {stars: 57, forks: 18, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/airhdl/spi-to-axi-bridge]
---

## 요약

외부 SPI 마스터(라즈베리파이·MCU 등)가 FPGA 내 AXI4-Lite 레지스터를 직접 읽고 쓸 수 있도록 중개하는 SPI-to-AXI4-Lite 브리지 IP. SystemVerilog와 VHDL 단일 파일로 제공되며, airhdl 레지스터 뱅크 생성 도구와 연동하도록 설계됐으나 독립 IP로도 사용 가능. Apache-2.0.

## 구조

- 소스 파일: `src/spi2axi.sv`(SystemVerilog) / `src/spi2axi.vhd`(VHDL) — 각 단일 파일
- SPI 모드: 0–3 모두 지원 (`SPI_CPOL`, `SPI_CPHA` generic/parameter로 정적 설정)
- 전송 형식(모두 11바이트, MSB first):
  - 쓰기: `0x00`(instr) + 4B 주소 + 4B 데이터(상위 먼저) + 1B dummy + 1B 상태(bit2=timeout, bit1:0=BRESP)
  - 읽기: `0x01`(instr) + 4B 주소 + 1B dummy + 4B 데이터 + 1B 상태(bit2=timeout, bit1:0=RRESP)
- AXI4 응답 코드: OKAY(0b00), EXOKAY(0b01), SLVERR(0b10), DECERR(0b11), 타임아웃(별도 bit)
- 주소/데이터 폭: 32비트 고정

## 검증·재현성

- 시뮬레이션: OSVVM 기반 VHDL-2008 테스트 스위트(`tb/`), Aldec Riviera-Pro 사용
- 실행: `sim/` 디렉터리에서 `source StartUp.tcl → build OsvvmLibraries → build SPI → build RunAllTests.pro`
- FPGA 보드: 명시 없음(벤더·보드 중립)
- 보드 실증: unverified(GitHub README에 없음)

## 한계·위험

- RPi 직접 사용 예제 없음: 파이썬 spidev 호스트 측 코드는 별도 작성 필요
- 타임아웃 플래그: 슬레이브 응답이 늦으면 bit2 세트 — AXI 슬레이브 레이턴시 주의
- Mode 3 테이블 오류 가능성: README가 idle clock=0으로 표기했으나 CPOL=1이 맞음(내 판단: 오타)
- airhdl 레지스터 생성 도구 없이 쓸 때는 AXI4-Lite 슬레이브를 별도 작성해야 함

## 재사용 메모

- Basys3 Pmod 포트(3.3V)에 RPi SPI0(MOSI/MISO/CLK/CE)을 직결하면 11바이트 SPI 거래로 AXI4-Lite 레지스터 R/W 가능. 추가 레벨 변환 불필요
- 테스트 환경: RPi Python `spidev` + 이 IP → MicroBlaze V AXI4-Lite 슬레이브 IP를 보드 없이 RPi에서 자동 테스트하는 CI 하네스 구성 가능
- 개조: `free_slots` 중 하나에 이 브리지를 AXI4-Lite 슬레이브로 등록하면 MicroBlaze V가 아닌 RPi가 버스 마스터가 됨. 단, AXI 인터커넥트에서 두 마스터(CPU·SPI 브리지)를 중재하는 arbiter 추가 필요. 단독 테스트 모드는 MicroBlaze V 없이 SPI 브리지만 연결해 주변장치 IP 검증 가능.
