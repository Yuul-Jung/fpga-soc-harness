---
name: wang-2020-mha-fpga-accelerator
url: https://arxiv.org/abs/2009.08605
source_type: paper
vendor: amd
board: [xcvu13p-fhga2104-3-e]
fit_basys3: needs-port
cpu: none(가속기 전용)
language: Verilog
tools: [Vivado]
bus: 내부 스트림
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2020-09-17}
doc_language: en
verification: L3
checked_at: 2026-11-06
rechecked_at: 2026-11-07
sources: [https://arxiv.org/abs/2009.08605, https://arxiv.org/pdf/2009.08605]
---

## 요약

Wang et al. (2020) "Hardware Accelerator for Multi-Head Attention and Position-Wise Feed-Forward in the Transformer."
Xilinx xcvu13p (UltraScale+) 대상, INT8 양자화, 64×64 시스톨릭 어레이 기반 MHA·FFN 가속기.
소프트맥스를 로그-합-지수(log-sum-exp) 근사와 선형 exp/ln 근사로 하드웨어 구현.
소스 코드 미공개.

## 구조

- FPGA: Xilinx xcvu13p-fhga2104-3-e (UltraScale+)
- 양자화: INT8 (가중치·활성화 모두). 스케일 팩터는 d_k=64 기준으로 √64 = 8로 나눔
- 행렬 곱(QK^T, Softmax×V, FFN 선형층): 64×64 또는 s×64 시스톨릭 어레이 PE 뱅크
- 소프트맥스 파이프라인 (4단계):
  1. 행 최댓값 추출 (온라인, 스트리밍)
  2. x - max 편이 후 선형 exp 근사 (LUT 불필요, 가산기·비교기만 사용)
  3. 편이된 지수값 누적 합산
  4. 선형 ln 근사로 나눗셈 대체 (로그 뺄셈)
- 소프트맥스 단독 자원: LUT 21,190 / FF 32,623 (xcvu13p 기준, 전체 중 약 4.5%)
- 전체 MHA+FFN 자원: LUT 471,563 / CLB Reg 217,859 / BRAM 498 / DSP 129
- 클럭: 200 MHz
- 성능: MHA 14.6× 가속(GPU V100 대비), FFN 3.4× 가속

## 검증·재현성

- 논문 내 하드웨어 시뮬레이션 및 FPGA 합성 결과 보고 (xcvu13p)
- 소스 코드 미공개; 재현은 논문 기술 사양에서 독자 구현 필요
- unverified: 테스트벤치 존재 여부, CI 흐름 미확인

## 한계·위험

- xcvu13p는 Basys3(XC7A35T)에 비해 LUT 약 23×, BRAM 약 10×, DSP 약 15× 큰 디바이스
- 소프트맥스 단독(LUT 21,190 / FF 32,623)도 XC7A35T(LUT 20,800)를 초과
- 소스 미공개이므로 직접 재현 불가; 논문 기술 사양 기반 자체 구현 필요
- 선형 exp/ln 근사의 오차 범위가 정확히 명시되지 않음

## 재사용 메모

- Softmax 로그-합-지수 4단계 파이프라인은 하드웨어 구현의 핵심 아이디어로, Basys3에서도 작은 행 길이(d_k ≤ 32~64) 기준으로 이식 가능
- 시스톨릭 어레이 크기를 4×4 또는 8×8로 축소하면 XC7A35T의 BRAM·DSP 자원 한도 내에서 단일 헤드 어텐션 구현 검토 가능
- INT8 고정소수점 MAC은 Artix-7의 DSP48E1(18×25 곱셈)에 2개 INT8 쌍으로 묶어 사용 가능
- 개조: MicroBlaze V AXI4-Lite 슬레이브 래퍼로 묶으면 소프트맥스 연산 오프로드 IP 형태로 사용 가능. CPU 코어 의존 없음; 가속기 IP만 추출. free_slots에서 64KB 할당 제안.
