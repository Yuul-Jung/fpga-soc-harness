---
name: deepc94-pid-fpga-vhdl
url: https://github.com/deepc94/pid-fpga-vhdl
source_type: repo
vendor: amd
board: [Spartan-3 XC3S400]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Xilinx ISE]
bus: none
peripherals: [actuator-servo, sensor]
stage: T2
license: MIT
stats: {commits: 6}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: README만 열람. 작성자가 2015년 실습용이라 지원하지 않는다고 밝힘
unverified_source_rev: 열람 경로에서 SHA를 얻지 못함
sources: [https://github.com/deepc94/pid-fpga-vhdl]
---

## 요약
Spartan-3 XC3S400에 VHDL로 PID 제어기를 구현한 2015년 실습 저장소. 예시 응용은 DC 모터 속도 또는 온도 제어이고, 상세 설계는 첨부 보고서 PDF에 있다고 README가 밝힌다.

## 구조
- 설계 파일은 pid.vhd로 확인(README 서술). 그 밖의 모듈 목록, 고정소수점 형식, PID 구조는 unverified: README에 없음(보고서 PDF 미열람).

## 검증·재현성
- 시뮬레이션은 Xilinx ISE로 가능하다고만 서술. 테스트벤치 유무와 자원 사용량: unverified.

## 한계·위험
- 작성자가 더 이상 관리하지 않으며 코드 설명도 해 줄 수 없다고 적음(README 서술).
- ISE 기반이라 Vivado와 Basys3(Artix-7)로 옮기려면 프로젝트 재구성이 필요하다.

## 재사용 메모
- 내 판단: 설계 세부가 보고서 PDF에 있어 현재 카드만으로는 구조를 가져올 수 없다. PDF를 열람하면 A 트랙 PID 입문의 참고가 될 수 있다.
- 개조: PID 연산 부분만 AXI4-Lite 레지스터(KP/KI/KD, SETPOINT, OUTPUT)를 가진 IP로 감싸는 방향. 코드는 MIT이지만 반입은 승인 후(§16.3 G4).
