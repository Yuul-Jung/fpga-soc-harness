---
name: lay007-zynq-sdr-course-block04
url: https://lay007.github.io/zynq-sdr-course/en/blocks/04-fixed-point-workflow/
source_type: course
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(방법론)
language: []
tools: [MATLAB, Python]
bus: none
peripherals: []
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://lay007.github.io/zynq-sdr-course/en/blocks/04-fixed-point-workflow/]
---

## 요약

SDR(소프트웨어 정의 무선) 과정의 Block 4 — 고정소수점 워크플로. Q<I>.<F> 포맷 표기법, 비트 성장 규칙(덧셈 +1, 곱셈 합산, FIR 가드 비트), 포화·반올림 정책, 오차 분석 지표(RMS, SQNR, EVM)와 "HDL 준비 체크리스트" 8항목을 체계적으로 정리한다. 코드 예제는 없으나 방법론 기준으로 쓸 수 있다.

## 구조

**Q포맷 표기**
- `Q<I>.<F>`: I = 부호 포함 정수 비트 수, F = 소수 비트 수, 전체 비트 W = I + F.
- 예: Q1.15 (16비트, 범위 ≈ [-1, 1)), Q2.14 (16비트, 범위 ≈ [-2, 2)), Q4.20 (24비트).

**권장 초기 포맷 표 (열람 기준)**:

| 노드 | 초기 포맷 | 비고 |
|------|-----------|------|
| 입력 IQ | Q1.15 또는 Q2.14 | ADC/IQ파일 정규화 방식에 따라 |
| NCO sin/cos | Q1.15 | 첫 믹서에 대개 충분 |
| FIR 계수 | Q1.15 또는 Q1.17 | 스톱밴드 감쇠에 영향 |
| FIR 누산기 | Q4.28 이상 | 탭 합계를 감당해야 함 |
| 믹서 출력(반올림 전) | Q2.30 | Q1.15 × Q1.15 |
| 최종 출력 스트림 | Q1.15 | 스케일링·포화 후 |

**비트 성장 규칙**:
- 덧셈: `W_sum = W + 1` (동일 포맷 피연산자, 오버플로 방지용 1비트 추가)
- 곱셈: `W_product = W_a + W_b`, `F_product = F_a + F_b`
- FIR 누산: 탭 N개일 때 가드 비트 = `ceil(log2(N))`

**포화·반올림 정책**:
- 랩(모듈로) 오버플로: DSP 체인 말단에서 거의 허용하지 않음.
- 포화(최소·최대값 고정): 블록 경계에서 선호.
- 반올림: 비트 폭 축소 시 절사보다 오차가 작음.
- 절사: 가장 싸지만 편향 발생.

**오차 분석 지표**: RMS 오차, 최대 절대 오차, SQNR(신호 대 양자화 잡음비), EVM(IQ 신호), 스퍼 레벨.

**설계 흐름**: 부동소수 참조 모델 → 범위 분석 → 스케일링 계획 → 고정소수 모델 → 오차 분석 → HDL 준비 아키텍처 → 준비 보고서.

**HDL 준비 체크리스트 (8항목)**:
입력·출력 포맷 정의, 계수 포맷 정의, 곱 비트폭 계산, 누산기 비트폭 계산, 반올림/포화 전략 선택, 레이턴시 추정, 스트리밍 인터페이스 명세, float/fixed 테스트벡터 준비.

## 검증·재현성

- 방법론 문서이며 RTL 코드·테스트벤치 없음.
- MATLAB/Python에서 float↔fixed 모델 비교를 직접 돌리는 것으로 검증.
- 설계 품질 판단: "최소 비트폭으로 허용 오차를 충족하면서 FPGA 자원 효율 유지"가 핵심 질문.

## 한계·위험

- Verilog/VHDL 코드 없음. 방법론 참고서로만 사용 가능.
- SDR(믹서, FIR, NCO) 중심이므로 범용 고정소수점 연산(PID 제어, 행렬 연산)에 직접 적용 시 추가 도메인 번역 필요.
- 라이선스 불명확. 저장소 주소: https://github.com/lay007/zynq-sdr-course 는 직접 열람하지 않아 미확인.

## 재사용 메모

- Q<I>.<F> 표기법, 비트 성장 규칙(덧셈/곱셈/FIR), 포화·반올림 정책을 MicroBlaze V SoC 고정소수점 주변장치 설계의 사양 기준으로 직접 활용할 수 있음.
- 개조: 이 방법론을 Basys3 FIR 필터 캡스톤에 그대로 적용. 계수 포맷 Q1.15, 누산기 Q4.28(32비트), 출력 Q1.15 → Q포맷 단계 명세로 capstone.json의 `integration.plan`에 포함. MicroBlaze V C 드라이버에서 Q4.28 → Q1.15 변환(비트 시프트 + 포화)을 소프트웨어로 처리할 경우 RTL 복잡도를 낮출 수 있음.
- 내 판단: S2 조합 탐색의 근거로 활용 — NCO(sin/cos)+FIR+믹서 조합을 Basys3 DSP48E1으로 구현할 때 이 포맷 표가 초기 비트폭 결정의 기준이 됨.
