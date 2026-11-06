---
name: arxiv-2607-01798-approx-attention-fpga
url: https://arxiv.org/abs/2607.01798
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(accelerator)
language: Verilog
tools: []
bus: AXI4-Lite
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-07}
doc_language: en
verification: L2
checked_at: 2026-11-07
source_rev: 
sources: [https://arxiv.org/abs/2607.01798, https://arxiv.org/pdf/2607.01798]
---

## 요약

"Approximate Attention Weighting for Sustainable FPGA-Based Vision Transformer Inference" (arXiv 2607.01798). FPGA 비전 트랜스포머 추론에서 Softmax를 선형 근사(max-shift 방식)로 대체해 하드웨어 복잡도를 줄이는 연구.

unverified: 본문 미열람(WebFetch PROVENANCE_REQUIRED 차단). 검색 결과 제목·초록 요약 기준 L2.

## 구조

- Softmax 근사: max를 뺀 뒤 1차 선형 근사(max-shift approximation) 사용
- 고정소수점 어텐션 가중치 계산 엔진
- Vision Transformer 타깃
- 대상 보드: 일반 FPGA(구체 모델 미확인)

## 검증·재현성

- unverified: LUT/DSP 사용량, 정확도 손실, 코드 공개 여부 미확인

## 한계·위험

- 선형 Softmax 근사가 얼마나 정확도를 떨어뜨리는지 본문 없이 판단 불가
- 내 판단: Softmax 근사 아이디어는 Basys3 소형 어텐션에 가장 적합한 접근 중 하나

## 재사용 메모

- 내 판단: Basys3의 소형 어텐션 헤드 구현 시 Softmax 근사 방법으로 max-shift 방식을 채택할 수 있음.
- 개조: QK^T 행렬곱 → max-shift Softmax → AV 가중 합산 순서는 Basys3에서도 그대로 적용 가능. 비트폭은 Q1.15 또는 Q8.8 고정소수점. 단일 헤드, 시퀀스 길이 ≤ 8이면 LUT 위주 구현 가능.
