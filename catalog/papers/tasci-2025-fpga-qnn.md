---
name: tasci-2025-fpga-qnn
url: https://mdpi.com/2076-3417/15/2/688
source_type: paper
vendor: amd
board: [PYNQ-Z1]
fit_basys3: needs-port
cpu: none(HLS)
language: HLS
tools: [FINN, Vivado]
bus: AXI
peripherals: []
stage: T4
license: CC-BY-3.0
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://mdpi.com/2076-3417/15/2/688]
---

## 요약

MDPI Applied Sciences 2025, 15(2), 688. 터키 Bursa Uludag 대학교 Tasci 외. FINN 프레임워크로 MLP(512→256→10)와 LeNet-5를 PYNQ Z1(Zynq 7020)에 W1A1/W1A2/W2A2 양자화로 배포. MNIST MLP 90%(FPGA), LeNet-5 95.4%(FPGA). CC BY 3.0.

## 구조

- 아키텍처: MLP Flatten→512→256→10; LeNet-5(conv2+pool2+fc3)
- 양자화: W1A1(가중치 1비트, 활성화 1비트), W1A2, W2A2 세 가지 비교
- 도구 체인: PyTorch 훈련 → Brevitas 양자화 → FINN 컴파일러 → Vivado HLS/합성 → PYNQ Z1 배포
- 버스: AXI (Zynq PS-PL 연결)
- 대상 보드: PYNQ Z1 — Zynq XC7Z020 (PL: Artix-7 기반 85K LUT, 220 BRAM, 220 DSP)
- Fashion-MNIST, CIFAR-10에도 같은 흐름 적용

## 검증·재현성

MNIST 정확도 (FPGA 측정값):

| 모델 | 양자화 | FPGA 정확도 | CPU float 정확도 |
|---|---|---|---|
| MLP | W1A1 | ~90% | ~95% |
| MLP | W2A2 | ~90% | ~95% |
| LeNet | W1A1 | 95.4% | 98.3% |

- FINN이 합성·배포를 자동화하므로 Verilog 수준 RTL 소스는 미공개
- 자원 수치 미발췌(Tables 4–5 참조, 본문에서 "BRAM roughly doubling for W2A2 MLP" 언급)
- 소비 전력: 약 0.5 W 이상(Vivado 추정 대비 초과)
- Fashion-MNIST: 더 어려운 데이터셋이므로 주요 평가 대상으로 사용

## 한계·위험

- RTL 소스 없음(FINN 자동생성 블랙박스). Verilog 수준 커스터마이징 불가.
- PYNQ Z1 Zynq PS(ARM Cortex-A9)에 의존. Basys3에는 PS 없음.
- W1A1 MLP 정확도 90%는 ≥90% 경계값 — 정밀도 손실이 클 가능성.
- MNIST 성능 수치가 본문 표가 아닌 본문 설명에서 추출되어 정확한 소수점 수치 미확인.

## 재사용 메모

FINN 없이 순수 Verilog로 W1A2 MLP를 Basys3에 구현할 때의 아키텍처 참고 자료. 가중치 1비트라면 784×128 = 100,352비트 ≈ 12.3KB → BRAM18 1개 미만; AXI4-Lite로 MicroBlaze V에 연결하면 T4 캡스톤 가능.

개조: ① 양자화 W1A2: 가중치를 BRAM 대신 LUT-distributed로 저장 가능 → BRAM 절약; ② 활성화 2비트: 임계치 2개 비교(ReLU2-step)로 FSM 단순화; ③ PS 의존 제거: MicroBlaze V가 AXI4-Lite 슬레이브를 통해 가중치 로드+추론 트리거. FINN 프레임워크 자체는 Basys3에 직접 적용 불가(SDK 의존), 원리만 가져와야 한다.
