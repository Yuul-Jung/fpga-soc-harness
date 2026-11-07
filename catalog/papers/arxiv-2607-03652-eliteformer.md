---
name: arxiv-2607-03652-eliteformer
url: https://arxiv.org/abs/2607.03652
source_type: paper
vendor: amd
board: [Versal VCK5000]
fit_basys3: no
cpu: none(LLM 추론 가속기)
language: HLS(C++)
tools: [Vitis HLS]
bus: none
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-07}
doc_language: en
verification: L2
checked_at: 2026-11-07
source_rev: 
sources: [https://arxiv.org/abs/2607.03652]
---

## 요약

Versal VCK5000를 대상으로 삼진 가중치(ternary)와 하이브리드 선형 어텐션을 결합한 LLM 추론 가속기. DSP 없이 비트마스크 연산으로 선형 투영을 처리해 LLaMA 3 대비 가중치 10×, KV 캐시 12.8× 압축. MMLU 31.9% 정확도. Basys3 이식은 불가 — 대형 AI엔진 플랫폼 전용.

## 구조

- 하이브리드 선형 어텐션 + 삼진 가중치(−1, 0, +1)
- 삼진 선형 투영을 비트마스크 연산으로 대체 → DSP 미사용
- FFN 9.6× 가속, 어텐션 4.4× 가속 (블록 레벨 시뮬레이션)
- 대상: Versal VCK5000 (AI엔진 포함 대형 가속기 카드)
- 구체적 LUT/FF/BRAM 수치: 미공개 (arXiv 초록 기준)

## 검증·재현성

- 블록 레벨 시뮬레이션 완료
- LLaMA 3 대비 장문 컨텍스트에서 3.9× 저지연, 3.2× 에너지 효율 (NVIDIA A100 비교, 검색 요약 기준)
- 보드 동작 확인 여부 미기재
- 코드 저장소·라이선스 미공개

## 한계·위험

- Versal VCK5000(AI엔진 집적형 대형 플랫폼) 전용 — Basys3 Artix-7에 직접 이식 불가
- LUT/FF/BRAM/DSP 구체적 수치 미공개
- LLM(대형 언어 모델) 추론 태스크로 Basys3 소형 추론에 비해 과도하게 큰 모델 가정
- MMLU 31.9%는 LLM 기준으로도 낮은 편
- unverified: 초록과 검색 요약만 열람, 전문 미공개

## 재사용 메모

삼진 가중치를 비트마스크로 처리해 DSP 소모를 없애는 아이디어는 Basys3의 90 DSP 제약 완화에 참고 가능. 가중치를 2비트 인코딩(00=0, 01=+1, 10=−1)으로 BRAM에 압축 저장하는 방식은 소형 Basys3 NPU에서도 적용 가능. S4 제약 역전: DSP 의존도를 낮춰 LUT 위주 설계로 전환.

개조: 삼진 가중치 비트마스크 연산 개념만 차용. MicroBlaze V AXI4-Lite NPU IP에서 가중치 메모리를 삼진값으로 압축해 BRAM 절약 가능 (2비트 인코딩, BRAM 1/4 압축 효과). 옮길 수 없는 부분: Versal AI엔진 HLS 전용 코드, VCK5000 보드 인터페이스 전체. LLM 규모(10억+ 파라미터)를 소형 어텐션 블록에 그대로 적용 불가.
