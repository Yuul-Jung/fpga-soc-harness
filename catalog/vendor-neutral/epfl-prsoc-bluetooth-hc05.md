---
name: epfl-prsoc-bluetooth-hc05
url: https://wiki.epfl.ch/prsoc/bluetooth-hc05
source_type: course
vendor: neutral
board: ["PrSoc 교육 보드(FPGA 부품명 unverified)"]
fit_basys3: needs-port
cpu: "unverified: 페이지에 미기재"
language: "unverified"
tools: ["unverified"]
bus: none
peripherals: [comm-bt, comm-uart]
stage: T2
license: unknown (위키에 미기재)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://wiki.epfl.ch/prsoc/bluetooth-hc05]
---

## 요약
EPFL PrSoc 교육 보드의 확장 헤더에 HC-05를 꽂는 연결 안내. 신호 이름과 방향 표만 있고 HDL이나 AT 절차는 없다.

## 구조
- 6핀 + 추가 1핀: BLT_State(→FPGA, LOW 미연결/HIGH 연결), BLT_RxD(FPGA→, 9600 또는 38400 bps), BLT_TxD(→FPGA), GND, Vcc(3.6~6 V 표기), BLT_En(FPGA→), 추가 핀 BLT_ATSel(FPGA→, FPGA Pin34).
- 전원 제어: BLT_PWR_n을 PCA9673 확장기(P02)가 구동. LOW면 전원 켜짐, 기본은 꺼짐. 이것이 AT 모드 진입 수단이라고 페이지가 적음.
- 제조사마다 핀 배치가 다르니 주의하라는 경고가 있다.

## 검증·재현성
- unverified: 코드·시험·자원 정보 없음.

## 한계·위험
- 보드 고유 구성(I/O 확장기로 전원 순서 제어)이라 그대로 재현 불가. AT 명령은 제조사 문서(hc01.com)로 링크만 있고 이번에 열람하지 않음.

## 재사용 메모
- 내 판단: 모듈 전원과 EN/AT 선택을 FPGA가 제어하는 설계는 "설정 모드 진입을 하드웨어 신호로 고정"하는 좋은 사례다. Basys3 Pmod 한 개(TX, RX, STATE, EN)로 단순화할 수 있다.
- 개조: CPU 비종속 보드 자료. STATE·EN을 동결 맵 GPIO 비트에 대응시킬 수 있다. PCA9673 전원 제어는 옮기지 않는다.
