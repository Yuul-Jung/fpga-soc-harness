---
name: ftrans-2020-transformer-fpga-piecewise-softmax
url: https://arxiv.org/abs/2007.08563
source_type: paper
vendor: amd
board: [VCU118]
fit_basys3: no
cpu: none(가속기 전용)
language: HLS(C++)
tools: [Xilinx SDx 2017.1]
bus: 내부 스트림
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2020-07-16}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://arxiv.org/abs/2007.08563]
---

## 요약

Li et al. (ISLPED '20) "FTRANS: Energy-Efficient Acceleration of Transformers using FPGA."
Xilinx VCU118 (UltraScale+)에서 블록-순환 행렬(BCM) 압축 + 16비트 고정소수점 양자화로 Transformer 추론 가속.
소프트맥스에 구간 선형(piecewise-linear) exp 근사 사용. 소스 코드 미공개.

## 구조

- FPGA: Xilinx Virtex UltraScale+ VCU118 (BRAM 345.9 Mb, DSP 6,840, 로직 2,586 K 셀)
- 양자화: 16비트 고정소수점 (fp32 → 16비트 정확도 무손실 보고)
- 압축: BCM(Enhanced Block-Circulant Matrix), 블록 크기 4 또는 8; 선형층 가중치 적용
- 소프트맥스 구현: 구간 선형 exp 근사 → 버퍼에 저장 → 누산기로 합산 → 나눗셈기 출력
- 스케일: QK 곱을 √d_k로 나눔 (파이프라인 내 Norm 모듈)
- 마스킹: 헤드별 로컬 컨트롤러 → 미래 토큰 멀티플렉서로 0 마스킹
- 자원 사용 (Shallow Transformer): DSP 5,647 / FF 304,012 / LUT 268,933
- 자원 사용 (RoBERTa-base): DSP 6,531 / FF 506,612 / LUT 451,073
- 클럭: 미보고

## 검증·재현성

- 논문 내 에너지 효율 및 처리량 비교 (CPU·GPU 대비)
- 소스 코드 미공개; ACM DOI만 제공
- unverified: 테스트벤치, CI 흐름, 보드 동작 확인 세부사항

## 한계·위험

- XC7A35T 기준: LUT 20,800, DSP 90, FF 41,600 — Shallow Transformer 조차 LUT 13×, DSP 63×, FF 7× 초과
- Basys3에서는 모델 크기를 극단적으로 축소해도 직접 실행 불가 (fit_basys3: no)
- 소프트맥스 파이프라인 세부 데이터플로 기술이 논문 내에서 일부 불일치 (열람 기준)
- HLS 흐름(SDx 2017.1)이므로 최신 Vivado HLS/Vitis 환경으로 재현 시 호환성 확인 필요

## 재사용 메모

- 구간 선형 exp 근사 아이디어(작은 LUT + 가산기)는 Basys3 소형 소프트맥스 설계의 참고 패턴으로 사용 가능:
  입력 범위를 제한(-8 ~ 0 편이 후)하면 32~64 항목 LUT로 piecewise-linear 구현 가능 (내 판단)
- BCM 압축 접근법은 선형층 가중치를 BRAM에 올릴 때 용량 절약에 적용 가능
- 개조: MicroBlaze V SoC에 연결 가능한 부분은 소프트맥스 근사 FSM 로직(CPU 비종속).
  BCM 압축 행렬 곱은 d_k=16 단일 헤드 크기에서 BRAM 절약 경로로 검토 가능. CPU 코어 의존 없음.
