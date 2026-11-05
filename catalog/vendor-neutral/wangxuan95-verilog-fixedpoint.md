---
name: wangxuan95-verilog-fixedpoint
url: https://github.com/WangXuan95/Verilog-FixedPoint
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
sources: [https://github.com/WangXuan95/Verilog-FixedPoint]
---

## 요약 (검색 요약 기준)

WangXuan95가 작성한 Verilog 고정소수점 연산 라이브러리. 중국어 설명 기준: 가산, 감산, 곱셈, 절단(truncate), 반올림(round), 형식 변환(format conversion)을 Verilog RTL로 구현. Q포맷 고정소수점 수를 대상으로 한다.

## 구조

- 검색 결과 요약만 열람, 저장소 본문 미열람
- 함수/모듈 목록: 가산·감산·곱셈·절단·반올림·형식 변환 모듈 추정
- unverified: 실제 파일 목록, 파라미터, 보드 타겟 미확인

## 검증·재현성

- unverified: 테스트벤치, CI, 시뮬레이션 환경 미확인
- unverified: 라이선스 미확인 (저장소 본문 미열람)

## 한계·위험

- 본문 미열람으로 모든 구체적 사양이 불확실
- 라이선스 미확인 — 사용 전 필수 확인
- Basys3 타겟 여부 불명

## 재사용 메모

- Q포맷 연산 패턴을 MicroBlaze V NPU IP(T2~T4) 설계 참고자료로 활용 가능 (내 판단)
- 개조: 고정소수점 연산 사양(포트, 파이프라인 단계, 반올림 모드)을 AXI4-Lite 래퍼에 맞게 재설계 필요. 코드 복사 금지(라이선스 미확인)
