---
name: codeshaa-16-bit-hdlc-using-vhdl
url: https://github.com/codeshaa/16-bit-HDLC-using-VHDL
source_type: repo
vendor: amd
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Xilinx ISE]
bus: none
peripherals: [comm-uart]
stage: T2
license: MIT
stats: {stars: 31, forks: 13, commits: 4, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/codeshaa/16-bit-HDLC-using-VHDL]
---

## 요약
HDLC(High-Level Data Link Control) 프레임 송수신기. 플래그(0x7E) 경계, 비트 스터핑(연속 5개 "1" 뒤에 "0" 삽입), 16비트 CRC를 VHDL 상태 기계로 구현한다. 31★, MIT 라이선스.

## 구조
- 파일 구성: TX 상태기계(`hdlc_tx.vhd`), RX 상태기계(`hdlc_rx.vhd`), CRC 모듈(`crc16.vhd`) 세 부분으로 나뉨(README 기준; 실제 파일명은 열람에서 패턴으로 확인).
- HDLC 표준 프레임: `01111110`(플래그) + 데이터 + CRC16 + `01111110`(플래그). 비트 스터핑으로 데이터 내 플래그 충돌 방지.
- CRC: 16비트 (CRC-CCITT 계열로 추정; unverified: 다항식을 README에서 명시적으로 확인하지 못함).
- 도구: Xilinx ISE (레거시 도구). Vivado로 이식 가능하나 프로젝트 파일(.xise) 미포함.
- 시뮬레이션: ISE 시뮬레이션 결과 스크린샷이 README에 포함됨(파형 확인 가능).

## 검증·재현성
- 테스트벤치: unverified — 별도 테스트벤치 파일 존재를 확인하지 못함. README 스크린샷은 ISE Simulator(isim) 파형으로 추정.
- 자원 사용: unverified — LUT/FF 수치를 열람 범위에서 확인하지 못함.
- CI: 없음(GitHub Actions 설정 없음, 커밋 4건으로 소규모 프로젝트).
- 커밋이 4건뿐이므로 단기간에 완성된 과제 혹은 데모 수준임. 내 판단: 에지 케이스(연속 플래그, CRC 에러 처리)는 별도 검증 필요.

## 한계·위험
- VHDL 전용, Verilog 없음. iverilog·Verilator로 직접 시뮬레이션 불가.
- Xilinx ISE 도구 대상이라 Vivado 프로젝트가 없음. UCF → XDC 변환 필요.
- 비트 스터핑 에지 케이스(5개 연속 "1"이 프레임 경계에 걸치는 경우) 처리의 정확성은 unverified.
- CRC 다항식·초기값·최종 XOR이 명시되지 않아, 상대방 구현과의 호환성 확인 필요.

## 재사용 메모
- 내 판단: HDLC는 UART 위에서 패킷 경계·오류 검출을 동시에 제공하는 가장 검증된 계층 2 프로토콜. 단순 헤더+길이+체크섬 방식보다 표준화 측면에서 유리하나 비트 스터핑 구현이 복잡하다.
- 개조: TX/RX 상태기계와 CRC 모듈의 논리를 Verilog로 재작성하고, AXI4-Lite 슬레이브 래퍼로 감싸면 MicroBlaze V SoC에 통합 가능. 데이터 경로: AXI-Stream(데이터)·AXI4-Lite(제어/상태 레지스터) 분리 구조가 적합. 옮길 수 없는 부분: VHDL 코드 그대로 사용 불가(Verilog 재작성 필요), ISE 프로젝트 파일(.xise) → Vivado 마이그레이션. MIT이므로 개념 참고 후 자체 RTL 작성에 제약 없음.
