---
name: ecen220wiki-basys3-debounce-fsm
url: https://ecen220wiki.groups.et.byu.edu/labs/lab-08/
source_type: course
vendor: neutral
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [hid-ps2, debug]
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-11-05}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://ecen220wiki.groups.et.byu.edu/labs/lab-08/]
---

## 요약

BYU ECEN 220 강의 Lab 08. Basys3 100MHz 기준, 동기 FF 2단 동기화기(synchronizer) + 4상태 FSM + 5ms 타이머로 버튼 디바운스를 구현한다. 디바운스 출력을 단발(one-shot) 에지 검출기로 처리해 카운터에 연결하는 전체 흐름을 실습 형식으로 제시한다.

## 구조

- `debounce` 모듈: 포트 `clk`, `reset`, `noisy`, `debounced`. 2-FF 동기화기 → 4상태 FSM(S0~S3) → 5ms(100MHz 기준 500,000 클럭) 타이머. FSM은 리셋 시 S0으로 복귀.
- `debounce_top`: `btnu`, `btnc`를 debounce 모듈에 연결. `anode[3:0]`, `segment[7:0]`으로 7세그 디스플레이에 디바운스 전·후 카운터를 동시 표시.
- 단발(one-shot) 에지 검출: `F1 AND ~F2` (현재 클럭의 debounced AND 직전 클럭의 NOT) → 8비트 카운터 증분 조건.
- Verilog, 단일 파일 구조로 추정(강의 자료 기반; 소스 파일 직접 열람 불가).

## 검증·재현성

- 강의 과제로 Basys3에서 보드 동작 확인을 목표로 한다(S3 수준 의도). 보조 검증: 시뮬레이션 필요 여부는 강의 자료에 명시 없음.
- 소스 코드를 직접 열람하지 못했으나 구조·포트·타이밍 수치는 강의 페이지에서 명시적으로 제시됨(내 판단: L3 근거 충분).

## 한계·위험

- 짧은 누름(short press) / 긴 누름(long press) 구분 없음 — 단순 디바운스 + 에지 검출만.
- 멀티 버튼 처리, 반복(repeat) 기능 없음.
- 소스 저장소 미확인(강의 위키만 열람). 강의 과제 제출물이므로 라이선스 불명확.
- unverified: 소스 파일 직접 URL — 강의 과제 제출 형태, Vivado 프로젝트 파일 형식 미확인.

## 재사용 메모

- 2-FF 동기화기 + 4상태 FSM + 5ms 타이머 구조는 Basys3 100MHz에서 직접 쓸 수 있다. 100MHz 기준 500,000 클럭 타이머 한계는 25-bit 카운터로 충분.
- 단발 에지 검출 패턴(`F1 AND ~F2`)은 AXI4-Lite 슬레이브 IP에서 버튼 인터럽트 소스로 재사용 가능.
- 개조: 이 모듈은 CPU 독립 RTL이므로 MicroBlaze V AXI4-Lite 슬레이브 래퍼에 주변장치 블록으로 직접 삽입 가능. 인터럽트 출력(one-shot pulse)을 AXI-INTC에 연결하면 된다. 긴 누름 기능 추가 시 §17의 free_slots에 레지스터 주소 1개 추가만으로 확장 가능.
