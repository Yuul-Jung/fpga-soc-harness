---
name: angelojacobo-fpga-i2c-implementation
url: https://github.com/AngeloJacobo/FPGA_I2C_Implementation
source_type: repo
vendor: neutral
board: [AX309 (Spartan-6 xc6slx9)]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: []
bus: none
peripherals: [comm-i2c, DS1307-RTC, 7-seg]
stage: T1
license: MIT
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/AngeloJacobo/FPGA_I2C_Implementation]
unverified: source_rev(커밋 SHA 미확인), 포트 이름·폭, 클럭 주파수, 테스트벤치 유무(페이지에 언급 없음), 자원 사용
---

## 요약
Verilog로 I2C 통신을 직접 구현해 DS1307 RTC의 시각을 읽어 7세그먼트에 표시하고, 버튼으로 시각을 RTC에 쓰는 FPGA 예제. 저장소 페이지(README와 파일 목록) 기준으로 열람했다.

## 구조
- `src/`: `ds1307_controller.v`(최상위, `i2c_top`과 `LED_mux` 결합), `i2c_top.v`(I2C 통신 제어), `LED_mux.v`(7세그 다중화), `ds1307_controller.ucf`(제약).
- 버튼 0은 시각·날짜 쓰기, 다른 버튼은 시:분:초와 월.일.년 표시 전환(README 서술, 버튼 번호 서술이 페이지 안에서 일치하지 않음).
- 소스 경로는 `src/…@(rev 미확인)`.

## 검증·재현성
- 테스트벤치, CI, 자원 수치는 페이지에서 확인하지 못함. 제약은 Spartan-6 AX309 전용(.ucf)이라 Vivado 제약(xdc)이 없다.

## 한계·위험
- 대상 보드가 Basys3가 아니고 ISE 계열 제약이다. 장치는 DS1307 하나만 다룬다(페이지 서술).
- 문서의 버튼 번호 서술이 서로 다르다(내가 확인한 불일치).

## 재사용 메모
- 내 판단: 시각 읽기·쓰기를 버튼으로 시험하는 구성이라 RTC 칩 IP의 동작 예로 참고할 수 있다. 라이선스는 MIT이나 코드 반입은 사용자 승인이 필요하다(§16.3 G4).
- 개조: 시각 7바이트(BCD) 읽기·쓰기를 AXI4-Lite 레지스터(TIME, DATE, CTRL/STATUS)로 노출하고 I2C 비트 제어는 자체 RTL로 새로 쓴다. CPU 비종속이므로 그대로 MicroBlaze V 쪽에 연결된다.
