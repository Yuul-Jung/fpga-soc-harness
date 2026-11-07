---
name: arxiv-2505-17662-tinyformer4ts
url: https://arxiv.org/abs/2505.17662
source_type: paper
vendor: neutral
board: [Spartan-7 XC7S15 (ElasticNode V5)]
fit_basys3: needs-port
cpu: none(전용 추론 가속기)
language: Verilog
tools: [Vivado, GHDL]
bus: none
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2025-05}
doc_language: en
verification: L3
checked_at: 2026-11-07
source_rev: 
sources: [https://arxiv.org/abs/2505.17662]
---

## 요약

Spartan-7 XC7S15(8K LUT)에 단일 인코더 블록(어텐션 1헤드, FFN 1층)을 얹어 시계열 분류를 수행하는 초소형 트랜스포머 가속기. d_model=8~40, 4~8비트 고정소수점, LUT 사용률 35~96%. Basys3(XC7A35T, 33K LUT)에서는 같은 구성이 약 8~24% 사용률로 여유 충분.

## 구조

- 단일 인코더 레이어: 1헤드 멀티헤드 어텐션 + FFN(4×d_model)
- d_model: 8, 16, 24, 32, 40 (파라미터로 선택)
- 양자화: 4~8비트 고정소수점, 성분별 비트폭 조정 가능
- 대상 플랫폼: Xilinx Spartan-7 XC7S15 (ElasticNode V5 하드웨어, BRAM 한정)
- 검증: GHDL 시뮬레이션 + Vivado 구현 (LUT/BRAM 보고)
- LUT 사용률: d_model=8/4bit → ~35%, d_model=40/8bit → ~96% (XC7S15 기준)
- 코드: github.com/tianheng-ling/TinyTransformer4TS (논문 제출 시 pending release)

## 검증·재현성

- Vivado 구현 성공. LUT/BRAM 수치 보고 (원문 §IV)
- GHDL 기능 시뮬레이션 통과
- 타이밍(WNS) 미기재
- 코드 저장소는 pending release 상태이므로 현재 직접 재현 불가

## 한계·위험

- XC7S15 전용 XDC. Basys3 이식 시 클럭·핀 수정 필요
- 코드 라이선스 미기재 — 공개 후 확인 필요
- 타이밍 마진(WNS) 미보고
- 시계열 분류 태스크 전용; 범용 NLP 추론과 구조 다름

## 재사용 메모

XC7S15 대비 Basys3(XC7A35T)가 약 4배 큰 LUT 풀을 가지므로, 같은 d_model=40, 8비트 구성도 LUT ~24% 사용에 그쳐 여유 큼. 단일 인코더 블록(1헤드, 1층 FFN) 구조가 §13.7 자동 과제화 아이디어(NPU 캡스톤 T4 어텐션 블록)의 직접 근거가 됨.

개조: 단일 인코더 FSM·데이터패스를 AXI4-Lite 슬레이브 IP로 감싸면 MicroBlaze V AXI4-Lite NPU IP로 전환 가능. 가중치를 BRAM에 저장, AXI 레지스터로 추론 트리거·결과 읽기를 구현하는 구조는 동결 맵 `free_slots` 한 칸 배정으로 수용 가능. 옮길 수 없는 부분: ElasticNode V5 전용 XDC 및 주변 하드웨어.
