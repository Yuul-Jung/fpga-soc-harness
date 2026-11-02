---
name: dpiegdon-verilog-can
url: https://github.com/dpiegdon/verilog-can
source_type: repo
vendor: neutral
board: [unspecified]
fit_basys3: unknown
cpu: none(FSM)
language: Verilog
tools: [unverified]
bus: Wishbone
peripherals: [comm-can]
stage: T2
license: LGPL-2.1
stats: {stars: 20, forks: 10, commits: 23}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: README가 "Currently nonfunctional"로 표기, 진행 중 작업
sources: [https://github.com/dpiegdon/verilog-can, https://github.com/dpiegdon/verilog-can/blob/master/can_top.v]
---

## 요약
OpenCores의 SJA1000 호환 CAN 컨트롤러(Igor Mohor 작, 2009년경부터 방치)를 정리·버그 수정하려는 포크. 현재 동작하지 않는다고 README가 밝힌다.

## 구조
- 코어 파일: `can_acf/bsp/btl/crc/fifo/ibo/registers/top.v`, 레지스터 변형 4종, 설정 `can_top_defines.v`, 테스트벤치 `can_top_tb.v`.
- `can_top.v` 모듈 4종(can_top.v@master): `can_controller`(8비트 `addr_i/data_i/data_o`, `cs_i`, `we_i`), `can_wishbone_top`(wb_* 8비트 데이터·주소, `wb_ack_o`), 8051 버스 래퍼 2종. 공통 `rx_i/tx_o/irq_n_o/bus_off_on_o/clkout_o`.
- 파라미터는 `Tp`(지연) 하나. 선택 BIST 포트는 `CAN_BIST` 정의 시.

## 검증·재현성
- Makefile과 `testbench/` 폴더 존재. 시뮬레이터·타깃 FPGA: unverified: README에 명시 없음. 자원 사용: unverified.

## 한계·위험
- "현재 동작하지 않음" 표기. SJA1000 기능 구현 범위 서술 없음.
- 헤더: LGPL 2.1 이상. 또한 헤더가 CAN 프로토콜은 Bosch 특허 대상이며 실리콘 구현 시 라이선스가 필요하다고 안내(FPGA 교육용과는 구분해 확인 필요).
- 커밋 날짜·SHA: unverified: 페이지에서 확인 못함. LICENSE 본문은 열람 못해 LGPL은 헤더 기준.

## 재사용 메모
- 내 판단: 8비트 레지스터 버스(주소 8비트)와 `irq_n_o` 구조는 레지스터 맵 설계의 참고가 된다. 기능이 동작하지 않아 학습·구조 참고 이상으로 쓰기 어렵다.
- 개조: 레지스터 접근이 단순 8비트 읽기/쓰기라 AXI4-Lite 슬레이브 래퍼로 감싸기 쉽다(CPU 코어와 무관). 다만 코어 신뢰성이 없어 WangXuan95 계열 FSM을 자체 RTL로 쓰는 쪽이 현실적이다(내 판단).
