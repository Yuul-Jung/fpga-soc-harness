---
name: arxiv-2401-02721-tiny-transformer-fpga
url: https://arxiv.org/abs/2401.02721
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
stats: {stars: 0, commits: 0, last_update: 2024-01}
doc_language: en
verification: L2
checked_at: 2026-11-07
source_rev: 
sources: [https://arxiv.org/abs/2401.02721, https://arxiv.org/html/2401.02721]
---

## 요약

"A Cost-Efficient FPGA Implementation of Tiny Transformer Model using Neural ODE" (arXiv 2401.02721). Neural ODE 근사를 써서 어텐션 블록과 FFN 계층을 Artix-7 계열 FPGA에서 비용 효율적으로 구현한 연구. T4 가속기 단계.

unverified: 본문 미열람(WebFetch PROVENANCE_REQUIRED 차단). 검색 결과 제목·초록 요약 기준 L2.

## 구조

- Tiny Transformer 모델을 Neural ODE로 근사해 계산량을 줄임
- 어텐션 헤드 수·시퀀스 길이 미확인(unverified)
- 고정소수점 연산 사용으로 추정(unverified)
- 대상 보드: 논문 텍스트에서 Artix-7 계열로 추정(검색 요약 기준)

## 검증·재현성

- unverified: 코드 저장소 존재 여부, 빌드 방법, 자원 사용(LUT/DSP) 미확인

## 한계·위험

- Neural ODE 근사 접근이라 일반 Softmax+MatMul 어텐션과 구현 방식이 다를 수 있음
- Basys3 타깃 여부 불명

## 재사용 메모

- 내 판단: Basys3의 소규모 어텐션 아이디어(1헤드, 짧은 시퀀스)에 참고할 근거로 사용 가능. 본문 열람 시 L3 승격 필요.
- 개조: Neural ODE 근사보다 직접 QKV MatMul + 선형 Softmax 근사를 Basys3에 맞게 구현하는 방향이 현실적. BRAM 제약(no-dram)으로 시퀀스 길이 ≤ 8이 타당.
