---
name: enjoy-digital-litex-rp2040-pmod-test
url: https://github.com/enjoy-digital/litex_rp2040_pmod_test
source_type: repo
vendor: neutral
board: [iCEBreaker]
fit_basys3: needs-port
cpu: none(RP2040 SPI host + iCE40 FPGA)
language: Python
tools: [LiteX, Migen, MicroPython]
bus: SPI → Wishbone (또는 AXI-Lite 선택 가능)
peripherals: [SPI-master-RP2040, SPIBone-bridge, Wishbone-master, LED-chaser]
stage: T3
license: BSD-2-Clause
stats: {stars: 28, forks: 2, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/enjoy-digital/litex_rp2040_pmod_test]
---

## 요약

WaveShare RP2040-Zero 모듈이 PMOD로 iCEBreaker FPGA에 꽂혀 SPIBone 프로토콜을 통해 LiteX SoC의 Wishbone 레지스터를 MicroPython에서 R/W하는 개념 증명. `spibone_gen.py`로 Wishbone 또는 AXI-Lite 선택 가능. 라즈베리파이 Pico(RP2040) 계열이 FPGA 주변장치 테스트 호스트로 사용됨.

## 구조

- 호스트 (RP2040-Zero PMOD): MicroPython, `machine.SPI`, `test_spibone.py` 실행
  - SPIBone 프레임: 1바이트 cmd(0x0=write, 0x1=read) + 4바이트 주소 + 4바이트 값
  - 예시: ID 레지스터 `0x800` 읽기, LED 레지스터 `0x1000` 쓰기
- FPGA 측 (LiteX SoC on iCEBreaker iCE40UP5K):
  - `tec0117.py`: LiteX SoCCore + SPIBone 브리지를 Wishbone 마스터로 등록 + LED 체이서 추가
  - 클럭: 100 MHz 입력 → PLL 50 MHz 시스템 클럭
  - 버스: `add_wb_master(spibone)` — RP2040이 Wishbone 버스 마스터
- 단독 IP 생성: `spibone_gen.py --mode wishbone` 또는 `--mode hybrid-axi-lite` → 순수 Verilog/VHDL SPI 브리지 출력 가능 (LiteX 없이도 사용 가능)
- 추가 파일: `pyboard.py`(RP2040에 MicroPython 스크립트 전송)

## 검증·재현성

- 보드에서 RP2040 → iCEBreaker SoC 레지스터 R/W 동작 확인 (저장소 description에서 "Test of a RP2040 PMOD" 명시)
- 런타임 검증: MicroPython test 스크립트가 ID 레지스터 값과 LED 패턴 변화로 동작 확인
- CI: 미확인 (공식 CI 설정 파일 없음)
- unverified: 정확한 마지막 커밋 날짜, 자원 사용 수치

## 한계·위험

- iCEBreaker 전용 LiteX 빌드 스크립트: Basys3로 포팅하려면 LiteX Basys3 플랫폼 또는 독립 Verilog 브리지 사용 필요
- RP2040(Pico MCU)이 호스트: RPi4(Linux SBC+spidev) 패턴과 다름 — RPi4로 대체 시 MicroPython→spidev Python 변환 필요
- Wishbone 버스: MicroBlaze V AXI4-Lite와 직결 불가 — `hybrid-axi-lite` 모드나 별도 Wishbone-AXI 변환 필요
- LiteX/Migen 의존: 독립 Verilog 추출은 `spibone_gen.py`로 가능하나 RTL 검증은 별도 필요

## 재사용 메모

- SPIBone 프로토콜(1B cmd + 4B addr + 4B data, 9바이트 고정)은 단순하고 Basys3에서 AXI4-Lite 슬레이브 구현에 직접 매핑 가능
- `spibone_gen.py --mode hybrid-axi-lite` 출력을 Basys3 AXI4-Lite 슬레이브로 추출하면 MicroBlaze V `free_slots`에 등록 가능
- RPi4 측에서도 같은 9바이트 프레임을 `spidev.xfer2([cmd, a3, a2, a1, a0, d3, d2, d1, d0])`로 전송 가능
- 개조: `spibone_gen.py` AXI-Lite 출력 → Basys3 Pmod(MOSI/MISO/CLK/CS, 3.3V)에 RPi GPIO 직결 → Python spidev로 Basys3 AXI-Lite 주변장치 자동 테스트 하네스 구성. MicroBlaze V 없이도 RPi가 AXI 버스 마스터로 동작하는 단독 테스트 보드 패턴. `free_slots` 한 칸에 SPIBone 브리지를 배정하면 소프트웨어 테스트와 보드 테스트를 동일 환경에서 실행 가능.
