---
name: unlv-si-harris-drelu-fpga-mlp
url: https://oasis.library.unlv.edu/ece_fac_articles/1052/
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: []
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://oasis.library.unlv.edu/ece_fac_articles/1052/, https://doi.org/10.4236/jcc.2020.812021]
---

## 요약

UNLV(네바다대 라스베이거스)의 2020년 논문. "Neural Networks on an FPGA and the Exploration of Hardware Friendly Activation Functions" (Jiong Si, Sarah L. Harris, Evangelos Yfantis). *Journal of Computer and Communications*, Vol. 8, No. 12, pp. 251–277. DOI: 10.4236/jcc.2020.812021. FPGA에서 D-ReLU(Double-sided ReLU)가 sigmoid보다 면적 24~41% 감소, 정확도 손실 없음을 실험으로 보였다. 2층·3층 MLP로 MNIST를 분류하고, 8비트 vs 4비트 고정소수점의 트레이드오프도 분석했다.

## 구조

- 대상 작업: MNIST 손글씨 숫자 분류 (10클래스).
- 네트워크 구조: 2층 MLP(실험 주력)와 3층 MLP.
- 고정소수점: 8비트(주력)와 4비트(면적 비교).
- 활성화 함수 비교: sigmoid, ReLU, D-ReLU(일종의 Leaky ReLU 변형).
- D-ReLU 정의: 양의 구간 패스스루, 음의 구간 소폭 감쇠(하드웨어 한두 비트 시프트). 조건 비교와 비트 시프트만으로 구현 — 곱셈기 없음.
- FPGA 구현: Vivado 합성. 보드명 명시 없음(논문 텍스트 전체 unverified — 오픈 액세스 HTML 기준 발췌).
- 소프트웨어 대비 29× 처리 속도 향상 보고.

## 검증·재현성

- 논문 실험 결과 기준: D-ReLU 면적 24~41% 감소 (sigmoid 대비), 정확도 손실 없음.
- 8비트 → 4비트: 면적 추가 감소, 정확도 소폭 하락 (구체 수치 unverified — 논문 본문 직접 확인 필요).
- 소스 코드 공개 여부 unverified. DOI 경유 접근 가능.

## 한계·위험

- 소스 코드 공개 없음(추정). 재현 시 논문 기반 재작성 필요.
- 보드/FPGA 명시 여부 unverified (논문 본문 직접 열람 필요 — 오픈 액세스 경로로 일부만 확인).
- 라이선스 unknown. MNIST 데이터셋 라이선스는 별도.
- 2020년 논문 — 최신 경량 활성화 함수(GELU, SiLU 등)와의 비교 없음.

## 재사용 메모

D-ReLU가 면적을 24~41% 줄인다는 측정 결과와, FPGA에서 비트 시프트만으로 구현하는 방법이 핵심 근거다. 2층 MLP를 Basys3 LUT 범위 내에서 구현할 때, 활성화 함수로 sigmoid 대신 D-ReLU를 선택할 근거 논문으로 사용한다.

개조: MicroBlaze V SoC 적용 시 — ① D-ReLU 활성화 모듈을 Verilog-2001로 작성한다(부호 비트 검사 + 조건부 비트 시프트, 약 10줄). ② `erwanregy-neural-network-fpga`의 `ACTIVATIONS` 파라미터 슬롯에 D-ReLU를 추가하거나, `libfpga-fpga-neuron`의 활성화 단계에 연결한다. ③ 2층 MLP + D-ReLU 조합을 AXI4-Lite 슬레이브로 감싸 동결 맵 `free_slots` 한 칸에 배정한다. ④ 테스트벤치에서 sigmoid 버전과 LUT/FF 사용량을 비교해 논문 결과를 재현한다. 옮길 수 없는 것: 소스 코드 없으므로 논문 사양에서 RTL 직접 작성 필요; MNIST 가중치는 Python 훈련 후 `$readmemh`로 올려야 한다.
