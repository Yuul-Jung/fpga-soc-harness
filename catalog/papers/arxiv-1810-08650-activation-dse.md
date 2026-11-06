---
name: arxiv-1810-08650-activation-dse
url: https://arxiv.org/abs/1810.08650
source_type: paper
vendor: neutral
board: [Xilinx VC7V2000T]
fit_basys3: needs-port
cpu: none(DSP)
language: VHDL
tools: [Vivado, Cadence]
bus: none
peripherals: [activation-function]
stage: T4
license: unknown
stats: {stars: 해당없음, commits: 해당없음, last_update: 2018}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://arxiv.org/abs/1810.08650]
---

## 요약

arXiv 2018 프리프린트. FPGA/ASIC에서 활성화 함수를 구현하는 5가지 방식(ROM_y, ROM_k_b, CORDIC, Taylor, 조합 sum-of-products)을 tanh_7_4·SELU_8_5 기준으로 면적·지연·정확도를 비교한다. 조합(Karnaugh map) 방식이 가장 작은 면적이나 오차가 가장 크다. (arXiv 초록 페이지 기준 L2 — 전문 PDF 미열람)

## 구조

비교 대상 5가지 구현 방식:
1. **ROM_y**: 출력값 직접 저장 — 가장 단순, BRAM 소비 큼
2. **ROM_k_b**: 선형 보간을 위한 기울기+절편 저장 — 오차 가장 작음(0.52% avg), BRAM 소비 큼
3. **CORDIC**: 쉬프트-덧셈 반복 — DSP 불필요, 긴 지연
4. **Taylor**: 다항식 전개 — 중간 복잡도
5. **조합(제안)**: Karnaugh map sum-of-products — 최소 면적, 오차 가장 큼(4.19% avg)

대상 함수 · 비트폭:
- tanh_7_4: 4비트 입력 → 7비트 출력
- SELU_8_5: 5비트 입력 → 8비트 출력

면적 (28nm CMOS ASIC):
- 조합 tanh: 97.65 µm²
- ROM_y: 306.12 µm²
- ROM_k_b: 751.44 µm²

## 검증·재현성

- 오차(tanh 기준): 조합 4.19% avg, ROM_k_b 0.52%
- 정확도 영향(조합 방식, 논문 보고):
  - MNIST: −0.05%
  - CIFAR-10: −1.96%
  - ImageNet: −7.83%
- 목표 보드: Xilinx VC7V2000T (Virtex-7, 대형 FPGA — Basys3와 다름)
- 오픈소스 구현: 미확인 (논문 GitHub 링크 없음)

## 한계·위험

- arXiv 초록 페이지만 열람 (전문 PDF 미열람) — 세부 회로도·타이밍·FPGA LUT 수 등 미확인
- 대상 보드가 Virtex-7 대형 FPGA; Basys3(Artix-7 소형)로 직접 이식 불가
- 면적 수치는 28nm ASIC 기준 — Artix-7 LUT 등가치는 별도 추정 필요
- SELU_8_5 정확도 영향: unverified (전문 미열람)

## 재사용 메모

- Basys3 포팅 가능성(needs-port): 조합(SOP) 방식은 순수 LUT 로직으로 Artix-7에 직접 구현 가능 (내 판단)
- 내 판단: tanh_7_4(4비트 입력) 조합 SOP 로직은 LUT 수십 개 이내 — Basys3 20800 LUT 중 소수 소비 추정. BRAM·DSP 불필요
- S4 제약 역전: BRAM 없이 순수 LUT 조합으로 활성화 함수 구현 → Basys3 BRAM-bound 한계를 역이용
- 5가지 방식 비교 체계(ROM_y/ROM_k_b/CORDIC/Taylor/조합)는 우리 MLP 추론 가속기 활성화 함수 슬롯 선택 가이드로 활용
- 개조: MicroBlaze V 파이프라인 활성화 함수 모듈로 조합 tanh_7_4 사용 가능. 비트폭(4비트 입력→7비트 출력)을 우리 Q포맷(Q4.4 등)에 맞게 조정 필요. ROM_k_b 방식은 보간 연산에 DSP48 1개 사용 → 동결 맵 미영향(계산기 로직만). 옮길 수 없는 것: Virtex-7 전용 타이밍 보고서, ASIC 28nm 면적 수치.
