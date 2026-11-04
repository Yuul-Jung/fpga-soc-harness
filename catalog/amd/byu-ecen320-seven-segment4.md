---
name: byu-ecen320-seven-segment4
url: https://byu-cpe.github.io/ecen320/labs/lab-07
source_type: course
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: SystemVerilog
tools: [Vivado]
bus: none
peripherals: [7seg-mux, hid-btn]
stage: T1
license: unknown
stats: {stars: 0, commits: 0, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://byu-cpe.github.io/ecen320/labs/lab-07]
---

## 요약

BYU ECEN320 디지털 시스템 과정의 Lab 7: Basys3 4자리 7세그먼트 디스플레이 멀티플렉서 고급 구현. `seven_segment4` SystemVerilog 모듈에 자리별 blank 제어(`blank[3:0]`)와 소수점 개별 제어(`dp_in[3:0]`)를 파라미터화된 갱신률(`REFRESH_RATE`)로 구현한다.

## 구조

- 모듈: `seven_segment4` (파라미터: `CLK_FREQUENCY=100_000_000`, `REFRESH_RATE=200`)
- 포트: `clk`, `rst`, `data_in[15:0]`(4자리 BCD), `blank[3:0]`(자리별 소등), `dp_in[3:0]`(소수점 개별), `segment[7:0]`(cat[6:0]+dp), `anode[3:0]`(active-low 공통 애노드)
- 최상위 `ssd_top`: Basys3 버튼 5개 연결 — `btnc`(반전), `btnd`(리셋), `btnu`(전체 blank), `btnl`(전체 DP on), `btnr`(왼쪽 2자리 blank)
- 테스트벤치: `tb_multisegment.sv`; 시뮬레이션 `REFRESH_RATE=500_000` Hz (가속)
- 내 판단: 갱신 주기 = `CLK_FREQUENCY / REFRESH_RATE / 4` 클럭마다 애노드를 순환하는 표준 분주·MUX 구조로 추정 (열람 범위 한계 — 소스 파일 직접 미확인)

## 검증·재현성

- 강의 과제로서 Basys3 xdc 제공 추정 (강의 페이지에 "constraints file" 언급 — 미확인)
- 테스트벤치 존재 확인 (`tb_multisegment.sv`); CI 여부 미확인
- 소스 GitHub 링크 강의 페이지에서 미발견 → verification L2 유지

## 한계·위험

- 소스 코드 직접 열람 불가 (강의 내부 Git 추정, 외부 공개 링크 없음)
- 라이선스 불명확 — 강의 자료 저작권 적용 가능
- `REFRESH_RATE=200`은 50 Hz × 4 = 200 Hz 등가, 경계치 (45 Hz 이상 기준 충족은 추정)
- unverified: 소스 파일 접근 경로·라이선스 미확인, 자원 사용(LUT/FF) 미확인

## 재사용 메모

- `blank[3:0]`와 `dp_in[3:0]` 포트 설계는 MicroBlaze V AXI4-Lite 슬레이브 레지스터로 직접 매핑 가능: `DIGIT_CTRL` 레지스터(blank 4비트 + dp_en 4비트 + data 16비트 구조).
- `REFRESH_RATE` 파라미터는 IP 표준의 제네릭 필드로 올릴 수 있어 런타임 조정 없이 합성 시 최적화 가능.
- 개조: MicroBlaze V 기준(AXI4-Lite, 동결 맵 `free_slots` 하나 배정) — `seven_segment4`를 AXI4-Lite 슬레이브 래퍼로 감싸 `DIGIT_CTRL`(W/R, 오프셋 0x00), `STATUS`(R, 현재 활성 자리 번호·DP 상태, 오프셋 0x04) 2개 레지스터로 구성. `blank`·`dp_in` 필드는 소프트웨어에서 비트 필드 마스크로 조작. 옮길 수 없는 부분: `btnu`/`btnl`/`btnr` 버튼 직결 하드웨어 로직 → 소프트웨어 레지스터 쓰기로 대체.
