---
name: pyadav1992-rtl-fixedpoint-arithmetics
url: https://github.com/pyadav1992/RTL-FixedPoint-Arithmetics-MathematicalFunctions
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(DSP IP)
language: Verilog
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://github.com/pyadav1992/RTL-FixedPoint-Arithmetics-MathematicalFunctions]
---

## 요약 (검색 요약 기준)

RTL 수준의 고정소수점 산술 연산 및 수학 함수 라이브러리. 검색 결과 제목 기준: 덧셈, 뺄셈, 곱셈, 나눗셈 등 기본 사칙연산과 수학 함수를 RTL로 구현. FPGA 타겟으로 추정.

## 구조

- 검색 결과 요약만 열람, 저장소 본문 미열람
- unverified: 모듈 목록, Q포맷 지원 여부, 파이프라인 구조 미확인
- unverified: 보드 타겟, 클럭, 자원 사용량 미확인

## 검증·재현성

- unverified: 테스트벤치, CI, 시뮬레이션 환경 미확인
- unverified: 라이선스 미확인 (저장소 본문 미열람)

## 한계·위험

- 본문 미열람으로 모든 구체적 사양이 불확실
- 라이선스 미확인 — 사용 전 필수 확인
- 수학 함수(제곱근, 로그 등) 포함 여부 불명

## 재사용 메모

- RTL 고정소수점 수학 함수가 포함된 경우 활성화 함수(Sigmoid, Tanh, GELU) 근사 구현 참고 가능 (내 판단)
- 개조: Basys3 Artix-7 타겟으로 포팅 및 AXI4-Lite 래퍼 추가 필요. 라이선스 확인 없이 코드 복사 금지
