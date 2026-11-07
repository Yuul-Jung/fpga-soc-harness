---
name: khoda-2023-hls4ml-gru-lstm
url: https://par.nsf.gov/biblio/10419986
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(가속기, hls4ml 생성)
language: HLS(C++)
tools: [hls4ml, Vivado HLS]
bus: none
peripherals: [GRU-cell, LSTM-cell]
stage: T4
license: Apache-2.0
stats: {stars: 0, commits: 0, last_update: 2023-04-10}
doc_language: en
verification: L3
checked_at: 2026-11-07
rechecked_at: 2026-11-07
sources: [https://par.nsf.gov/servlets/purl/10419986, https://arxiv.org/abs/2207.00559]
---

## 요약 (3줄 이내, 내 표현으로)

Khoda et al. (UW·MIT·Stanford·CERN 등, 2023, Machine Learning: Sci & Tech vol. 4, 025004)이 hls4ml 프레임워크로 GRU/LSTM을 Kintex UltraScale·Alveo U250에서 초저지연 추론. 최저 1.7 µs 달성(탑쿼크 태깅). GRU가 LSTM보다 ~1/4 자원 적게 사용(MVM 3 vs 4 비율). 소스: github.com/fastmachinelearning/hls4ml (Apache-2.0).

## 구조

- 보드: Xilinx Kintex UltraScale xcku115-flvb2104-2-i (탑쿼크·제트 플레이버 태깅), Xilinx Alveo U250 (QuickDraw 그림 분류)
- 클럭: 200 MHz (Vivado HLS 2019.2)
- GRU 게이트: update gate + reset gate (2개). LSTM 게이트: forget/input/candidate/output (4개)
- MVM 수: GRU 3회, LSTM 4회 → GRU 자원 ~25% 절감
- 고정소수점: 훈련 후 양자화(PTQ). 소수부 최소 10비트 권장. 정수부 6비트(탑쿼크·플레이버), 10비트(QuickDraw)
- Reuse factor: 연산량 대 병렬도 트레이드오프 파라미터(hls4ml)

### 지연시간 비교 (hls4ml 추정, µs)

| 응용 / Reuse | GRU | LSTM |
|---|---|---|
| 탑쿼크 R=(6,5) | 2.4–6.5 | 2.7–6.8 |
| 탑쿼크 latency 전략 | 1.7 | 1.7 |
| 제트 플레이버 R=(48,40) | 6.7–24.8 | 6.9–25.0 |
| QuickDraw R=(48,32) | 35.4–164.0 | 35.9–164.0 |

- 자원(LUT/DSP/FF): 그림으로만 보고, 텍스트 수치 미공개. 논문은 "GRU가 LSTM보다 ~1/4 적은 자원 사용"으로 명시.
- 양자화 정확도: GRU는 LSTM보다 양자화 후 정확도 소폭 하락(5% 미만), 탑쿼크에서 가장 뚜렷.
- 도구: hls4ml (fastmachinelearning/hls4ml, Apache-2.0). PyTorch/Keras 모델 → Vivado HLS C++ 자동 생성.

## 검증·재현성

- 세 가지 물리 응용(탑쿼크 태깅, 제트 플레이버, QuickDraw)에서 GRU/LSTM 비교 실험 완료
- hls4ml GitHub 저장소(fastmachinelearning/hls4ml): RNN 지원 커밋 존재, 튜토리얼 노트북 포함
- 데이터셋: CERN Open Data, Zenodo, Quick Draw! 공개 데이터셋
- unverified: 실제 Verilog/VHDL 출력물 구조(hls4ml 내부 HLS C++ 생성 → Vivado HLS 처리)

## 한계·위험

- 타깃: Kintex UltraScale·Alveo U250 → Basys3(Artix-7 XC7A35T) 직접 이식 불가
- hls4ml이 생성하는 HLS C++를 Vivado HLS로 처리해야 하므로 순수 Verilog 환경에서 직접 사용 불가
- LUT/DSP/FF 수치가 그림 형식으로만 공개 → 카드 기재 불가, 직접 추론 필요
- 고성능 물리 추론 응용(LHC) 특화: 활성화 함수 테이블 범위가 범용과 다를 수 있음
- Vivado HLS 2019.2 기반 → 2024.2와 호환성 미확인

## 재사용 메모

핵심: hls4ml 프레임워크가 PyTorch GRU/LSTM 모델을 HLS C++로 자동 변환하므로, 작은 모델(은닉 8–16 노드)은 Basys3 Artix-7 대상 HLS로 시도해볼 수 있다. GRU가 LSTM보다 명확히 자원이 적으므로, 자원이 빡빡한 Basys3에서 RNN 가속기를 첫 구현할 때 GRU 선택이 합리적.

개조: (내 판단)
① hls4ml을 Artix-7 대상 HLS 프로젝트로 돌려 소형 GRU(H=8~16) 가속기 생성 가능. 단, Vivado HLS 라이선스와 Artix-7 지원 여부 확인 필요.
② 순수 Verilog-2001 구현 시: hls4ml 생성 HLS 코드를 구조 참고만 하고, GRU 셀(2게이트 + 고정소수점 tanh/σ LUT + MAC)을 자체 작성
③ AXI4-Lite 슬레이브로 MicroBlaze V가 입력·가중치 적재, 타임스텝 완료 인터럽트 반환 구조 → free_slots 1슬롯
④ 옮길 수 없는 것: hls4ml Python 환경, UltraScale 전용 DSP/BRAM 배열, 고성능 클럭 경로
