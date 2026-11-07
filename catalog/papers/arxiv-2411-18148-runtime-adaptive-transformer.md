---
name: arxiv-2411-18148-runtime-adaptive-transformer
url: https://arxiv.org/abs/2411.18148
source_type: paper
vendor: amd
board: [Alveo U55C, VC707 (Virtex-7 xc7vx485t), ZCU102 (Zynq UltraScale+)]
fit_basys3: no
cpu: none(HLS-accelerator)
language: HLS (C/C++)
tools: [Vivado HLS, Vitis HLS]
bus: AXI4
peripherals: [QKV-attention-modules, multi-head-attention, BERT-variant]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: 2024-11}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://arxiv.org/html/2411.18148v4]
---

## 요약

Kabir et al. (2024) 발표 논문. 런타임에 헤드 수·레이어 깊이·FFN 폭을 동적으로 조정할 수 있는 트랜스포머 하드웨어 가속기를 Alveo U55C에 HLS로 구현한다. QKV_PM, QK_PM, SV_PM 세 모듈로 Multi-Head Attention 연산을 분리하고, 런타임 파라미터로 헤드 수를 1~12 사이에서 전환한다.

## 구조

- **대상 보드**: Alveo U55C (기본 타깃), VC707·ZCU102도 평가에 등장
- **처리 모듈 (HLS):**
  - `QKV_PM`: Query/Key/Value 행렬 곱 계산
  - `QK_PM`: Q·Kᵀ 스코어 계산 (스케일된 닷-프로덕트)
  - `SV_PM`: 소프트맥스 스코어 × V 집계
- **버스**: AXI4 (Vitis HLS 인터페이스)
- **런타임 파라미터**: 헤드 수(h), 레이어 깊이(L), FFN 폭(d_ff)를 AXI 레지스터로 프로그래밍
- **정밀도**: INT8·FP16 혼합; 소프트맥스 근사 미명시(논문 본문에서 확인)
- **모델**: BERT-base 변형 기준 (12헤드, d_model=768)

## 검증·재현성

- Alveo U55C에서 BERT-base 추론 실험 수치 제시 (레이턴시·처리량, 논문 HTML 본문 열람)
- VC707·ZCU102 보조 평가 포함
- 소스 코드 저장소 URL 미기재(논문 HTML에 없음); GitHub 검색에서도 미발견
- unverified: 정확한 LUT/BRAM/DSP 수치 (논문 HTML에 하드웨어 자원 표 없음)

## 한계·위험

- **Basys3 불가**: BERT-base 기준 d_model=768, 12헤드 → XC7A35T BRAM·LUT 대비 최소 10× 초과
- Alveo U55C (HBM 탑재 데이터센터 카드) 전용 설계; Pmod·UART 인터페이스 없음
- HLS 소스 미공개; 소프트맥스 근사·정밀도 처리 세부는 본문에서 추정만 가능
- 논문 내 지시문 없음(§7 준수)

## 재사용 메모

Basys3에서 직접 사용 불가. 그러나 세 처리 모듈(QKV_PM, QK_PM, SV_PM)로 어텐션을 분리하는 아키텍처 패턴은 소형화 설계 참고로 유용하다.

**개조 (d_model 축소 버전):** d_model=16, h=1, 시퀀스 길이=16으로 축소하면 QKV 행렬 크기가 16×16 × 3 = 768 INT8값 → 약 768 B = Basys3 BRAM 1블록 미만. SV_PM 소프트맥스 근사는 piecewise-linear exp(기존 `cardarilli-2021-pseudo-softmax` 패턴)로 대체 가능.

**NPU T3 감성 분류 맥락:** QKV_PM→QK_PM→SV_PM 세 단계 직렬 FSM으로 구성하면 약 400줄 Verilog-2001 범위 내. 호스트 UART 토큰 직렬 입력 후 세 FSM이 순차 계산하고 아르그맥스로 긍정/부정 출력.
