---
name: ignaciosim-tt06-triple-watchdog
url: https://tinytapeout.com/chips/tt06/289
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: []
bus: none
peripherals: [WDT-triple, WDT-window, WDT-basic, WDT-independent]
stage: T1
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-04}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://tinytapeout.com/chips/tt06/289, https://github.com/ignaciosim/tt06-triple-watchdog]
---

## 요약 (3줄 이내, 내 표현으로)

TinyTapeout 6(ASIC 교육 플랫폼) 289번 프로젝트. Verilog로 작성된 삼중(Triple) 워치독 타이머로, 기본 모드·윈도우 모드·독립 모드를 하나의 소형 IP에 구현했다. ASIC 타겟이지만 순수 Verilog FSM이므로 Basys3에 포팅하면 WDT 모드 비교 실험 소스로 쓸 수 있다.

## 구조

- **구성**: 삼중(triple) 독립 WDT 채널 — 각 채널을 다른 모드로 설정 가능
- **모드** (TinyTapeout 목록 기준):
  - 기본(Basic) 모드: 단순 카운트다운 타임아웃
  - 윈도우(Window) 모드: 창 열림 전 서비스 금지 + 창 닫힘 후 타임아웃 — 양쪽 경계 모두 적용
  - 독립(Independent) 모드: 세 채널이 서로 독립적으로 동작
- **인터페이스**: ASIC 디지털 I/O (ui_in, uo_out 등 TinyTapeout 표준 핀맵), 버스 없음
- **클럭**: TinyTapeout 표준 (10 MHz)
- unverified: 채널별 비트폭(카운터 크기), 하트비트 출력 여부, 소스 파일 구조 — GitHub 직접 열람 차단

## 검증·재현성

- TinyTapeout 6 테이프아웃에 포함됨 → ASIC 합성 통과 확인(sky130 PDK 기준)
- unverified: Verilog 시뮬레이션(iverilog) 개별 테스트벤치 존재 여부
- unverified: Vivado 합성 가능 여부 (ASIC → FPGA 포팅 시 xdc 필요)

## 한계·위험

- 라이선스 미확인: GitHub 저장소 직접 열람 차단으로 LICENSE 파일 확인 불가 → 코드 반입 시 반드시 확인 필요
- ASIC 타겟: Basys3 포팅 시 타임아웃 클럭 주파수, 핀맵, 리셋 극성 조정 필요
- TinyTapeout 핀맵(ui_in[7:0], uo_out[7:0])을 AXI4-Lite로 래핑해야 MicroBlaze SoC에 연결 가능
- unverified: 윈도우 모드 창 폭 파라미터 조정 가능 여부

## 재사용 메모

- Basys3에서 WDT 모드별 행동을 7세그에 카운트다운 시각화하는 T1 실습 소스로 쓸 수 있음.
- 개조: TinyTapeout 핀맵(ui_in/uo_out) → AXI4-Lite 슬레이브 래퍼 추가. 삼중 채널 중 하나를 윈도우 모드로 고정하고, 나머지 두 채널로 서비스 타이밍 비교 실험 가능. CPU 종속 부분 없음(FSM 전용)이므로 MicroBlaze 외 CPU로 교체해도 RTL 코어는 그대로 사용.
- S2 조합 아이디어: 삼중 WDT + 7세그 3채널 카운트다운 동시 표시 → 캡스톤 T2 패키지 근거.
