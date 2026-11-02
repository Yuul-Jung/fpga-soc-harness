---
name: digilent-forum-basys3-ethernet-ipv4-udp
url: https://forum.digilent.com/topic/21614-ethernetipv4udp-basys3/
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Vivado 2019.1]
bus: none
peripherals: [comm-eth, 10BASE-T-bitbang, UDP-tx]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
status: 포럼 스레드는 보관·종료됨(글쓴이 답변 중단)
sources: [https://forum.digilent.com/topic/21614-ethernetipv4udp-basys3/]
unverified: 첨부 파일(UDP_Tx.vhd, xdc)은 열람하지 못함, 라이선스, 자원 수치, 게시일
---

## 요약
Basys3의 FPGA 핀 한 쌍을 케이블에 직결해 10BASE-T로 UDP 패킷을 송신했다는 포럼 글. 송신만 있고 수신은 없으며, 답변자가 규격 부적합과 핀 손상 위험을 지적했다.

## 구조
- fpga4fun의 10BASE-T Verilog 예제를 VHDL로 옮기고 IPv4 체크섬 계산을 바꿨다고 글쓴이가 설명(글 서술).
- 20 MHz 클럭(Clock Wizard)을 쓰고 H1/J1 차동쌍 핀을 출력으로 썼다.
- 글쓴이는 가정용 스위치 너머 PC의 수신 프로그램에서 올바른 데이터를 받았다고 보고. 송신 전용.

## 검증·재현성
- 테스트벤치·CI·자원 수치 없음. 첨부 파일은 보지 못해 재현성은 unverified.

## 한계·위험
- 답변자(zygot)가 트랜스포머와 필터 없는 직결은 이더넷 규격이 아니며 장비·핀 손상 위험이 있다고 지적(스레드 서술).
- ARP 미구현, 같은 패킷 반복 송신은 실제 UDP 동작을 보여 주지 못한다는 지적도 있다.
- 답변자는 Pmod 기반 컨트롤러(Pmod NIC100, ENC424J600)를 대안으로 권했다.

## 재사용 메모
- 내 판단: 하드웨어 직결 방식은 하네스 전기 규칙(§17.2)에 맞지 않아 캡스톤에 쓰지 않는다. 패킷 구성(헤더, 체크섬)을 단계 시험하는 자료로만 참고하고, 외부 부품은 MAC/PHY 모듈을 쓴다.
- 개조: UDP 헤더·체크섬 생성기를 CPU 비종속 모듈로 분리하고 AXI4-Lite 래퍼의 TX_LEN/TX_DATA/CTRL 레지스터로 옮긴다. 물리 계층(핀 직결)은 옮기지 않는다. 라이선스 확인 필요.
