---
name: arxiv-1511-05552-rnn-fpga
url: https://arxiv.org/abs/1511.05552
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: []
bus: none
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2015-11-17}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://arxiv.org/abs/1511.05552]
---

## 요약 (3줄 이내, 내 표현으로)

Ferreira 등이 2015년 발표한 FPGA 위 RNN 구현 연구. Elman 네트워크(단순 순환 셀: 현재 입력 + 이전 은닉 상태 → 출력)를 VHDL로 작성하고, 고정소수점 양자화(16비트)가 부동소수점 대비 정확도 손실이 미미함을 보였다. 검색 요약 기준이므로 세부 자원 수치는 미확인.

## 구조

- unverified: 아키텍처 세부(레이어 크기, 클럭, 보드 종류)는 논문 본문 미열람으로 확인하지 못함
- 구조: Elman RNN 셀, 행렬×벡터 곱 + tanh 활성화 + 귀환 경로
- 양자화: 16비트 고정소수점, saturation 처리 포함(검색 요약 기준)
- 언어: VHDL (Verilog 아님)

## 검증·재현성

- unverified: 테스트벤치, CI, 자원 사용(LUT/FF/BRAM), WNS 미확인
- unverified: GitHub 코드 공개 여부 미확인 — 논문 연구 출판물이므로 소스 미공개 가능성 높음

## 한계·위험

- 2015년 논문으로 최신 도구(Vivado 2024.2)와 호환성 미확인
- VHDL 소스이므로 Verilog-2001 환경으로 직접 사용 불가
- 보드 정보 미명시; Basys3 적합성 unknown (내 판단: Elman 셀 단독은 LUT 수 적어 T4 개조 범위 내 가능하나, 소스 미공개이면 직접 재현 불가)
- Basys3 제약 태그: `needs-port` (가정, 소스 미확인)

## 재사용 메모

- 이 논문의 직접 재현보다 "Elman 셀 고정소수점 FPGA 구현" 패턴 참고용
- 개조: MicroBlaze V AXI4-Lite 슬레이브로 감싸는 순환 셀 IP를 자체 작성 시, 귀환 레지스터(이전 은닉) + 행렬-벡터 곱 + 활성화 LUT 구조를 참고할 수 있음
- 단, 소스 미공개이므로 사양만 참고하고 RTL은 자체 작성 필요 (§16.3 G4 조건 미충족)
- 더 적합한 오픈소스 대안: arxiv-2310 계열(2023년 LSTM 최적화 논문), GitHub systolic array 사례들
