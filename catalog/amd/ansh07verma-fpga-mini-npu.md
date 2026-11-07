---
name: ansh07verma-fpga-mini-npu
url: https://github.com/ansh07verma/fpga-mini-npu
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(시스톨릭 어레이 가속기)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [NPU-MAC, systolic-array]
stage: T4
license: MIT
stats: {stars: unknown, last_update: 2025}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://github.com/ansh07verma/fpga-mini-npu]
---

## 요약

Basys3(XC7A35T) 대상 INT8 2단계 파이프라인 MAC 기반 2×2/4×4 가중치 고정 시스톨릭 어레이 NPU. AXI 인터페이스는 미구현이고 테스트벤치 직접 로딩 방식이다. MIT 라이선스.

## 구조

- 보드: Basys3 XC7A35T, 100 MHz
- MAC 단위: `mac_unit.v` — INT8 곱셈 + 24비트 누산기, 2사이클 파이프라인. `(* use_dsp = "yes" *)` pragma.
- PE(`pe.v`): 가중치 고정(weight-stationary) 처리 요소.
- 어레이: `systolic_array_2x2.v`, `systolic_array_4x4.v` — 파라미터화 가능.
- 버퍼: `input_buffer.v`(행렬 A 레지스터 파일), `weight_buffer.v`(행렬 B), `output_buffer.v`.
- FSM: `controller_fsm.v` — IDLE→LOAD_W→CLR→COMPUTE one-hot 4상태.
- 최상위: `npu_top.v`.
- **AXI4-Lite 없음**: 현재 테스트벤치 직접 입력. AXI4-Stream은 future work.

## 자원 사용 (Vivado, XC7A35T, 합성 결과)

| 어레이 | Slice LUTs | Flip-Flops | DSPs(구현) | 지연(cycles) |
|--------|-----------|-----------|-----------|------------|
| 2×2 | 391 (1.9%) | 229 (0.6%) | 4 | 9 |
| 4×4 | 1,801 (8.7%) | 1,258 (3.0%) | 16 | 17 |

- BRAM: 0 (레지스터 파일 구현).
- 4×4 후배치 WNS: +0.153 ns (100 MHz 충족).
- 4×4 처리율: 170 ns/matmul.

## 검증·재현성

- 테스트벤치: `tb_mac_unit`(9/9 PASS), `tb_systolic_4x4`(80/80), `tb_npu_top`(64/64).
- Python: `golden_model.py`(NumPy 참조), `gen_test_vectors.py`, `fixed_point_utils.py`(INT8/Q8.8 헬퍼).
- 시뮬레이션 스크립트: `scripts/sim.ps1`, 합성: `scripts/synth.tcl`.
- VCD 파형과 로그: `results/simulation_logs/`.

## 한계·위험

- **AXI 미구현**: MicroBlaze V에서 직접 사용 불가. AXI4-Lite 래퍼 추가 필요.
- MLP 추론 흐름(레이어 연결, 활성화, 편향) 없음. 행렬 곱셈 블록만 구현.
- 보드 동작 확인(S3) 기록 없음.
- 라이선스: MIT.

## 재사용 메모

- INT8 MAC 2사이클 파이프라인 구조(mac_unit.v), controller FSM 상태 설계가 참고 가치 있다.
- 개조: AXI4-Lite 슬레이브 래퍼를 추가하면 MicroBlaze V에서 가중치 로드·추론 트리거·결과 읽기가 가능하다. 행렬 곱셈 → FC 레이어로 활용 가능. 버스: AXI4-Lite로 교체. 인터럽트: `free_slots` 슬롯 배정 후 INTC 연결. AXI4-Stream(현재 future work)보다 AXI4-Lite 슬레이브가 MicroBlaze V C 드라이버와 더 직접적으로 연결된다.
- Basys3 BRAM 0% 사용 — BRAM 대역폭을 MLP 가중치 저장에 추가 활용 가능.
