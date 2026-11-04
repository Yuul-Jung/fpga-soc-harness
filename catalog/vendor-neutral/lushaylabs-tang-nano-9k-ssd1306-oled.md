---
name: lushaylabs-tang-nano-9k-ssd1306-oled
url: https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/examples/lushaylabs/3_oled_101/oled_101.html
source_type: article
vendor: neutral
board: [Tang Nano 9K]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [yosys, nextpnr-gowin, iverilog]
bus: none
peripherals: [comm-spi, display-oled, SSD1306]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://wiki.sipeed.com/hardware/zh/tang/Tang-Nano-9K/examples/lushaylabs/3_oled_101/oled_101.html]
unverified: 라이선스(페이지에 미기재), 원본 저장소의 커밋 SHA, 자원 사용량·타이밍
---

## 요약
Tang Nano 9K(Gowin GW1N-9C)로 128x64 단색 SSD1306 OLED를 4선 SPI로 구동하는 입문 글(2023-03-14 표시). 5상태 FSM이 초기화 명령을 보낸 뒤 1024바이트 프레임 버퍼를 흘려 보낸다.

## 구조
- 4선 SPI(CS, D/C, RES, SDIN, SCLK). 27 MHz 클럭, 비트당 클럭 2주기로 SPI 클럭을 만든다.
- 초기화 약 15개 명령(총 23바이트)을 하나의 넓은 레지스터에 담아 MSB부터 전송. D/C 낮음 = 명령. 설정 항목: 표시 끔, 대비, 정상 표시, 수평 주소 지정, 스캔 방향, 멀티플렉스 비, 클럭, 프리차지, VCOM, 차지 펌프, 표시 켬.
- FSM 5상태: 전원·리셋 대기 → 다음 초기화 바이트 로드 → 바이트 비트 전송 → 초기화 완료 판정 → 픽셀 바이트 로드(D/C 높음) 후 전송으로 복귀.
- 파일: screen.v(대기 파라미터 STARTUP_WAIT, 기본 10,000,000주기), screen_tb.v, 핀 제약 파일, Makefile(합성·배치·시험 타깃), PNG를 hex로 바꾸는 Node 스크립트.
- 프레임 버퍼는 1024바이트 배열(열당 8픽셀 세로 바이트)을 `$readmemh`로 채운다. 글꼴 ROM은 이 편에 없고 다른 편에서 다룬다고 되어 있다.

## 검증·재현성
- Makefile의 test 타깃이 iverilog 시뮬레이션을 돌린다. 하드웨어에서는 시험 패턴과 이미지를 표시한 사진으로 확인했다고 한다. 자체 점검형(PASS/FAIL) 여부는 확인하지 못했다.

## 한계·위험
- 라이선스 미기재 → 코드는 가져오지 않고 구조와 순서만 기록(G0). Gowin 도구 체인 기준이라 핀·제약은 Basys3용으로 다시 써야 한다.
- 초기화 값이 128x64 패널 기준이라 128x32 Pmod OLED에는 멀티플렉스 비 등을 맞춰야 한다(내 판단, SSD1306 일반 사양 기준 추정).

## 재사용 메모
- 내 판단: "초기화 시퀀스를 데이터(레지스터 한 덩어리)로 두고 FSM은 비트 전송만 한다"는 구조가 작고 테스트하기 쉽다. 시작 대기 파라미터로 시뮬레이션 시간을 줄이는 방식도 CI에 맞는다.
- 개조: 초기화 ROM을 별도 메모리로 분리하고 AXI4-Lite 레지스터(시작, 상태, 프레임 버퍼 쓰기 창)로 감싼다. 시험은 iverilog 자체 점검 tb로 SPI 출력 바이트열을 기대값과 `!==` 비교.
