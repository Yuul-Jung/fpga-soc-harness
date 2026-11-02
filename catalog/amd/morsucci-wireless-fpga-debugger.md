---
name: morsucci-wireless-fpga-debugger
url: https://www.hackster.io/morsucci/wireless-fpga-debugger-and-system-monitor-56b7e5
source_type: article
vendor: amd
board: [unspecified]
fit_basys3: needs-port
cpu: MicroBlaze
language: C
tools: [Vivado 2017.4]
bus: AXI4-Lite
peripherals: [comm-uart]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://www.hackster.io/morsucci/wireless-fpga-debugger-and-system-monitor-56b7e5]
---

## 요약
MicroBlaze가 Pmod ESP32에 UART로 AT 명령을 보내 Wi-Fi TCP로 파이썬 서버에 스위치·버튼·LED 상태를 전송하는 무선 모니터 예제.

## 구조
- Pmod ESP32를 커넥터 JA에 연결, AT 펌웨어가 미리 올라와 있어 별도 플래시 불필요(글).
- AXI UARTlite 2개: 115200 baud로 ESP32, 나머지는 USB 디버그 콘솔. 디지런트 PWM IP로 RGB LED 구동. ADC Wizard 포함하나 미사용. 서버 포트 5005 예시(글).
- 보드·FPGA 이름: unverified: 글에 명시 없음(스위치·버튼·LED·RGB LED 보유). 이 글은 Wi-Fi(ESP32) 사례이며 블루투스 자료가 아니다.

## 검증·재현성
- 빌드는 Vivado 2017.4 + SDK 워크스페이스. 저장소 URL은 글에 없음: unverified. 자원 사용·테스트벤치: 서술 없음.

## 한계·위험
- Wi-Fi 접속을 시리얼 터미널이나 코드로 먼저 해야 하고, 서버 주소·포트가 코드에 고정, 서버를 먼저 띄워야 함(글). 문제 시 Pmod 전원 재투입 권고.
- 라이선스 미표기. 코드 가져오지 않음.

## 재사용 메모
- 내 판단: "AT 명령 모듈 + UART IP" 구조는 HC-05/06 블루투스, ESP-01 같은 Arduino 생태계 모듈에도 같은 방식으로 쓰인다. 모듈마다 5 V/3.3 V 전원·논리 레벨 확인이 필요하다(config 전기 규칙).
- 개조: MicroBlaze V와 AXI UARTlite 구성은 동결 맵 UART 영역에 거의 그대로 대응(내 판단). AT 응답 파서는 CPU 비종속 C 드라이버로 분리 가능. 연결 상태 폴링 대신 UART 인터럽트로 바꾸는 것은 개선 여지.
