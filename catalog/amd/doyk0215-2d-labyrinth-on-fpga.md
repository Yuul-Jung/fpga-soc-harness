---
name: doyk0215-2d-labyrinth-on-fpga
url: https://github.com/doyk0215/2D-Labyrinth-on-FPGA
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog, VHDL, Tcl
tools: [Vivado 2025.2]
bus: none
peripherals: [PS2, OLED-SPI, centre_button-longpress, switch-debounce]
stage: T4
license: unknown
stats: {stars: 0, commits: 219, last_update: 2026-11}
doc_language: en
verification: L3
checked_at: 2026-11-05
source_rev: 51ef823
sources: [https://github.com/doyk0215/2D-Labyrinth-on-FPGA/pull/74, https://github.com/doyk0215/2D-Labyrinth-on-FPGA]
---

## 요약

Basys3(XC7A35T, Vivado 2025.2)로 구현한 2D 미로 탐험 게임. OLED 디스플레이에 미로를 렌더링하고, PS/2 키보드로 움직임을 입력하며, 중앙 버튼(BTNC)의 긴 누름(2초)으로 게임·물리·OLED·PS/2 서브시스템 전체를 초기화한다. 긴 누름 감지 모듈(`centre_button`)이 이 저장소의 핵심 사례다.

## 구조

- 최상위 구조: 게임 FSM + 물리 FSM + OLED 렌더러 + PS/2 수신기 + `centre_button` 모듈이 병렬 동작
- `centre_button` 모듈 (PR #74 기준):
  - 입력: `clk`(100 MHz), `rst`, `i_btn_raw` (BTNC 핀의 비동기 raw 입력)
  - 출력: `o_long_press` (1클럭 펄스, 2초 누름 완료 시점)
  - 디바운스: 약 10 ms (~1,000,000 사이클 @ 100 MHz) 카운터. 버튼이 눌린 상태를 유지할 때만 카운터 증가
  - 긴 누름: `LONG_PRESS_CYCLES = 200_000_000` (100 MHz × 2초). 포화 카운터(saturating counter): 임계값 도달 후 카운터가 더 올라가지 않음
  - 재무장(re-arm): 버튼을 놓으면 카운터 리셋 → 다시 누르면 처음부터 카운 → 겹침(overlap) 없음
  - 짧은 누름: 릴리즈 시점에 `o_short_press` 단일 펄스 (긴 누름 완료 전에 놓을 경우). 현재 게임 로직에서는 짧은 누름 출력을 사용하지 않으나 포트는 존재
  - 리셋 전파: `o_long_press`가 게임·물리·OLED·PS/2 FSM의 `rst` 신호에 연결됨
- PS/2 수신기: VHDL로 구현 (PS2_RX.vhd), Verilog 최상위에서 혼합 언어 인스턴스화
- OLED: SPI 방식 (Pmod OLED Rev C 또는 호환). Basys3 Pmod 헤더 직결
- 디렉터리 구조: PR #74 머지 기준 219 커밋, 단일 Vivado 프로젝트 (.xpr)
- 클럭: 100 MHz (온보드 클럭 직접 사용, PLL 미확인)

## 검증·재현성

- Vivado 2025.2로 빌드. .xpr과 xdc 파일이 저장소에 있는 것을 메인 페이지 디렉터리 목록에서 확인
- PR #74: "board verified by reviewer DY" 주석 확인 → 보드 동작 검증 사례 존재 (내 판단: S3 수준이지만 에이전트가 직접 확인한 것이 아니므로 `board` 미기록)
- 별도 테스트벤치(.tb 파일) 존재 여부: 열람 미확인 (`unverified: GitHub blob/raw 접근 불가`)
- LUT/FF/BRAM 자원 사용: 열람 미확인 (`unverified: 합성 보고서 접근 불가`)
- WNS: 미확인

## 한계·위험

- 라이선스: 없음(LICENSE 파일 미확인, `unverified: GitHub raw 접근 불가`). 코드를 가져올 경우 라이선스 확인 필요
- 짧은 누름과 긴 누름이 단일 모듈에서 나오는 구조라 짧은 누름 타이밍이 긴 누름 임계값에 종속됨
- PS/2 수신기가 VHDL이므로 Verilog 전용 환경에서는 Verilog 재작성 필요
- Vivado 2025.2 사용 → 구 버전(2024.2)에서의 호환성 미확인

## 재사용 메모

가져올 수 있는 부분: `centre_button`의 디바운스 + 포화 카운터 + 재무장 FSM 패턴. CPU 없이 순수 FSM 구조라 MicroBlaze V와 무관하게 이식 가능.

개조: `centre_button`을 AXI4-Lite 버튼 IP로 감쌀 수 있다. LONG_PRESS_CYCLES를 AXI 레지스터(REG0)에 쓰면 소프트웨어에서 임계값을 런타임에 변경 가능. `o_long_press`를 MicroBlaze V IRQ 핀(인터럽트)에 연결하면 ISR에서 게임 리셋 등 소프트웨어 동작을 트리거할 수 있음. 옮길 수 없는 부분: OLED·PS/2·물리 FSM 로직(게임 고유), VHDL PS/2 수신기(Verilog 재작성 필요).

내 판단: Basys3 버튼 인터럽트 IP의 T2 단계 출발점으로 적합. 포화 카운터 + 재무장 패턴은 FPGA 특유의 하드웨어 병렬 처리 강점을 보여주는 대표 사례(S4 제약 역전: MCU 소프트웨어 디바운스와 달리 클럭마다 독립 카운터 증가가 가능).
