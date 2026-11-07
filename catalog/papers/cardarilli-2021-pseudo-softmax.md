---
name: cardarilli-2021-pseudo-softmax
url: https://www.nature.com/articles/s41598-021-94691-7
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(가속기 전용)
language: Verilog
tools: [Synopsys Design Compiler, 90nm CMOS]
bus: none
peripherals: []
stage: T4
license: CC-BY 4.0
stats: {stars: 0, commits: 0, last_update: 2021-07-01}
doc_language: en
verification: L3
checked_at: 2026-11-07
sources: [https://www.nature.com/articles/s41598-021-94691-7.pdf]
---

## 요약

Scientific Reports 2021 오픈액세스 논문. 지수 밑을 e에서 2로 바꾼 "의사-소프트맥스(pseudo-softmax)"를 제안한다. `p_i = 2^(x_i) / Σ_k 2^(x_k)` 형태로 정수 입력에서 지수 계산이 단순한 비트 시프트·조회로 환원된다. CMOS 90nm ASIC 대상이지만 FPGA에도 적용 가능한 원리다.

## 구조

- **핵심 아이디어**: 밑을 2로 바꾸면 `2^(x_i)` = 정수 부분이 비트 위치, 소수 부분이 가수(mantissa)로 분리됨 → 1회 역수 계산으로 나눗셈 대체
- **출력 형식**: 부호 없는 부동소수점, 9비트 비편향 지수 + 8비트 소수 가수(1은 암묵적)
- **입력 형식**: 부호 있는 정수 (INT8 기준, 범위 -128~127). 3비트·10비트 케이스도 평가
- **역수 블록**: 가수 1.5 경계로 2구간 PWL(계수를 2의 거듭제곱으로 선택 → 곱셈 없이 시프트만). 최대 절대오차 2^-5 = 0.03125
- **합산 트리**: 이진 트리 구조, 파이프라인 가능
- **10클래스 INT8 지연**: 비파이프라인 3.22 ns (Synopsys 90nm)

## 검증·재현성

- 30개 입력(≈5) 테스트: MSE 2.7082×10⁻⁴ (기존 비교 대상 0.8502보다 약 3000배 낮음)
- ImageNet 5개 CNN(10비트 양자화): MSE 범위 0~10×10⁻⁴
- 비교 대상(설계 [23])보다 오차 약 1 OOM 낮음
- RTL 소스 미공개(논문 수식·ASIC 플로우만 기술)

## 한계·위험

- RTL/IP 코드 미공개: 논문 원리를 이해하고 직접 구현해야 함
- ASIC 플로우(Synopsys 90nm) 전용, Vivado/iverilog 검증 없음
- N < 128로 입력 수 제한 (9비트 지수 오버플로 방지)
- argmax 미언급: 출력 확률 중 최댓값 선택은 별도 구현 필요
- 직렬·혼합 병렬-직렬 버전은 미래 과제로만 언급

## 재사용 메모

Basys3 Softmax IP 직접 설계 시 이 논문의 base-2 근사가 출발점이 된다. 나눗셈을 비트 시프트로 대체하고 역수를 2구간 선형 근사하는 구조는 LUT 없이 Artix-7에서 구현 가능하다.

개조: MicroBlaze V INT8 추론 파이프라인 말단에 삽입. ① 연산 단위(가수 연산)는 DSP48 없이 LUT-only로 가능. ② 출력 정규화 불필요 → argmax만 필요한 경우 `2^(x_i)` 비교로 최댓값 클래스 직접 선택 가능(softmax skip). ③ AXI4-Lite 래퍼로 N 로짓 버스, 트리거, 결과 레지스터 추가. 옮길 수 없는 부분: Synopsys DC 타이밍 수치는 FPGA에 직접 적용 불가, Vivado 합성으로 재측정 필요.
