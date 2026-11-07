---
name: arxiv-2410-03294-mixprecq-ts-fpga
url: https://arxiv.org/abs/2410.03294
source_type: paper
vendor: neutral
board: [Spartan-7 XC7S15 (ElasticNode V5)]
fit_basys3: needs-port
cpu: none(전용 추론 가속기)
language: Verilog
tools: [Vivado]
bus: none
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-10}
doc_language: en
verification: L3
checked_at: 2026-11-07
source_rev: 
sources: [https://arxiv.org/abs/2410.03294]
---

## 요약

XC7S15에서 단일 인코더 트랜스포머(1헤드, d_model=64, FFN 1층)의 성분별 혼합 정밀도(4/6/8비트) 최적화 연구. 균일 양자화로 배포 불가했던 구성을 혼합 정밀도로 배포 가능하게 만들었으나, BRAM 사용률 100%가 Basys3 이식의 주요 위험 요소.

## 구조

- 단일 인코더 레이어: 1헤드 MHA + FFN(4×64=256), LayerNorm ×2
- d_model: 64, 입력 시퀀스 n: 12 / 18 / 24
- 10개 성분(L_input, AddPE, MHA, AddMHA, BN_MHA, FFN, AddFFN, BN_FFN, GAP, L_output) 각각 4/6/8비트 독립 할당
- 편향(bias) 비트폭: 선행 레이어에 따라 14~18비트
- 대상: AirU 대기질 단일 스텝 예측

## 검증·재현성

- Vivado 구현 성공, 자원 사용률 보고 (Table 7)

| n | LUT% | DRAM% | BRAM% | DSP% |
|---|---|---|---|---|
| 12 | 85.7 | 79.3 | 100 | 100 |
| 18 | 76.3 | 56.5 | 100 | 80 |
| 24 | 80.7 | 67.8 | 100 | 80 |

- n=12 추론: 5.78ms, 70mW, 0.405mJ/추론 (100MHz)
- 코드 저장소 없음, 라이선스 미기재

## 한계·위험

- BRAM 100% 포화: XC7S15(5개 BRAM36)가 한계. Basys3도 50 BRAM36으로 d_model=64 1층은 위험 수준
- DSP 100% 포화(n=12): XC7S15는 20 DSP, Basys3는 90 DSP이므로 DSP는 여유 있음
- 코드·라이선스 미공개, 재현 불가
- XC7S15 전용 지식 데이터베이스 기반 추정 — 다른 디바이스로 이전 필요

## 재사용 메모

혼합 정밀도 성분 배분 전략이 핵심 이식 대상. MicroBlaze V AXI4-Lite NPU IP 설계에서 각 성분의 비트폭을 AXI 레지스터로 프로그래밍 가능하게 하면 소프트웨어 제어 혼합 정밀도 추론 구현 가능. BRAM 포화는 d_model을 32 이하로 줄이거나 DRAM 비율 증가로 대응 필요.

개조: 성분별 혼합 정밀도 FSM은 AXI4-Lite 레지스터 맵에서 비트폭 설정값을 읽어 동작하도록 설계하면 MicroBlaze V에서 소프트웨어로 정밀도를 조정 가능. BRAM 포화 회피를 위해 d_model≤32 설계를 권장. 옮길 수 없는 부분: ElasticNode V5 주변장치 접속, XC7S15 XDC, 지식 데이터베이스 모델.
