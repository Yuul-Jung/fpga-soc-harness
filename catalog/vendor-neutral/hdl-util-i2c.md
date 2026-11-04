---
name: hdl-util-i2c
url: https://github.com/hdl-util/i2c
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: []
bus: none
peripherals: [comm-i2c]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/hdl-util/i2c, https://awesome.ecosyste.ms/projects/github.com%2Fhdl-util%2Fi2c, https://awesome.facts.dev/awesome/hdl-util/i2c]
unverified: source_rev(커밋 SHA 미확인), 라이선스(ecosyste.ms 메타만), 클럭 조건, 멀티마스터 지원 여부, 테스트벤치 유무, 자원 사용
---

## 요약 (검색 요약 기준)
hdl-util 조직의 SystemVerilog I2C 구현. 여러 I2C 관련 검색 결과에서 반복적으로 나타나며 FPGA 프로젝트에서 참조되는 범용 HDL 유틸리티 라이브러리 중 하나다. SystemVerilog 문법으로 작성되어 iverilog·verilator에서 컴파일하려면 버전 플래그가 필요할 수 있다.

## 구조
- 열람하지 않아 모듈 목록, 포트, 클럭 조건, 버스 조건 모두 `unverified`.
- hdl-util 조직은 여러 프로토콜(HDMI, I2S, SPI 등) 구현을 같은 형식으로 모아 두는 패턴 (검색 요약 기준). I2C도 비슷한 패턴으로 마스터 FSM + 슬레이브 FSM 구성일 가능성 있음(내 판단, unverified).

## 검증·재현성
- 검색 요약 기준(L2). 라이선스 미확인 — 사용 전 GitHub 페이지에서 직접 확인 필요.
- 열람 필요: 멀티마스터 중재 지원 여부, 클럭 스트레칭 처리, 테스트벤치.

## 한계·위험
- SystemVerilog: Vivado에서는 호환되나 Yosys/iverilog는 --sv 플래그 필요.
- 라이선스 `unknown`: 코드를 가져오기 전에 확인 필수.
- 열람 미완료라 모든 기능 항목이 추정임.

## 재사용 메모
- SystemVerilog 문법이지만 Vivado는 `.sv` 파일을 그대로 받아들이므로 Basys3 Pmod 연결에 쓸 수 있음.
- 개조: AXI4-Lite 래퍼 없음. 마스터 FSM을 감싸 MicroBlaze V `free_slots` IP로 만들려면 중재 플래그와 버스 타임아웃 레지스터를 추가해야 한다. 열람 후 L3로 올려 모듈 포트를 확인하고 IP 표준 래퍼 설계에 반영할 것 (내 판단).
