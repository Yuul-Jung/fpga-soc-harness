---
name: libfpga-fpga-neuron
url: https://github.com/libfpga/fpga-neuron
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Verilator, Icarus Verilog, Yosys]
bus: none
peripherals: []
stage: T0-T1
license: MIT
stats: {stars: 1, commits: 3, last_update: 2026}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://github.com/libfpga/fpga-neuron]
---

## 요약

MIT 라이선스의 소규모 순수 Verilog-2005 단일 뉴런 라이브러리. Q4.4 고정소수점(8비트, ±8 범위, 1/16 해상도)으로 가중합을 계산하고, 18비트 누산기에서 포화 연산으로 Q4.4로 되돌린다. XOR 4-은닉-뉴런 데모(832 LUT4, 0 FF, 순수 조합 논리)와 293개 테스트 벡터(전체 XOR 망라 + 17×17 입력 쓸기)가 포함되어 있다.

## 구조

- Q4.4 포맷: 부호 1b + 정수 3b + 소수 4b = 8비트. 범위 ±7.9375.
- MAC 계산: 입력 Q4.4 × 가중치 Q4.4 → 16비트 곱, 뉴런당 여러 곱을 18비트 누산기에 더한 뒤, 오버플로 여부를 보고 Q4.4로 포화 반올림한다.
- 활성화 함수: 별도 모듈 (파일명 미확인, 연산 흐름은 README 기준).
- 계층 구조: `neuron.v`(단일 뉴런), `layer.v`(여러 뉴런 병렬), `network.v`(최상위 — 소스 직접 열람은 PROVENANCE_REQUIRED로 차단됨). unverified: `network.v` 내부 연결.
- 테스트 환경: Python 황금 모델(bit-exact)로 293개 벡터 생성 → Icarus/Verilator로 대조. `make test`로 구동.
- Yosys 합성 결과(XOR 데모, iCE40 대상 추정): 832 LUT4, 0 FF, 조합 논리만.

## 검증·재현성

- Icarus Verilog + Verilator 시뮬레이션 통과 (293개 벡터, bit-exact 비교). unverified: CI 여부.
- Yosys 합성: 832 LUT4, 0 FF (보드별 수치는 달라질 수 있음).
- xdc/Vivado 프로젝트 없음. `make test` 실행으로 시뮬레이션 가능.

## 한계·위험

- 커밋 수 3건, 스타 1 — 초기/실험 저장소.
- 소스 파일을 직접 열람하지 못함(PROVENANCE_REQUIRED): `network.v` 내부 구조와 활성화 모듈 세부는 unverified.
- 보드 타깃 미명시. xdc 없음. Vivado/Artix-7 호환 여부 불명.
- source_rev가 커밋 SHA인지 확인하지 못함 (메타 릴리스 필드에서 추출).
- 가중치는 `initial` 블록으로 하드코딩 추정 — 큰 네트워크로 확장 시 BRAM 사용으로 전환 필요.

## 재사용 메모

Q4.4 포화 MAC 커널과 293개 bit-exact 테스트 벡터가 핵심 자산. MIT 라이선스이므로 구조와 포트 사양은 자유롭게 참조 가능하다.

개조: MicroBlaze V SoC 적용 시 — ① Q4.4 포화 MAC 커널(`neuron.v`/`layer.v`)을 Verilog-2001로 재작성해 `library/rtl/`에 올린다. ② 최상위를 AXI4-Lite 슬레이브 래퍼로 감싸 동결 맵의 `free_slots`에 배정한다. ③ 가중치를 `initial` 블록에서 BRAM 초기화(`$readmemh`)로 전환하면 BRAM 타일 2~4개로 소규모 2층 MLP가 들어간다. ④ 테스트벤치는 Python 황금 모델과 bit-exact 비교 패턴을 그대로 차용할 수 있다. 옮길 수 없는 것: `network.v`의 가중치 하드코딩 구조(CPU 비종속이므로 사실 무관) — AXI 버스 쪽 연결만 새로 작성하면 된다.
