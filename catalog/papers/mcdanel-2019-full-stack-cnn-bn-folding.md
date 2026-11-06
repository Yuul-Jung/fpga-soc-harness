---
name: mcdanel-2019-full-stack-cnn-bn-folding
url: https://arxiv.org/abs/1905.00462
source_type: paper
vendor: neutral
board: [VC707]
fit_basys3: needs-port
cpu: none(가속기)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2019-05-01}
doc_language: en
verification: L2
checked_at: 2026-11-06
source_rev:
sources: [https://arxiv.org/abs/1905.00462, https://arxiv.org/pdf/1905.00462]
---

## 요약

배치 정규화(BN)를 log 양자화 가중치에 "흡수(folding)"하여 추론 시 BN 연산을 완전히 제거하는 방법을 제안한다. VC707 Virtex-7 FPGA에서 CNN 추론을 검증하며, BN 파라미터를 앞 층의 가중치로 사전 병합함으로써 추론 단계에서 나눗셈과 sqrt 연산 없이 각 채널당 1회 곱셈·덧셈만 남는다.

## 구조

- **BN 흡수 방법**: γ, β, μ, σ를 이용해 `scale = γ/√(σ²+ε)`, `shift = β − γμ/√(σ²+ε)`를 훈련 후 오프라인으로 계산. 추론 시 BN 블록이 없어지고 선행 합성곱/FC 층의 가중치에 흡수된 scale·shift만 남음
- **Log 양자화**: 가중치를 2의 거듭제곱으로 양자화하면 곱셈이 비트 시프트로 대체 가능. BN 흡수와 조합하면 BN이 추가 하드웨어 없이 사라짐
- **대상 보드**: Xilinx Virtex-7 VC707 (XC7VX485T)
- **검증 형태**: 논문 내 FPGA 추론 실험으로 정확도와 처리량 확인 (검색 요약 기준)

## 검증·재현성

- 오픈소스 코드 링크 없음 (GitHub 미확인, 검색 요약 기준)
- 정확도: log 양자화 + BN 흡수 조합 시 floating-point 대비 허용 오차 범위 내 (구체적 수치는 논문 본문 미열람)
- unverified: 자원 사용(LUT/FF/BRAM/DSP) 수치 — 논문 본문 직접 미열람

## 한계·위험

- VC707은 Basys3보다 훨씬 큰 FPGA(485K LUT). 소규모 Artix-7로 이식 시 자원 재검증 필요
- Log 양자화 조건 하에서만 BN 흡수 시 비트 시프트 단순화 가능. 일반 INT8 환경에서는 여전히 1 MAC 필요
- 코드 미공개 가능성 있음(논문 기반 연구, 검색 결과 L2 수준)

## 재사용 메모

- BN 흡수의 핵심 공식(`scale`, `shift` 사전 계산)은 Basys3 NPU에 직접 적용 가능. Python으로 훈련 후 `scale/shift` 배열을 BRAM에 적재하면 추론 단계에서 BN 블록 불필요
- 개조: MicroBlaze V SoC에서 AXI-Lite 슬레이브로 `scale_bram`과 `shift_bram`을 각각 별도 슬롯에 맵핑, 가중치 적재 단계에서 CPU가 사전 계산 값을 써주는 구조. `free_slots`에서 64 KB 슬롯 1개로 충분. log 양자화는 아두이노·MCU 환경에서도 비트 시프트만으로 BN 처리 가능해 임베디드 추론 범위를 아우름
