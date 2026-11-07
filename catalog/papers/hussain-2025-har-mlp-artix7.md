---
name: hussain-2025-har-mlp-artix7
url: https://journals.utm.my/aej/article/download/25257/9128/109555
source_type: paper
vendor: amd
board: [Artix-7-35T]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado 2024.2]
bus: none
peripherals: []
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://journals.utm.my/aej/article/download/25257/9128/109555]
---

## 요약

말레이시아 UTM Applied Engineering Journal(2025) 논문. Artix-7 35T(xc7a35ticsg324-1L)에서 7→6→5 MLP로 인간 행동 인식(HAR)을 구현. 16비트 Q8.8 고정소수점, ReLU6 활성화 함수, Vivado 2024.2. UCI HAR 데이터셋에서 약 94% 정확도. Basys3와 동일 칩 — 자원 기준점으로 활용 가능.

## 구조

- 아키텍처: 7(입력) → 6(은닉, ReLU6) → 5(출력) MLP
- 대상 FPGA: Xilinx Artix-7 35T, xc7a35ticsg324-1L (Basys3의 xc7a35tcpg236과 동일 칩, 패키지 다름)
- 고정소수점: 16비트 서명 Q8.8 (정수부 8비트, 소수부 8비트)
- 활성화: ReLU6 (8KB BRAM에 LUT로 저장)
- 버스: 없음 (독립형)
- 클럭: 50 MHz, WNS +3.722 ns
- 자원 사용 (Artix-7 35T 기준):

| 자원 | 사용 | 가용 | 비율 |
|---|---|---|---|
| LUT | 520 | 20,800 | 2.50% |
| FF | 964 | 41,600 | 2.32% |
| DSP | 2 | 90 | 2.22% |
| BRAM | 8 KB (ReLU6 LUT) | — | 최소 |

- 소비 전력: 67 mW 총합, 5 mW 동적

## 검증·재현성

- UCI HAR 데이터셋 3분할 테스트 정확도: 94.4% / 94.7% / 94.1% (초록 기준; 본문 2.2.5절과 소폭 차이 있음)
- Vivado에서 타이밍 클로저 확인 (50 MHz, +3.722 ns)
- HDL 테스트벤치 언급 없음 — 소프트웨어 모델 비교로 검증
- 소스 코드/GitHub 링크 미제공

## 한계·위험

- 아키텍처(7→6→5)가 매우 작아 MNIST(784→128→10) 규모 추론과 직접 비교 불가. 자원 수치는 하한 추정값으로만 사용해야 한다.
- 정확도 수치가 초록과 본문 2.2.5절 사이에 불일치 (94.0~95.3%)가 있어 측정 방법론 주의 필요.
- 패키지가 csg324(QFP)로 Basys3의 cpg236과 다름. 핀맵은 다르나 LUT/DSP/BRAM 수치는 동일하게 적용됨.
- 소스 코드 미공개.

## 재사용 메모

동일 Artix-7 35T 칩에서 Q8.8 직렬 MLP가 LUT 2.5%, FF 2.32%, DSP 2.22%만 사용한다는 것을 확인. MNIST MLP(784→128→10) 추론은 가중치 BRAM 소요량(약 100KB = BRAM18 약 6개)이 훨씬 크지만, MAC FSM 자체는 비슷한 LUT 규모에서 운용 가능하다.

개조: MicroBlaze V AXI4-Lite 슬레이브 래퍼로 연결 시 — ① HAR 7차원 입력을 MNIST 784차원으로 늘리면 입력 MUX 사이클이 길어지나 FSM 구조는 동일; ② ReLU6 LUT BRAM은 단순 ReLU(임계치 비교)로 대체하면 BRAM 절약; ③ 출력 5→10으로 확장. CPU 비종속 MAC-FSM 패턴 직접 이식 가능. Artix-7 35T 자원 여유 확인 완료.
