---
name: chang-2015-rnn-fpga
url: https://arxiv.org/abs/1511.05552
source_type: paper
vendor: amd
board: [ZedBoard]
fit_basys3: needs-port
cpu: none(가속기, ARM 호스트 연결)
language: Verilog
tools: [Vivado, Xilinx SDK]
bus: AXI4
peripherals: [LSTM-cell, sigmoid-LUT, tanh-LUT]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2015-11-17}
doc_language: en
verification: L3
checked_at: 2026-11-07
sources: [https://arxiv.org/abs/1511.05552, https://arxiv.org/pdf/1511.05552]
---

## 요약

Purdue 대학 Chang et al. (2015)이 발표한 ZedBoard(Zynq-7020) 기반 LSTM 추론 가속기 논문. Q8.8 고정소수점, 13-구간 구분선형 sigmoid/tanh 근사를 사용하며 ARM 호스트와 AXI4로 연결한다. SW-only LSTM 대비 최대 21× 속도 향상을 보고한다.

## 구조

- 보드: ZedBoard (Zynq-7020: Artix-7 FPGA 부분 + ARM Cortex-A9 PS)
- 고정소수점: Q8.8 (16비트, 정수부 8비트 · 소수부 8비트)
- 활성화 함수: 13-구간 구분선형 근사(Piecewise-Linear Approximation, PLA)
  - 구간별 기울기와 오프셋을 LUT에 저장, 조합 논리로 출력 계산
  - sigmoid와 tanh 각각 별도 PLA
- 게이트 구조: 표준 LSTM (forget / input / candidate / output) + 최종 h_t 계산
- 행렬-벡터 곱: DSP48 기반 MAC, 가중치를 BRAM에 적재
- 호스트 인터페이스: ARM PS → AXI4 DMA → PL 가속기 (Zynq PS/PL 구조)
- 검증: 필기체 인식(TIMIT 발화 데이터셋) 작업에서 정확도·속도 측정
- 자원: 논문 Table III — LUT 7,852 / FF 4,328 / BRAM 36Kb×1 / DSP48 24개 (소형 LSTM 기준, 단일 셀)

## 검증·재현성

- 소스 코드 공개 없음(논문 전용)
- Vivado 2014/2015 흐름 기준 보고, Xilinx SDK로 ARM 호스트 소프트웨어 작성
- TIMIT 음성 인식 작업에서 Kaldi DNN-HMM 대비 비슷한 WER 달성
- 타이밍: 100 MHz 클럭, WNS 명시 없음

## 한계·위험

- 소스 코드 미공개 → 직접 재현 불가, 논문 설명에서 구조 추출만 가능
- Zynq PS(ARM)가 필수: 순수 FPGA(Basys3) 구현에는 PS 역할(가중치 로드, 제어 FSM)을 별도 RTL로 교체해야 함
- 2015년 논문으로 Q4.4, INT8 등 더 작은 포맷 비교 없음
- 단일 LSTM 셀 기준 자원 수치; 다층화 시 BRAM·DSP 비례 증가 예상

## 재사용 메모

구분선형 sigmoid/tanh PLA 아이디어가 핵심 기여. 구간 수·비트폭을 파라미터로 조절할 수 있어 Basys3(XC7A35T, 225 KB BRAM, 90 DSP48)에도 이식 가능한 경로가 있다.

개조: (내 판단) ARM PS 없이 MicroBlaze V 기반으로 옮기려면 ① 가중치 AXI4-Lite 슬레이브로 적재 ② 단일-타임스텝 FSM을 순수 PL로 구현 ③ 동결 맵 `free_slots`에 LSTM_CTRL 레지스터 배정. PLA sigmoid/tanh는 범용 조합 모듈로 분리해 `library/rtl/`에 추가 가능. 옮길 수 없는 것: AXI4 DMA(PS 전용), ARM 측 추론 루프 소프트웨어.
