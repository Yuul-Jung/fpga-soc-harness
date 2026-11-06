---
name: arxiv-2409-14023-famous-attention-fpga
url: https://arxiv.org/abs/2409.14023
source_type: paper
vendor: neutral
board: []
fit_basys3: no
cpu: none(accelerator)
language: Verilog
tools: []
bus: AXI4-Lite
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-09}
doc_language: en
verification: L2
checked_at: 2026-11-07
source_rev: 
sources: [https://arxiv.org/abs/2409.14023, https://ar5iv.labs.arxiv.org/html/2409.14023]
---

## 요약

"FAMOUS: Flexible Accelerator for the Attention Mechanism of Transformer on UltraScale+ FPGAs" (arXiv 2409.14023). Xilinx UltraScale+ FPGA에서 트랜스포머의 어텐션 메커니즘(QKV 행렬곱, Softmax, 가중 합산)을 가속하는 유연한 가속기. Kabir et al. (Univ. South Carolina).

unverified: 본문 미열람(WebFetch PROVENANCE_REQUIRED 차단). 검색 결과 제목·초록 요약 기준 L2.

## 구조

- 대상 보드: Alveo U280 / UltraScale+ (Basys3와 무관)
- Scaled Dot-Product Attention의 세 단계(QK^T, Softmax, AV)를 파이프라인으로 처리
- 고정소수점 행렬곱 엔진 추정(unverified)
- 헤드 수, 비트폭, 처리량 미확인(unverified)

## 검증·재현성

- unverified: 코드 공개 여부, 자원 사용 미확인

## 한계·위험

- UltraScale+용으로 Basys3 이식 불가(HBM2, 대용량 DSP 의존 추정)
- 내 판단: 아키텍처 패턴 참고용으로만 적합

## 재사용 메모

- 내 판단: Basys3에서 소형 어텐션을 구현할 때 QK^T→Softmax→AV 3단계 파이프라인 패턴을 참고 가능.
- 개조: UltraScale+ DSP 블록 대신 Artix-7 DSP48E1로 대체, 행렬 크기를 4×4 또는 8×8 이하로 축소 필요. BRAM 제약 때문에 가중치 on-chip 저장 한계 존재.
