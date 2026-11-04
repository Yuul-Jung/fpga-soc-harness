---
name: wdevore-tinyfpga-quadrature-decoder-gist
url: https://gist.github.com/wdevore/3274dec5cfbfbb0b63a2c6a58635d0a0
source_type: repo
vendor: lattice
board: [TinyFPGA-B2]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [IceStorm]
bus: none
peripherals: [sensor, rotary-encoder, 7seg]
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://gist.github.com/wdevore/3274dec5cfbfbb0b63a2c6a58635d0a0]
unverified: 커밋 SHA(gist 리비전 미기록), 자원 사용, 실제 보드 동작 여부
---

## 요약
TinyFPGA-B2(16 MHz)에서 로터리 엔코더 A/B를 4체배 디코딩해 0~99를 7세그에 표시하는 단일 gist. 저속 샘플링 필터와 fpga4fun식 디코더, BCD 변환으로 구성된다.

## 구조
- 모듈(gist 서술): `digital_filter`(clk, D, Q), `flip_flop`, `quadrature_decoder`(A, B, Clk → Dir, Shift), `event_detect`, `binary2bcd`(8비트→12비트 BCD), `top`.
- 디코딩: A/B를 플립플롭 열로 표본화한 뒤 XOR 조합으로 Dir와 Shift(전이마다 펄스)를 만든다. 모든 전이를 세는 4체배이며 `event_detect`가 4번에 1번만 통과시켜 한 클릭에 1 증가. 카운터는 0~99로 클램프. 주석에 fpga4fun 디코더를 기반으로 했다고 적힘.
- 필터: 4표본 시프트 레지스터, 4개가 모두 같을 때만 출력 갱신. 약 2 kHz로 나눈 클럭에서 동작해 클럭 도메인 교차 문제를 피한다고 적음.
- 표시: 이중 자릿수 7세그, 소수점 미사용.

## 검증·재현성
- 테스트벤치 없음(`flip_flop`에 시뮬레이션용 initial 블록만). 빌드 스크립트 없음, 읽기만 했고 실행하지 않았다.

## 한계·위험
- 라이선스 없음 → 코드 가져오기 불가, 사양(디코더 포트·필터 구조)만 사용. fpga4fun 등 외부 출처 인용이 있어 출처 라이선스도 불명.
- 표본 필터가 저속 클럭이라 고속 모터 엔코더(수 kHz 이상)에는 부적합 (내 판단: 2 kHz 표본은 4체배 최대 에지율을 제한).
- 카운트 범위 0~99 클램프, 방향 반전 시 동작 확인 근거 없음.

## 재사용 메모
- 내 판단: 4체배 + 한 클릭당 1 카운트라는 두 모드를 분리한 구조(Shift 펄스와 Dir)는 사람 손 엔코더(입문)와 모터 엔코더(속도 제어)를 같은 디코더로 다루는 설계의 출발점이 된다.
- 개조: 디코더는 CPU 비종속 RTL이므로 포트(A, B → dir, step)만 취해 100 MHz 동기화 2단 + 파라미터화 필터로 새로 쓴다. 모터용은 필터 표본 주기를 짧게(클럭 분주 없이 카운터 기반) 하고 AXI4-Lite 래퍼는 IP 표준에 맞춘다. Basys3 슬라이드 스위치로 A/B를 모사하는 자체 시험을 같이 쓴다.
