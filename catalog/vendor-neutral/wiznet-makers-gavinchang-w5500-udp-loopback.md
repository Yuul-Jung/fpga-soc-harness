---
name: wiznet-makers-gavinchang-w5500-udp-loopback
url: https://maker.wiznet.io/gavinchang/projects/fpga%2Dcontrols%2Dw5500%2Dto%2Dcomplete%2Dudp%2Dloopback%2Dtest/
source_type: article
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: []
bus: SPI
peripherals: [comm-eth, W5500, UDP-loopback, BRAM-buffer]
stage: T2
license: CC-BY-SA-4.0 (글 기준, 코드 라이선스는 unknown)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://maker.wiznet.io/gavinchang/projects/fpga%2Dcontrols%2Dw5500%2Dto%2Dcomplete%2Dudp%2Dloopback%2Dtest/?page=4, https://maker.wiznet.io/Arnold/projects/how-to-build-fpga-ethernet-with-wiznet-w5500-on-verilog/]
unverified: FPGA·보드, SPI 모드와 클럭, 자원 수치, 전체 코드(저자 CSDN 댓글에 있다고 하나 열람하지 않음)
---

## 요약
FPGA에서 WIZnet W5500을 SPI로 제어해 UDP 에코(받은 데이터를 RAM에 저장 후 되돌려 송신)를 완성한 글. 코드는 일부 조각만 실려 있다.

## 구조
- W5500 SPI 프레임: 2바이트 주소, 1바이트 제어(블록 선택, 읽기/쓰기, 길이 모드), 데이터(글 서술).
- 흐름: 공통 레지스터 초기화(게이트웨이, 서브넷, MAC, IP, 재시도, PHY) → 소켓 0을 UDP로 열고 상태 0x22 확인 → 수신 크기 레지스터 폴링 후 읽기 포인터로 읽고 RECV → 송신 여유 확인, 쓰기, SEND.
- 상태 이름 예: WR_MR, WR_GAR, WR_SHAR, WR_IP, WR_PORT, WR_CR, RD_RXBUF, 에코 FSM(IDLE, RDDAT_PRE, RD_DAT, END), RAM 버퍼 1개.
- 보조 출처(Arnold 글): 같은 계열 설명이나 FPGA·코드가 확인되지 않는 계획 서술. 열람 범위는 글뿐이며 외부 저장소(GitCode, MIT 표기)의 HDL은 보이지 않았다고 페이지에 적혀 있었다.

## 검증·재현성
- 테스트: PC 네트워크 디버깅 도구와 Wireshark 캡처(결과 그림만 있음). 테스트벤치·자원 수치 없음.

## 한계·위험
- UDP만 완료. TCP 클라이언트는 W5500이 ARP를 보내지 않아 실패했다고 저자가 적음.
- 글은 CC BY-SA 4.0이며 재게시 시 원문 링크와 고지를 요구. 코드 반입은 하지 않는다.

## 재사용 메모
- 내 판단: W5500은 TCP/IP를 칩이 처리하므로 FPGA는 SPI 레지스터 접근만 하면 되어 Basys3 캡스톤에 맞다. 초기화 시퀀스는 레지스터 쓰기 목록(ROM)과 범용 SPI 전송 FSM으로 분리하는 편이 시험하기 쉽다.
- 개조: 초기화 목록을 AXI4-Lite 설정 레지스터(IP/MAC/PORT)로 노출하고, 송수신은 BRAM 창(TX/RX 길이+데이터)으로 옮긴다. 수신 완료는 인터럽트 1비트로 INTC 빈 입력에 배정 제안. W5500 칩 모델 대신 레지스터 응답 테스트벤치 모델로 시험. 3.3V 모듈이므로 레벨 변환 불필요(모듈별 확인 필요).
