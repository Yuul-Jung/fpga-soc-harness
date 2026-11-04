---
name: arpitsingh7634-spi-master-slave
url: https://github.com/arpitsingh7634/SPI_Master_Slave
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(SPI-only)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [SPI-master, SPI-slave, comm-spi]
stage: T1
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://github.com/arpitsingh7634/SPI_Master_Slave]
---

## 요약

Basys3 FPGA 전용 8비트 SPI 마스터·슬레이브 Verilog 구현. Mode 0(CPOL=0, CPHA=0), MSB-first. 루프백 최상위 모듈과 테스트벤치, Basys3 XDC 제약 파일을 모두 포함한다. 수업 과제 수준의 단순 구조.

## 구조

- 모듈: SPI 마스터 모듈, SPI 슬레이브 모듈, 루프백 최상위(top) 모듈
- SPI 모드: Mode 0만 지원 (CPOL=0, CPHA=0, MSB-first)
- 데이터 폭: 8비트 고정
- 보드 제약: Basys3 XDC 파일 포함
- 테스트벤치 포함 (기능 검증용)
- unverified: 메모리맵, 클럭 주파수, SCLK 분주비 세부 사항 — 직접 열람 필요

## 검증·재현성

- Basys3 XDC 파일과 테스트벤치가 모두 포함되어 Vivado로 바로 빌드·시뮬레이션 가능하다고 추정 (검색 제목 기준).
- unverified: CI, 자원 사용(LUT/FF/BRAM), WNS, 실제 보드 동작 확인 여부 — 직접 열람 필요

## 한계·위험

- Mode 0 단독 지원 — Mode 1~3(CPOL=1 또는 CPHA=1) 사용 불가.
- 8비트 고정 — 가변 데이터 폭 불지원.
- 라이선스 미확인(`unknown`): 코드 반입 전 LICENSE 파일 확인 필요.
- unverified: 절대경로 하드코딩, 외부 IP 의존 여부 — 직접 열람 필요

## 재사용 메모

Basys3 XDC까지 포함된 완성형 SPI 슬레이브 FSM 예제. 슬레이브 모듈만 추출해 AXI4-Lite 래퍼로 싸면 MicroBlaze V SoC에 외부 MCU 인터페이스로 붙일 수 있다. 마스터 모듈은 Verilog 테스트벤치 마스터 시뮬레이터로 재활용 가능하며, 이 용도가 본 하베스트 주제([B3])의 핵심 필요 요소와 직접 대응한다.

개조: 슬레이브 FSM의 레지스터·제어 신호를 AXI4-Lite 슬레이브 래퍼(`axil_regs.v` 형식)로 감싸고, `config/soc_address_map.json`의 `free_slots` 중 하나에 배정한다. MicroBlaze V는 AXI4-Lite로 접근하고 외부 Arduino/STM32 SPI 마스터가 MOSI/MISO로 데이터를 교환하는 이중 인터페이스 구조. CPU-전용 인터럽트 방식(`cpu_irq_axil_spi.c`)만 MicroBlaze V 전용으로 격리; FSM 자체는 CPU 무관.
