---
name: digilent-pmod-oled-reference-manual
url: https://www.electrokit.com/upload/product/41010/41010136/PmodOLED_rm.pdf
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified
tools: [unverified]
bus: none
peripherals: [comm-spi, display-oled, SSD1306]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.electrokit.com/upload/product/41010/41010136/PmodOLED_rm.pdf, https://forum.digilent.com/topic/3855-pmodoled-vhdl-source/]
unverified: VDD·VBAT 전압값(매뉴얼 본문에 없음), SPI 모드(CPOL/CPHA), 초기화 명령 목록, 픽셀 메모리 바이트 배치, 매뉴얼 개정 번호(전자상거래 사이트 사본)
---

## 요약
Digilent Pmod OLED(128x32 단색, SSD1306 호환 컨트롤러)의 공식 레퍼런스 매뉴얼 사본. 쓰기 전용 SPI와 D/C·RES 선, 전원 스위치 두 줄(VDDC, VBATC)로 구성되고, 전원 투입·차단 순서가 핵심이다. Basys3용 예제가 없다는 포럼 답변을 함께 읽었다.

## 구조
- 패널은 0.9인치 WiseChip/Univision UG-23832HSWEG04, 컨트롤러는 Solomon Systech SSD1306 호환 명령 집합, 해상도 128x32 (매뉴얼 J1 설명).
- 12핀 커넥터 J1: 1 CS, 2 SDIN(MOSI), 3 미사용, 4 SCLK, 5·11 GND, 6·12 VCC, 7 D/C, 8 RES, 9 VBATC, 10 VDDC. VBATC·VDDC는 FET 스위치 제어선이며 풀업 때문에 구동하지 않으면 전원이 꺼진 상태.
- D/C 높음 = 표시 데이터, 낮음 = 명령. RES는 낮추어 리셋하고 낮은 구간은 최소 3 µs. 장치는 쓰기 전용이라 읽기 불가. 전송 중 CS 낮음 유지, 최대 클럭 10 MHz.
- 전원 투입 순서: VDD 인가 → Display Off → 표시 모드 초기화 → 화면 지우기 → VBAT 인가 → 100 ms 대기 → Display On. 차단 순서: Display Off → VBAT 끄기 → 100 ms 대기 → VDD 끄기.
- Digilent 포럼(2017-03-31 질문): Basys3용 VHDL 예제는 없고, Nexys 3 예제를 XDC로 옮기거나 MicroBlaze용 PmodOLED IP를 쓰라는 답변.

## 검증·재현성
- 매뉴얼은 하드웨어 설명서이며 RTL·테스트벤치를 포함하지 않는다. Basys3 직접 예제는 포럼 기준 없음.

## 한계·위험
- 매뉴얼 본문에서 VDD·VBAT 전압값을 확인하지 못했다(unverified). 커넥터 VCC가 3.3 V인지는 Digilent 공식 페이지에서 따로 확인해야 한다.
- 예제 포럼 글은 2017년 기준이며 링크된 튜토리얼이 바뀌었을 수 있다.

## 재사용 메모
- 내 판단: 디스플레이 출력 사다리의 SPI 단색 단계. 전원 순서(100 ms 대기 두 번)와 RES 3 µs를 FSM 파라미터로 둘 수 있다.
- 개조: 자체 SPI 송신 FSM + 초기화 ROM + 128x32 프레임 버퍼를 AXI4-Lite IP 표준 레지스터(제어, 상태, 버퍼 창)로 노출. 제어 루프 값(속도·오차)을 글자로 표시하는 응용. 새 IP는 `free_slots`에서 한 칸 제안.
