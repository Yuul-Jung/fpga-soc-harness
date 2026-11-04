---
name: byu-ecen220-lab08-debounce-basys3
url: https://ecen220wiki.groups.et.byu.net/labs/lab-08/
source_type: course
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: SystemVerilog
tools: [Vivado]
bus: none
peripherals: [switch-debounce, button-debounce, one-shot-edge-detect, 7seg-counter]
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://ecen220wiki.groups.et.byu.net/labs/lab-08/]
---

## 요약

BYU ECEN 220 Lab 08 — Basys3 100 MHz 기반 SystemVerilog 버튼 디바운스 FSM 강의 실습. `btncn`·`btnu` 2개 버튼을 디바운스해 4자리 7세그먼트 카운터를 증가/리셋한다. FSM 기반 디바운스 + 원샷 에지 검출 패턴을 명세화한 교육 자료.

## 구조

- **디바운스 타이밍**: 5 ms = 500,000 사이클 @ 100 MHz (≈19비트 카운터). 타이머는 `clrTimer` 신호로만 리셋되고, 글로벌 리셋에는 반응하지 않음(내 판단: 타이머가 리셋과 무관하게 독립적으로 동작하는 것이 의도적 설계)
- **디바운스 FSM**: 입력 2개(noisy, timerDone), 출력 2개(debounced, clrTimer)
  - 상태: IDLE(debounced=0, clrTimer=1) → WAIT(debounced=0, clrTimer=0) → DEBOUNCED(debounced=1, clrTimer=1)
  - noisy가 High 유지 + timerDone=1 → DEBOUNCED 천이
  - noisy가 Low로 돌아오면 → IDLE로 복귀, clrTimer=1
- **원샷 에지 검출**: `F1 AND ~F2` 패턴 (F1 = 현재 클럭의 debounced, F2 = 이전 클럭의 debounced). 오름 에지 1클럭 펄스를 카운터 enable 신호로 사용
- **모듈 인터페이스**:
  - `debounce(clk, reset, noisy → debounced)`: 순수 FSM + 타이머
  - `debounce_top(CLK100MHZ, btnc, btnu → an[3:0], seg[6:0], dp)`: 최상위 (보드 핀 직결)
- **검증**: Tcl 시뮬레이션 스크립트 제공 — 짧은 바운스 펄스(< 5 ms) 필터링 테스트, 긴 바운스 펄스(> 5 ms) 통과 테스트 포함
- **보드**: Basys3 100 MHz, 입력 btnc·btnu (Basys3 내장 버튼), 출력 4자리 7세그

## 검증·재현성

- BYU 강의 위키에서 직접 열람(L3). 웨이브폼 다이어그램, FSM 상태 천이도, Tcl 시뮬레이션 스크립트 명세까지 확인
- Basys3 100 MHz 기준이므로 보드 직접 적용 가능(fit_basys3: yes)
- 자원 사용·WNS: 미기록 (교육 자료 특성상 간략 표현)

## 한계·위험

- 라이선스: 미명시. 강의 자료이므로 교육 목적 사용 가정 가능하나 확인 필요
- 단일 버튼 단위 모듈 구조 — 복수 버튼에는 모듈을 복수 인스턴스화해야 함 (인스턴스당 ~19비트 카운터 1개)
- 멀티 클릭이나 긴 누름 감지는 이 실습 범위 밖

## 재사용 메모

가져올 수 있는 부분: `debounce` FSM + 원샷 에지 검출 패턴 (Verilog-2001로 재작성 용이). 타이머 독립 리셋 설계는 채터 필터의 명확한 구현 사례.

개조: MicroBlaze V AXI4-Lite 버튼 IP의 하위 디바운스 계층으로 직접 사용 가능. FSM 출력인 `debounced` → 에지 검출 → IRQ 발생 경로가 MicroBlaze V 인터럽트 설계와 직접 연결. 500,000 사이클(5 ms) 상한을 AXI 레지스터로 프로그래밍 가능하게 개조하면 T2 수준 IP 완성. 옮길 수 없는 부분: 7세그 최상위 로직 (보드 주변장치 고유, MicroBlaze V IP와 별개).

내 판단: S7 난이도 사다리의 T0 계단(입문 FSM 디바운스). 단순 카운터 방식(nandland-project4-debounce-switch)과 달리 FSM 명세가 명확해 모듈 경계 설계 연습에 적합. BYU ECEN 220 강의이므로 채택율·실험 사례가 많을 것으로 추정(내 판단).
