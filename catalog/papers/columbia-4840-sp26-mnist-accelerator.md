---
name: columbia-4840-sp26-mnist-accelerator
url: https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/MNIST-Accelerator.pdf
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: none(ARM HPS 제어, 가속기 RTL 별도)
language: SystemVerilog
tools: [Quartus, Qsys, Icarus Verilog]
bus: Avalon-MM
peripherals: []
stage: T3
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-04-17}
doc_language: en
verification: L3
checked_at: 2026-11-07
sources: [https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/MNIST-Accelerator.pdf]
---

## 요약

Columbia CSEE 4840 Spring 2026 최종 프로젝트. DE1-SoC(Cyclone V)에서 MLP(784→128→10) MNIST 추론 가속기를 구현한다. **소프트맥스 없이 순수 argmax(10사이클 선형 스캔)로 분류 결과를 출력**하고 7세그먼트에 표시한다. 추론 약 4ms, 샘플 10개 중 9개 정답.

## 구조

- **모듈**: `mnist_accel.sv` 단일 파일(약 610줄). Avalon-MM 슬레이브, 6개 BRAM, FSM, MAC 데이터패스, argmax 비교기, HEX 디코더 포함
- **argmax 회로**: 10사이클 순차 스캔, `>` 엄격 비교(numpy tie-breaking 일치), scale-invariant(정규화 불필요)
- **고정소수점**: 픽셀 INT8(-128~127), 가중치 INT8(대칭 양자화), FC1 누산기 INT32, FC2 누산기 INT48
- **메모리맵(Avalon-MM 오프셋)**:
  - 0x00: CMD(bit0=시작), STATUS(bit1=완료)
  - 0x08: RESULT[3:0] 예측 숫자(0~9)
  - 0x0C: CONFIDENCE (FC2 누산기 하위 32비트, 디버그용)
- **출력 인터페이스**: HEX0 7세그먼트(active-low), HEX1~5 소등
- **Helper**: `hex7seg.sv`(7세그 디코더), `tb_mnist_accel.sv`(자체 검증, 139개 중간값 단언)

## 검증·재현성

- 테스트벤치 `tb_mnist_accel.sv`: 이미지당 139개 단언, 자체 검증형
- Plan B 폴백: 가중치+이미지 비트스트림 내장, Linux 없이 약 1.3ms에 추론 시작
- Plan A: HPS Linux, `mnist_pick` 프로그램, `run_on_board.sh`로 가중치 로드 후 추론
- 보드 정확도: 10개 샘플 중 9개 정답(1개 오답 5→6, 부동소수점 모델 문제로 추정)
- Basys3 AXI4-Lite 포팅 시 AXI slave→Avalon slave 교체, ARM HPS 대신 MicroBlaze V SW 작성 필요

## 한계·위험

- Intel Qsys/Avalon-MM 전용: Xilinx AXI4-Lite로 포팅 필요
- INT48 누산기: Artix-7 DSP48E1(48비트) 1개로 직접 대응 가능하나 타이밍 확인 필요
- 소프트맥스 없음: 출력은 비정규화된 INT32/INT48 누산 값으로 확률 아님
- 보드에서 97%+ 정확도 미달성(10개 중 9개, 90%로 낮음); 모델 양자화 정밀도 한계
- 소스 코드 공개 저장소 미확인(보고서만 열람)

## 재사용 메모

10클래스 분류 출력 인터페이스의 직접 참고 사례. RESULT 레지스터(4비트) + CONFIDENCE 레지스터 구조는 MicroBlaze V AXI4-Lite IP 설계에 그대로 적용 가능하다.

개조: Basys3 MicroBlaze V 포팅 경로 ① Avalon-MM slave → AXI4-Lite slave (동결 맵 free_slot 배정) ② 6개 BRAM 접근 AXI → Vivado BRAM IP 교체 ③ argmax 로직은 vendor-neutral이므로 그대로 재사용 ④ HEX 디코더: Basys3 7세그 배선으로 XDC 수정 ⑤ HPS Linux 드라이버 → MicroBlaze V 폴링/인터럽트 드라이버로 교체. 옮길 수 없는 부분: Qsys 컴포넌트 기술자(`hw.tcl`), INT48 누산기 Avalon 타이밍 보장.
