---
name: mnemocron-axi-perf-counter-pattern
url: https://github.com/mnemocron/axi-perf-counter-pattern
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Vivado 2021.2, GHDL 3.7]
bus: AXI4-Lite
peripherals: [performance-monitor]
stage: T2
license: unknown
stats: {stars: 2, forks: 1, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://github.com/mnemocron/axi-perf-counter-pattern, https://repos.ecosyste.ms/hosts/GitHub/repositories/mnemocron%2Faxi-perf-counter-pattern]
---

## 요약

AXI Stream 인터페이스 사이의 클럭 사이클 레이턴시를 패턴 매칭 트리거로 측정하는 VHDL IP 패키지. Xilinx Vivado 2021.2 + GHDL 3.7로 검증. `axi_dma_0` IP 모니터링 예제 포함.

## 구조

- **IP 코어 3종**:
  1. `axi_event_counter`: start/stop 트리거 신호 사이의 클럭 사이클 수를 계수하는 메인 카운터
  2. AXI4 W채널 패턴 트리거: `wdata` 버스의 4바이트 패턴 일치 시 start/stop 이벤트 발생 (바이트 정렬 비교)
  3. AXI Stream TDATA 패턴 트리거: `tdata` 채널의 패턴 일치 시 이벤트 발생 (폭: `C_S_AXIS_TDATA_WIDTH` 파라미터)
- **측정 방식**: 패턴 감지(`trg_a`) → 패턴 감지(`trg_b`) 사이의 클럭 주기 수 → AXI-Lite 레지스터로 읽기
- **제한**: 비교 패턴 하드코딩 4바이트 (`C_S_AXI_DATA_WIDTH`), Ethernet 패킷(빅엔디언)과 MicroBlaze(리틀엔디언) 간 바이트 순서 주의 사항 명시
- **커밋**: 11개 (main 브랜치), 별 2, 포크 1

## 검증·재현성

- GHDL 3.7 시뮬레이션 + Xilinx Vivado 2021.2에서 구현·테스트 완료 (L3 직접 열람)
- Xilinx Vivado IP Packager로 패키징된 3개 IP 코어 포함
- 특정 보드 명시 없음; Vivado 타깃 FPGA 불명 (`source_rev` 미확인: PROVENANCE_REQUIRED)
- 라이선스 미명시 — 코드 복사 전 확인 필요

## 한계·위험

- VHDL 전용 (Verilog 환경에선 래퍼 작성 필요)
- 측정 트리거가 AXI Stream TDATA 또는 AXI W채널 wdata 패턴에만 국한 (AR/AW/R/B 채널 레이턴시 직접 측정 불가)
- 패턴 폭 고정(4바이트); 가변 패턴 불가
- 별 2, 커밋 11개로 소규모 프로젝트; 실 사용 사례 부족
- 라이선스 미명시: `license: unknown`으로 기록, 코드 재사용 전 확인 필요

## 재사용 메모

VHDL로 작성돼 있어 Basys3 Verilog 환경에서 직접 사용하려면 래퍼 모듈이 필요하다. 그러나 패턴 매칭 기반 레이턴시 측정의 아이디어(start/stop 트리거 → 카운터)는 Verilog로 재구현하기 간단하다.

개조: `axi_event_counter` 핵심 로직(32비트 카운터, start/stop 트리거)만 Verilog로 재작성하면 약 30~50줄. W채널 패턴 감지 대신 AXI-Lite wvalid & wready를 start 트리거, bvalid & bready를 stop 트리거로 삼으면 MicroBlaze V의 쓰기 왕복 레이턴시를 직접 측정할 수 있다. 측정값을 AXI-Lite 읽기 레지스터에 연결하면 C 드라이버로 주기적 샘플링 가능. 옮길 수 없는 것: Xilinx VHDL IP Packager 의존 패키징 (Verilog 재작성으로 우회), Ethernet 엔디언 고려 (MicroBlaze의 AXI-Lite는 리틀엔디언이므로 패턴 비트 순서 역전 불필요).
