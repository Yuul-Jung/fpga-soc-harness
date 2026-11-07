---
name: columbia-4840-sp26-mnist-accelerator
url: https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/MNIST-Accelerator.pdf
source_type: report
vendor: neutral
board: [DE1-SoC]
fit_basys3: needs-port
cpu: none(순차 MAC FSM)
language: SystemVerilog
tools: [Questa]
bus: Avalon-MM
peripherals: [MNIST-MLP, BRAM-weight, argmax]
stage: T4
license: unknown
stats: {last_update: 2026}
doc_language: en
verification: L3
checked_at: 2026-11-08
rechecked_at: 2026-11-07
sources: [https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/MNIST-Accelerator.pdf]
---

## 요약

Columbia CSEE 4840 2026년 봄 학기 과제. DE1-SoC(Cyclone V, 50 MHz)에서 784→128→10 MLP를 INT8/INT32 고정소수점으로 구현. 순차 MAC 1개로 모든 레이어를 직렬 계산하며 가중치를 BRAM에 저장($readmemh). Avalon-MM 8레지스터 인터페이스.

## 구조

- 보드: DE1-SoC (Cyclone V 5CSEMA5F31), 50 MHz.
- MLP: 784→128→10, FC1 뒤 ReLU, FC2 뒤 argmax.
- 고정소수점: 입력 INT8(픽셀−128), 가중치 INT8(대칭 양자화), 편향 INT32, FC1 누산 INT32, FC2 누산 INT48.
- 단일 순차 MAC: BRAM의 2사이클 읽기 지연에 맞춰 클럭당 1 MAC. 추론 1회 약 4.1 ms.
- 가중치 적재: HPS 소프트웨어가 SD 카드에서 읽어 LOAD_DATA 레지스터에 바이트별 스트리밍. `$readmemh` 플랜 B 모드도 지원(HPS 없이 자동 추론).
- 최상위 `mnist_accel` 모듈: 오프셋 0x40(HPS 브릿지 베이스 0xFF200000)에 배치.

## 레지스터 맵 (Avalon-MM 32비트, 오프셋 ×4)

| 오프셋 | 이름 | 접근 | 용도 |
|--------|------|------|------|
| 0x00 | CONTROL | W | start, load_mode, clear_done |
| 0x04 | STATUS | R | busy, done(sticky) |
| 0x08 | RESULT | R | 예측 숫자[3:0] |
| 0x0C | CONFIDENCE | R | FC2 최대 누산값(하위 32비트) |
| 0x10 | LOAD_ADDR | R/W | 대상 로컬 쓰기 인덱스 |
| 0x14 | LOAD_DATA | W | 스트리밍 데이터 포트 |
| 0x18 | LOAD_TARGET | W | 대상 메모리 선택 |
| 0x1C | VERSION | R | 식별자 상수 |

## 자원 사용 (Cyclone V ALM 기준; Artix-7 LUT와 직접 비교 불가)

| 자원 | 사용 | 가용 | 점유 |
|------|------|------|------|
| ALMs | 957 | 32,070 | 3% |
| 레지스터 | 1,617 | — | — |
| BRAM bits | 827,840 | 4,065,280 | 20% |
| M10K 블록 | 104 | 397 | 26% |
| DSP (27×27) | 8 | 87 | 9% |

내 판단: 827 Kb ≒ 103 KB BRAM. Basys3 총 BRAM 225 KB의 약 46%에 해당한다. 포팅 가능하나 타이밍 여유 필요.

## 검증·재현성

- Python `golden.py`: NumPy 정수 순방향 연산 추적.
- SystemVerilog testbench `tb_mnist_accel.sv`(Questa): 139개 중간값 비교, 0 불일치 조건.
- 플랜 B: `$readmemh`로 가중치 내장 후 HEX0에 결과 표시. 10개 샘플 중 9개 정답 확인(S3 수준).
- 소프트웨어: C 드라이버로 SD 카드 로딩 및 폴링 완료 감지.

## 한계·위험

- Cyclone V Avalon-MM 전용. AXI4-Lite 변환 없이는 MicroBlaze V에서 직접 사용 불가.
- 단일 순차 MAC → 4.1 ms/추론 (100 MHz 환경에서 약 2 ms 예상).
- Basys3 포팅 시 BRAM 46% 점유 고려 필요.

## 재사용 메모

- 레지스터 배치(CONTROL/STATUS/RESULT/CONFIDENCE/LOAD_ADDR/LOAD_DATA/LOAD_TARGET/VERSION) 패턴을 AXI4-Lite로 바꾸면 MicroBlaze V에서 직접 사용 가능.
- 개조: Avalon-MM → AXI4-Lite 슬레이브 교체. 클럭 50 MHz → 100 MHz 재타이밍. `$readmemh` 초기화 그대로 사용 가능. INT8/INT32 고정소수점 구조 그대로 이식. 편향 INT32는 MicroBlaze V의 32비트 AXI 버스와 직접 호환. 옮길 수 없는 것: Cyclone V DSP 블록 → Artix-7 DSP48E1 대체 필요(자동화 가능).
