---
name: mikrocontroller-net-nrf24l01-tutorial
url: https://www.mikrocontroller.net/articles/NRF24L01_Tutorial
source_type: article
vendor: neutral
board: [ATmega8 (글 서술). Arduino 호환 사용은 본문 언급 수준]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C (AVR)
tools: [AVR 툴체인 (글 서술)]
bus: SPI
peripherals: [comm-spi, sensor]
stage: T2
license: unknown (페이지에 라이선스 표기 없음 → 코드 반입 금지)
stats: {last_update: "unverified: 페이지에 최종 수정일 없음"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.mikrocontroller.net/articles/NRF24L01_Tutorial]
---
변경: 2026-11-03 source_rev 필드 제거(형식 오류). 사유 보존 — unverified: 위키 문서라 oldid=92199가 보이나 커밋 해시 아님

## 요약
nRF24L01+ 2.4 GHz 트랜시버를 SPI로 제어해 송신기·수신기를 만드는 독일어 위키 튜토리얼(열람은 영어 요약 기준). 명령 바이트, 레지스터, TX/RX 순서, CE·IRQ 사용법을 한곳에 정리한 점이 가치다.

## 구조
- 신호: VCC, GND, CE, CSN(액티브 로우), SCK, MOSI, MISO, IRQ(액티브 로우, 수신 완료·송신 완료·재전송 한도 초과 세 사건, 마스크 가능). 전원 1.9–3.6 V, 5 V 인가 시 파손 경고(글 서술).
- SPI: 마스터, MSB 먼저, 모드 0. 모든 명령 바이트에 STATUS가 응답으로 돌아오고, 읽기는 더미 바이트를 보내 밀어낸다. 최대 SPI 클럭: unverified: 글에 수치 없음.
- 명령: R_REGISTER, W_REGISTER, W_TX_PAYLOAD, R_RX_PAYLOAD, FLUSH_TX, FLUSH_RX, NOP(STATUS 읽기).
- 레지스터 설명 범위: CONFIG(인터럽트 마스크·CRC·PWR_UP·PRIM_RX), RF_CH, RF_SETUP, RX_PW_P0, 주소 레지스터, SETUP_RETR, STATUS. EN_AA, FIFO_STATUS는 글에서 다루지 않음(데이터시트 참조). 비트 주소(오프셋) 값은 unverified: 요약에 없음.
- 송신 순서: 핀·SPI 초기화 → 채널·속도·CRC·재시도·주소 설정 → TX 모드 전원 → FLUSH_TX → 페이로드 쓰기 → CE를 10 µs 이상 high → TX_DS/MAX_RT 플래그 정리.
- 수신 순서: 같은 채널·속도 → 페이로드 폭 설정 → RX 모드 전원, CE high → RX_DR 시 CE low, 페이로드 읽기, 플래그 정리, FIFO에 더 있는지 확인.

## 검증·재현성
- 테스트벤치·CI·자원 수치: unverified: 글에 없음. 예제 코드 저자는 글 서술 기준 Ernst Buchmann, SPI 루틴 출처는 Stefan Engelke·Brennan Ball(이름만 기록).

## 한계·위험
- 라이선스 표기 없음 → 코드를 가져오지 않는다. 라이선스 확인 필요.
- 글이 밝힌 함정: 폴링은 MCU를 막고 연속 도착 패킷을 놓칠 수 있음, 송신기가 여럿이면 재전송 지연을 서로 다르게, 250 kbps에서는 기본 250 µs 재전송 지연이 짧음, 0xAA·0x55 같은 비트 전이 부족 주소는 오검출 위험, 송수신 페이로드 크기 일치.
- 이 글의 모드(Enhanced ShockBurst 세부 포함)는 요약으로만 확인. 공식 데이터시트는 열람하지 못함(unverified).

## 재사용 메모
- 내 판단: 명령 바이트 + 상태 바이트 응답 구조는 SPI 마스터 FSM 하나(바이트 송수신 + CS 제어)와 레지스터 시퀀스 소프트웨어로 나누기 좋다. CE 10 µs 펄스와 IRQ 3종 사건이 하드웨어 몫(펄스 생성, 인터럽트 라인)이다.
- 개조: SPI 바이트 엔진, CS·CE 출력, IRQ 입력을 AXI4-Lite 레지스터 IP(IP 표준 래퍼)로 만들고 레지스터 초기화 순서·재시도 정책은 MicroBlaze V 펌웨어로 옮긴다. 옮길 수 없는 부분은 AVR SPI·인터럽트 루틴(MCU 전용, 한 파일로 격리)이다. 코드는 라이선스 불명으로 구조만 참고하고 RTL은 새로 쓴다.
- 전기: 보드 I/O 3.3 V에 맞아 레벨 변환은 불필요, 단 모듈 전원은 3.3 V 전용이고 순간 전류용 커패시터가 필요하다는 글 서술(Arduino 전원 사용 시 10 µF 언급).
