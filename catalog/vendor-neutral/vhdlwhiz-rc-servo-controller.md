---
name: vhdlwhiz-rc-servo-controller
url: https://vhdlwhiz.com/rc-servo-controller-using-pwm/
source_type: article
vendor: lattice
board: [iCEstick]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [iCEcube2, ModelSim]
bus: none
peripherals: [actuator-servo]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://vhdlwhiz.com/rc-servo-controller-using-pwm/]
unverified: 게시일, 라이선스(압축 파일은 이메일 등록 후 제공), 핀 제약 세부, 실제 서보 동작 영상
---

## 요약
RC 서보를 FPGA 핀 하나의 PWM으로 구동하는 VHDL 모듈 설명. 위치 정수를 받아 펄스 폭으로 바꾼다. Lattice iCEstick(12 MHz) 기준이지만 구조는 보드 비종속이다.

## 구조
- 서보 모듈 제네릭: clk_hz, pulse_hz, min_pulse_us, max_pulse_us, step_count. 포트: clk, rst, position(0~step_count-1), pwm.
- 주기 50 Hz(20 ms), 펄스 폭 500~2500 µs(TowerPro SG90에서 약 180도라고 저자가 적음). 일반적으로는 1~2 ms라는 설명도 있다.
- 최상위는 iCE40 HX1K 핀에 pwm을 연결.

## 검증·재현성
- 테스트벤치는 1 MHz 클럭으로 5개 위치를 순회하고 보고를 출력하지만 펄스 폭은 파형 커서로 직접 재야 하는 수동 방식이다. 저자가 자체 점검형을 개선 과제로 언급.

## 한계·위험
- FPGA 로직은 3.3 V, 대부분의 서보는 5 V라서 저자는 PWM 출력에 레벨 변환기를 두고 서보 전원은 외부 5 V를 쓰라고 권한다.
- 라이선스 미기재, 내려받기는 이메일 등록 필요 → 받지 않았고 사양만 쓴다.

## 재사용 메모
- 내 판단: 제네릭으로 펄스 폭 범위와 단계 수를 묶은 점이 IP 파라미터화의 좋은 사례. 서보마다 범위가 달라 범위를 레지스터로 두는 편이 낫다.
- 개조: 자체 Verilog로 min/max 펄스 폭(µs)과 위치 값을 AXI4-Lite 레지스터로 노출하고, 클럭 100 MHz 기준 카운터 값은 파라미터로 계산한다. 자체 점검형 테스트벤치(펄스 폭을 `!==`로 비교)를 추가. 서보 신호는 3.3 V 직결 가능 여부를 부품별로 확인하고 전원은 분리, GND만 공통.
