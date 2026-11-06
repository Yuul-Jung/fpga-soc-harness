---
name: erwanregy-neural-network-fpga
url: https://github.com/erwanregy/Neural-Network-on-an-FPGA
source_type: repo
vendor: neutral
board: [Zynq-7000]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [Vivado]
bus: none
peripherals: []
stage: T2-T3
license: Apache-2.0
stats: {stars: 17, commits: 36, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://github.com/erwanregy/Neural-Network-on-an-FPGA]
---

## 요약

Apache-2.0 라이선스의 파라메트릭 SystemVerilog MLP 가속기. `DATA_WIDTH`(비트 폭), `SIZES`(레이어별 뉴런 수 배열), `ACTIVATIONS`(레이어별 활성화 함수: `ReLU`/`sigmoid`), `NUM_NEURONS`를 파라미터로 받아 임의 레이어 구조를 합성할 수 있다. 상태 기계로 순전파를 단계별로 수행하고, 가중치와 바이어스는 `initial` 블록에 하드코딩되어 있다. Zynq-7000 타깃으로 개발됐으나 로직 아키텍처는 벤더 중립적이다.

## 구조

- 최상위 파라미터: `DATA_WIDTH`, `SIZES` 배열, `ACTIVATIONS` 배열, `NUM_NEURONS`.
- 상태 기계 단계: `waiting → multiplying → accumulating → activating → done`.
- 활성화 함수: ReLU(부호 비트 마스킹)와 sigmoid(LUT 또는 선형 근사 — 세부 unverified).
- 클럭: 1 ns 클럭 (테스트벤치 기준). 보드 클럭 주파수 unverified.
- 가중치·바이어스: `initial` 블록에 하드코딩. 큰 네트워크는 BRAM `$readmemh`로 전환 필요.
- 소스 파일 직접 열람 차단(PROVENANCE_REQUIRED) — 포트 목록과 모듈 계층은 README 및 검색 요약 기준. unverified: MAC의 비트 폭 성장(word growth) 처리 방식, 포화 연산 여부.
- 자원 사용 수치: unverified (보고된 LUT/FF 없음).

## 검증·재현성

- Vivado 시뮬레이션으로 기능 검증한 것으로 보임(README 기준). unverified: 테스트벤치 세부, CI 여부.
- xdc 제공 여부 unverified. Basys3용 핀 매핑 없음.
- 합성 성공 여부 unverified (Zynq-7000 타깃 추정). Artix-7로 이식 시 IP 교체 불필요(순수 RTL 추정).

## 한계·위험

- 소스 파일 직접 열람 불가 — 비트 폭 성장(word growth), 포화, 활성화 LUT 세부 미확인.
- `initial` 블록 가중치: Vivado에서 합성 가능하나, 실제 합성 여부와 FPGA 구현 시 동작 unverified.
- SystemVerilog 사용 — iverilog 2012 미만은 일부 구문 미지원.
- 스타 17, 커밋 36 — 소규모 학습·실험 프로젝트.
- Zynq 하드 코어(PS)에 의존하지 않는지 unverified.

## 재사용 메모

파라미터 하나로 레이어 구조 전체를 지정하는 설계 패턴이 핵심 자산. 레이어별 활성화 선택(ReLU/sigmoid) 파라미터화 방식은 D-ReLU 등 다른 활성화 함수로 교체할 때의 기준 구조가 된다.

개조: MicroBlaze V SoC 적용 시 — ① SystemVerilog 파라메트릭 패턴을 Verilog-2001 `generate`/`parameter`로 재작성한다. ② `DATA_WIDTH`, `SIZES`, `ACTIVATIONS`를 AXI4-Lite 슬레이브 래퍼의 레지스터로 연결하거나, 합성 시 파라미터로 고정한다. ③ 가중치를 `$readmemh`로 BRAM에 올려 동결 맵 `free_slots` 한 칸(64KB)으로 주소를 배정한다. ④ word growth 처리(§ gisselquist-zipcpu-bit-growth 참조)를 명시적으로 추가하고, 포화 연산을 넣어야 한다 (현재 미확인). 옮길 수 없는 것: `initial` 블록 하드코딩 가중치(BRAM 전환 필수) — CPU 연결 없이도 작동하므로 AXI 래퍼만 추가하면 된다.
