---
name: jakubcabal-spi-fpga
url: https://github.com/jakubcabal/spi-fpga
source_type: repo
vendor: neutral
board: [CYC1000 Intel Cyclone10 10CL025YU256C8G, EP4CE6 Starter Board EP4CE6E22C8]
fit_basys3: needs-port
cpu: none(peripheral controller)
language: VHDL
tools: [Modelsim, GHDL]
bus: none(raw SPI)
peripherals: [SPI-master, SPI-slave]
stage: T1
license: MIT
stats: {stars: 185, commits: 41, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://github.com/jakubcabal/spi-fpga]
---

## 요약

FPGA용 SPI 마스터와 슬레이브 컨트롤러를 VHDL 93으로 구현한 오픈소스 IP 라이브러리. SPI 모드 0(CPOL=0, CPHA=0)만 지원하며, MIT 라이선스로 상업적 재사용 가능. CYC1000(Cyclone 10) 기준 자원 사용량이 README에 기록되어 있다.

## 구조

- 모듈: SPI 마스터 컨트롤러, SPI 슬레이브 컨트롤러 (각각 별도 RTL 파일)
- SPI 모드: 모드 0 전용(CPOL=0, CPHA=0). 다른 모드 미지원 명시
- 버스 인터페이스: AXI-Lite 없음; 순수 직렬 SPI 신호만 노출
- 예제 설계: `spirit_level`(기울기 센서 활용), `loopback`(자기 송수신 테스트)
- 테스트벤치: GHDL(`spi_master_tb_ghdl_run.sh`, `spi_slave_tb_ghdl_run.sh`), Modelsim(.tcl) 모두 제공
- CI: `.github/workflows` 존재(내용 미확인)
- 대상 보드: CYC1000 · EP4CE6 Starter Board. "어떤 FPGA에도 적용 가능"이라고 명시

## 검증·재현성

- MIT 라이선스로 사양 추출 및 Verilog 재구현 모두 가능(§16.3 G0)
- GHDL 오픈소스 테스트벤치 제공 → CI 환경에서 직접 실행 가능
- 자원 사용: README에 Cyclone 10 기준 수치 있으나 이번 열람에서 구체 수치 미획득
- unverified: 커밋 최신 날짜, CI 통과 여부, 정확한 LUT/FF 수치

## 한계·위험

- SPI 모드 0만 지원. 일부 센서·AD 변환기는 모드 1·3 필요 — 사용 전 타겟 디바이스 모드 확인 필요
- VHDL 93으로 작성 → Verilog 프로젝트에 통합 시 혼용 컴파일 설정 또는 Verilog 재구현 필요
- RPi와 직접 연결하는 예제 없음; 조합 시 전압 레벨(3.3V ↔ 5V 주의) 별도 설계 필요
- Basys3용 xdc·Vivado 프로젝트 없음 → 핀 할당과 클럭 제약 직접 작성 필요

## 재사용 메모

- SPI 슬레이브 모듈을 Verilog-2001로 포팅하여 Basys3 Pmod 포트에 연결 가능
- RPi SPI 마스터(`spidev`)와 조합하면 "RPi 호스트 → Basys3 FPGA 레지스터 R/W" 디버그 창구 완성
- 개조: VHDL → Verilog-2001 포팅 후, AXI4-Lite 슬레이브 래퍼(`config/ip_standard.json`)를 씌워 MicroBlaze V에 연결. SPI 모드 0 가정이 맞는 센서(ADXL345, MAX7219 등)에 재활용 가능. 모드 0 외 필요 시 FSM 타이밍 로직 수정(CPHA 샘플·전이 타이밍 반전).
