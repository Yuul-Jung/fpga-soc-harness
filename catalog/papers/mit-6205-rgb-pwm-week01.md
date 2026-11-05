---
name: mit-6205-rgb-pwm-week01
url: https://fpga.mit.edu/6205/F25/assignments/week01/led_hw
source_type: course
vendor: neutral
board: [Urbana FPGA board]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [cocotb, Icarus Verilog, Pulseview]
bus: none
peripherals: [pwm-rgb, led-breathing]
stage: T1
license: unknown
stats: {stars: 0, commits: unknown, last_update: 2025}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://fpga.mit.edu/6205/F25/assignments/week01/led_hw]
---

## 요약

MIT 6.205 (Digital Systems Lab, F25) 1주차 하드웨어 과제. Urbana FPGA 보드에서 RGB LED를 스위치로 제어하는 8비트 PWM 모듈 작성. S6 핵심 실패 사례 포함: 카운터 중간에서 듀티 사이클을 바꾸면 잘못된 PWM 주파수가 발생하며, 이를 카운터 리셋 시점에 래치해야 한다고 명시.

## 구조
- 보드: Urbana FPGA 보드 (Xilinx, `clk_100mhz` 100 MHz).
- RGB LED: common-cathode, `rgb0`, `rgb1` 2개.
- 입력: 스위치 `sw[15:0]` → 5R + 6G + 5B 형식(RGB565)으로 색상 선택.
- PWM: 8비트 카운터(0~255), 출력 HIGH while `count < dc_in`. 주기 = 256 사이클 = 2.56 µs @ 100 MHz.
- 검증 방법: Python cocotb 테스트벤치 (Icarus 시뮬레이터) + Pulseview 로직 애널라이저 (보드 측정).

## 검증·재현성
- MIT 강의 자료 직접 열람(과제 페이지 전체 확인). 소스코드 미열람(PROVENANCE_REQUIRED로 차단).
- Urbana 보드 타겟. Basys3로 포팅 시 xdc 클럭 핀 변경, RGB LED 핀 매핑 수정 필요(구조는 동일).
- cocotb/Icarus 기반 테스트벤치 — Basys3 환경에 그대로 재활용 가능한 검증 패턴.
unverified: 소스코드 직접 미열람(자동 모드 접근 제한). 보드 동작 확인 여부 미명시.

## 한계·위험
- 감마 보정 없음 (과제 의도상 기본 PWM만 다룸).
- HSV→RGB 변환 없음.
- 라이선스 미명시.
- 소스 저장소 위치 과제 페이지에서 미확인.

## 재사용 메모
- **S6 핵심 실패 사례**: "카운터 중간에 듀티 사이클을 바꾸면 잘못된 PWM 주파수가 발생한다. 변경은 카운터 리셋 시점에 래치해야 한다." — 이 패턴은 모든 PWM 모듈 설계에서 주의해야 할 glitch 방지 규칙.
- RGB565 → 8비트 듀티 사이클 변환 방식(5R+6G+5B → 8비트 채널별 scale)은 Basys3 스위치 16개 활용 아이디어로 직접 적용 가능.
- cocotb Python 테스트벤치 패턴은 Basys3 MicroBlaze V AXI4-Lite RGB LED IP 검증에 착용 가능.
개조: Basys3 Artix-7 100 MHz 클럭 환경과 완전 호환. `clk_100mhz` 그대로 사용 가능. RGB LED Pmod 핀 xdc만 교체하면 되며, PWM 핵심 로직(카운터·래치 패턴)은 그대로 AXI4-Lite 슬레이브 IP에 감싸는 자체 RTL 재작성에 착용. 래치-at-reset 패턴을 반드시 적용할 것. 내 판단: T1 단계 RGB PWM IP 작성 전 반드시 이 실패 사례를 참고 — 가장 직접적인 S6 교훈 카드.
