---
name: ahirsharan-lstm
url: https://github.com/ahirsharan/LSTM
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(가속기 셀 단위)
language: Verilog
tools: []
bus: none
peripherals: [LSTM-cell, sigmoid-approx, tanh-approx]
stage: T4
license: MIT
stats: {stars: 0, commits: 0, last_update: 2021-10-01}
doc_language: en
verification: L2
checked_at: 2026-11-07
sources: [https://github.com/ahirsharan/LSTM]
unverified: 커밋 수·최신 갱신일을 직접 확인하지 못함. 비트폭·파라미터 세부사항은 소스 열람 필요.
---

## 요약

단일 LSTM 셀 순전파를 Verilog로 구현한 교육용 저장소. ConcatMultAdd 모듈로 가중치·입력 연결 행렬-벡터 곱을 처리하고, 별도 모듈로 sigmoid/tanh 근사를 계산한다. Test.v 테스트벤치 포함. MIT 라이선스.

## 구조

- 최상위: `lstm_cell.v` — forget/input/candidate/output 게이트 + h_t/c_t 출력 (검색 요약 기준)
- `ConcatMultAdd.v`: [h_{t-1}; x_t] 연결 후 가중치 행렬 곱 + 편향 덧셈
- `Sigmoid.v`, `Tanh.v`: 근사 활성화 함수 (구현 방식 미확인 — LUT 또는 조합 로직)
- 상태 레지스터: c_t, h_t (비트폭 미확인)
- 테스트벤치: `Test.v` (통과/실패 출력 형식 미확인)
- 보드 명시 없음; 타겟 보드 불명

## 검증·재현성

- MIT 라이선스 명시 (파일 열람 미완료 → `license: MIT` 는 README 기재 기준)
- 테스트벤치가 있으나 실제 PASS/FAIL 형식, 커버리지는 미확인
- CI 없음 (검색 요약 기준)
- 합성 자원·타이밍 수치 없음

## 한계·위험

- 비트폭·Q 포맷이 명세에 없어 직접 소스 열람 필요
- 행렬 크기(은닉 상태 차원 H, 입력 차원 I)가 하드코딩인지 파라미터화인지 불명
- BRAM 적재 방식(ROM 초기화 or 외부 주입) 불명
- 최신 갱신일 2021년이므로 iverilog 호환성 최신 버전 미확인

## 재사용 메모

MIT 라이선스 단일 셀 Verilog가 핵심 가치. ConcatMultAdd 모듈 구조가 단순해서 AXI4-Lite 슬레이브 래퍼를 붙이기 쉬울 것으로 예상(내 판단).

개조: (내 판단) ① 비트폭·차원을 파라미터로 확인 후 Q8.8 또는 Q4.4로 고정 ② sigmoid/tanh 근사 모듈을 구분선형(PLA) 또는 BRAM LUT로 교체하여 정확도와 자원 균형 ③ 가중치를 `$readmemh`로 초기화하는 BRAM 모듈 추가 ④ MicroBlaze V AXI4-Lite 슬레이브로 감싸 동결 맵 free_slots에 배정. MIT 라이선스므로 사용자 승인 후 구조 참고 가능(코드 직접 복사는 사용자 승인 필요 §16.3 G4).
