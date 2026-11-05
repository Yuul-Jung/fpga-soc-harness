---
name: gisselquist-zipcpu-bit-growth
url: https://zipcpu.com/dsp/2017/07/21/bit-growth.html
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(방법론)
language: [Verilog]
tools: []
bus: none
peripherals: []
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://zipcpu.com/dsp/2017/07/21/bit-growth.html]
---

## 요약

ZipCPU 블로그(Gisselquist Technology)의 DSP 시리즈 아티클. 고정소수점 덧셈·뺄셈·곱셈에서 결과 비트폭이 얼마나 늘어나는지(bit growth) 2의 보수 극값 분석으로 유도하고, 파라미터화된 Verilog 가산기·곱셈기 작성 패턴을 제시한다. 포화·반올림은 별도 아티클로 연결.

## 구조

**비트 성장 규칙 (열람 기준)**:
- 덧셈/뺄셈: `OUTWID = max(AWIDTH, BWIDTH) + 1`. 부호 없는 뺄셈은 결과가 음수가 될 수 있으므로 부호 비트 1개 추가.
- 긴 합산(컨볼루션·FIR 누산): K개의 N비트 값 합산 시 `OUTWID ≈ N + ceil(log2(K))`. 단순 "값마다 1비트"보다 훨씬 효율적.
- 곱셈: `OUTWID = AWIDTH + BWIDTH`. 부호 있는 경우 `N+M-1`도 흔하지만 `N+M`이 안전한 상한.

**Verilog 패턴 (열람 기준)**:
- 가산기: `localparam OUTWID = (AWIDTH > BWIDTH ? AWIDTH : BWIDTH) + 1` 방식.
- 곱셈기: `localparam OUTWID = AWIDTH + BWIDTH`. `signed` 키워드로 부호 있는 곱셈을 처리.
- 비트폭을 파라미터로 선언해 모듈 하나를 여러 프로젝트에서 재사용하는 방식 권장.

**유도 방법**:
- 2의 보수에서 N비트의 최소/최대값 (-2^(N-1), 2^(N-1)-1)을 극값으로 계산.
- 덧셈 최대 = 2^(N-1)-1 + 2^(N-1)-1 = 2^N - 2 → N비트로 표현 불가 → N+1비트 필요.

## 검증·재현성

- 아티클 내에 Verilog 코드 조각이 있으며 직접 열람 확인(L3).
- 별도 저장소·테스트벤치 없음.
- 포화·반올림: "deferred to a follow-up post"로 명시. 별도 열람 필요.

## 한계·위험

- 포화(saturation) 처리 미포함.
- 반올림(rounding) 미포함.
- 2017년 아티클이지만 비트 성장 수학 자체는 변하지 않는 내용.
- 라이선스 불명확. 블로그 아티클이므로 코드 조각 복사는 별도 확인 필요.

## 재사용 메모

- 비트 성장 계산이 MicroBlaze V SoC 주변장치(FIR 필터, PID 연산)의 누산기 비트폭 결정에 직접 사용됨. 예: 탭 32개(N=16비트) FIR → 가드 비트 5개 → 누산기 21비트.
- 개조: capstone.json `memory_map` 레지스터 폭을 결정할 때 이 규칙으로 계산한 필요 비트폭을 먼저 구하고, 그 위에 AXI4-Lite 32비트 정렬로 맞춤. PID 오차 적분기의 가드 비트 수를 샘플 개수 K로부터 `ceil(log2(K))`로 산정하고 `integration.plan`에 명시하는 방식을 권장.
- 내 판단: S7 난이도 사다리 — 이 아티클이 T4 고정소수점 DSP 파이프라인의 첫 단계(비트폭 결정)이고, 포화·반올림 아티클이 두 번째, 실제 FIR/MAC 구현이 세 번째. 카탈로그에 세 단계가 모두 갖춰지면 T4 체인이 완성됨.
