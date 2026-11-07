---
name: hiteshtp09-verilog-softmax-accelerator
url: https://github.com/hiteshtp09/Verilog-Softmax-Accelerator
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Icarus Verilog, GTKWave, Yosys]
bus: none
peripherals: []
stage: T0
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-07
sources: [https://github.com/hiteshtp09/Verilog-Softmax-Accelerator]
---

## 요약

N입력 Softmax 가속기 IP. FSM 5단계(IDLE → FIND_MAX → EXP_SUM → NORMALIZE → FINISH)로 구성되며, LUT 기반 exp(-d) 근사를 사용한다. 보드 지정 없이 순수 Verilog RTL로 작성되었고 Icarus Verilog·Yosys로 검증한다.

## 구조

- **입력 형식**: 부호 있는 Q8.8 고정소수점(scale 256). 예: 1.5 → 384, -2.0 → -512
- **FSM 단계**:
  - FIND_MAX: 가장 큰 로짓을 찾아 각 입력에서 뺀다(수치 안정화용 max-subtraction)
  - EXP_SUM: LUT로 exp(-d) 근사, 1/16 간격 샘플, 하위 4비트로 선형 보간. d ≥ 16.0이면 0 처리
  - NORMALIZE: exp 값을 합으로 나눠 Q1.15(scale 32768) 확률 출력. 출력 scale 65535
  - FINISH: done 신호 단언
- **파일**: `rtl/softmax.v`(RTL), `testbench/softmax_tb.v`(VCD 출력), `simulation/`, `synthesis/`, `schematic/`
- **합성 통계(Yosys)**: 46,148 generic logic cells, 구조 검사 오류 0건. Sky130 기술 매핑 미완성

## 검증·재현성

- Icarus Verilog로 `softmax_tb.v` 실행 → `softmax.vcd` 생성 후 GTKWave 확인
- 테스트 로짓 [27, 21, 23, 19]: RTL 출력 ≈ 0.979324, 0.002426, 0.017929, 0.000336 (합 ≈ 1.0, 65536 기준)
- Yosys `synth → check → stat` 오류 없음
- 물리 FPGA 합성(XDC, 배치·배선, 타이밍) 미수행

## 한계·위험

- 특정 보드/FPGA 미지정: XDC, 클럭, I/O 래퍼 없음
- LUT 근사로 d ≥ 16.0 차이는 0으로 처리 → 로짓 차이가 큰 경우 소수 클래스 확률 소실
- argmax(최대 클래스 선택)는 미구현; 소프트맥스 출력값만 반환
- 라이선스 미확인: 소스 사용 전 LICENSE 파일 확인 필요
- Yosys 추정치는 Vivado 실제 LUT/FF와 다를 수 있음

## 재사용 메모

Basys3 MicroBlaze V SoC에서 추론 파이프라인 말단에 Softmax IP로 통합 가능. FSM 구조가 명확하고 LUT exp 근사는 작은 BRAM 없이 구현 가능하다는 점이 Basys3에 유리하다.

개조: MicroBlaze V AXI4-Lite 래퍼 추가 필요. ① AXI slave 레지스터로 N개 로짓 로드 → ② 추론 트리거 비트 → ③ 소프트맥스 완료 인터럽트 → ④ 확률 레지스터 읽기. argmax는 별도 combinational 블록(10개 비교기)으로 추가. `integration.frozen_mapping` 슬롯 1개 필요. 옮길 수 없는 부분: LUT 크기와 고정소수점 스케일은 클럭 주파수 및 타이밍에 따라 재조정 필요.
