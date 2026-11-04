---
name: taada33-basys3-spi
url: https://github.com/taada33/basys3-spi
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(SPI-subsystem)
language: SystemVerilog
tools: [Vivado]
bus: AXI4-Stream
peripherals: [SPI-master, SPI-slave, comm-spi]
stage: T2
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://github.com/taada33/basys3-spi]
---

## 요약

Basys3 FPGA를 대상으로 한 파라메트릭 SPI 마스터·슬레이브 서브시스템. SystemVerilog로 작성되었으며, AXI4-Stream 인터페이스, CDC(Clock Domain Crossing) 처리, 클래스 기반 검증 환경을 갖춘 고품질 구조.

## 구조

- 언어: SystemVerilog (클래스 기반 검증 환경 포함)
- 인터페이스: AXI4-Stream (SoC와의 연결용)
- 기능: 파라메트릭 SPI 마스터·슬레이브 서브시스템
- CDC: 클럭 도메인 교차 처리 명시 포함 (SPI SCLK ↔ 시스템 클럭 동기화)
- 검증: 클래스 기반(SystemVerilog class) 검증 환경
- 보드: Basys3 XDC 포함 추정
- unverified: 지원 SPI 모드 수(Mode 0~3 여부), 메모리맵, 최고 SCLK 주파수, 자원 사용 — 직접 열람 필요

## 검증·재현성

- 클래스 기반 SystemVerilog 검증 환경은 방법론적 완성도가 높으며, 커버리지 측정·랜덤 테스트가 가능하다.
- Basys3를 타깃으로 명시하여 XDC 제약과 Vivado 프로젝트가 포함되어 있을 가능성이 높다.
- unverified: 실제 CI, 자원 사용, WNS, 보드 동작 확인 여부 — 직접 열람 필요

## 한계·위험

- SystemVerilog: iverilog 1.2 이전 버전은 클래스 문법을 지원하지 않아 CI 환경에서 verilator 또는 Questa/Riviera 필요 가능성 있음.
- AXI4-Stream 인터페이스: 본 SoC의 AXI4-Lite와 다르므로 직접 버스 연결 불가. 중간에 AXI4-Stream-to-AXI4-Lite 변환 로직 필요.
- 라이선스 미확인: 반입 전 LICENSE 확인 필요.
- unverified: CPOL/CPHA 지원 모드, 파라미터 세부 목록, 패키지 의존 여부 — 직접 열람 필요

## 재사용 메모

Basys3 타깃 SPI 서브시스템 중 CDC와 클래스 기반 검증 환경을 갖춘 가장 체계적인 예제. 구조와 검증 패턴 참고 가치가 높다. 그러나 AXI4-Stream 인터페이스이므로 MicroBlaze V SoC에 연결하려면 AXI4-Stream FIFO IP(Vivado 제공)를 거치거나 직접 AXI4-Lite 슬레이브 래퍼를 작성해야 한다.

개조: SystemVerilog SPI 슬레이브 FSM의 사양(포트 이름, 타이밍, CPOL/CPHA 로직)을 추출(§16.3)하여 Verilog-2001 AXI4-Lite 래퍼(`<slug>/rtl/spi_slave_axil.v`)로 재구현한다. AXI4-Stream → AXI4-Lite 변환은 하지 않고, 슬레이브 FSM 로직만 가져온다. `config/soc_address_map.json`의 `free_slots` 한 칸에 배정. CDC 처리 패턴(SCLK → sys_clk 동기화 2단 플립플롭)은 그대로 적용 가능.
