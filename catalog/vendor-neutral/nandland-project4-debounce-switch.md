---
name: nandland-project4-debounce-switch
url: https://nandland.com/project-4-debounce-a-switch/
source_type: article
vendor: neutral
board: [NandLand Go Board]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog, VHDL
tools: []
bus: none
peripherals: [switch-debounce]
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://nandland.com/project-4-debounce-a-switch/]
---

## 요약

NandLand.com의 스위치 디바운스 입문 프로젝트(Project 4). iCE40HX1KVQ100 (25 MHz, NandLand Go Board) 기준이지만 Verilog·VHDL 양언어 소스와 카운터 기반 알고리즘을 완전히 설명한 교육 자료. Basys3(100 MHz)로 포팅 시 카운터 한계값만 4배 조정.

## 구조

- **알고리즘**: 순수 카운터 방식 (FSM 없음)
  - `i_Switch ≠ r_State`: 카운터 증가
  - 카운터 도달(`c_DEBOUNCE_LIMIT = 250_000`): `r_State` ← `i_Switch`, 카운터 리셋
  - `i_Switch = r_State`: 카운터 즉시 리셋 (안정 상태 유지)
- **타이밍**: 10 ms @ 25 MHz (c_DEBOUNCE_LIMIT = 250,000, 18비트 카운터)
- **모듈 인터페이스**:
  - `Debounce_Switch(i_Clk, i_Switch → o_Switch)`: 순수 디바운스 모듈
  - `Debounce_Project_Top(i_Clk, i_Switch_1 → o_LED_1)`: 최상위 (토글 LED 출력)
- **에지 활용**: 디바운스된 `o_Switch`의 오름 에지에서 LED를 토글 (내장 로직, 별도 에지 모듈 없음)
- **언어**: Verilog와 VHDL 양쪽 소스 제공 — 같은 로직을 비교 학습 가능

## 검증·재현성

- NandLand.com 사이트에서 소스 코드와 설명 직접 열람(L3)
- Go Board(iCE40) 기준. Basys3(Artix-7) 포팅 시 필요한 변경:
  - `c_DEBOUNCE_LIMIT`: 250,000 → 1,000,000 (25 MHz → 100 MHz, 10 ms 유지, 20비트 카운터)
  - 핀 배정(xdc)과 클럭 소스 교체
  - iCE40 전용 IP(SB_PLL40 등) 없으므로 RTL 로직 자체는 그대로 사용 가능

## 한계·위험

- 라이선스: 사이트에 명시되지 않음. 코드 사용 전 nandland.com 이용약관 확인 필요
- 짧은 누름, 긴 누름, 멀티 클릭 감지 없음 — 순수 디바운스만 제공
- FSM 없는 단순 카운터 방식이므로 카운터 도달 직전에 채터가 발생하면 타이밍이 늘어날 수 있음 (내 판단)

## 재사용 메모

가져올 수 있는 부분: 카운터 기반 디바운스 로직 (Verilog). iCE40 전용 요소 없어 Artix-7 RTL 그대로 적용 가능.

개조: Basys3 포팅은 `c_DEBOUNCE_LIMIT` 파라미터만 변경으로 완료. MicroBlaze V AXI4-Lite 버튼 IP의 디바운스 계층(하위 모듈)으로 사용 가능. 파라미터를 AXI 레지스터로 외부화하면 소프트웨어에서 임계값 조정 가능. FSM 없는 단순 구조라 byu-ecen220-lab08-debounce-basys3의 FSM 버전과 비교 학습용으로 적합(S7 사다리 T0 첫 계단). 옮길 수 없는 부분: 없음 (보드 고유 요소 없는 순수 RTL 로직).

내 판단: S4 제약 역전 사례 — FPGA는 클럭마다 카운터를 하드웨어로 병렬 증가시키는 반면, MCU는 같은 타이머를 소프트웨어 폴링으로 처리해야 한다. 이 단순 Verilog 모듈은 "FPGA에서 디바운스는 1개 모듈 인스턴스 = 1개 버튼이고 각 버튼이 완전히 독립적"임을 보여주는 최소 사례.
