---
name: masterplayer-lcd-st7789-sv
url: https://github.com/MasterPlayer/lcd-st7789-sv
source_type: repo
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [unverified]
bus: AXI4-Stream
peripherals: [comm-spi, display-lcd, ST7789]
stage: T2
license: MIT
stats: {commits: 5}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/MasterPlayer/lcd-st7789-sv]
unverified: 커밋 SHA(source_rev, 페이지에서 확인 못 함), 보드(저장소 토픽에 artix 표시만 있음), 자원 사용량, 소스 파일 내부(포트·레지스터는 README만 읽음)
---

## 요약
240x240 ST7789 SPI LCD를 SystemVerilog로 구동하는 간단한 시연 저장소. 바이트 단위 명령 관리자와 직렬 전송 드라이버를 AXI-Stream으로 이어 단색 채우기만 한다.

## 구조
- 모듈 둘: st7789_driver(SPI 직렬 전송), st7789_mgr(바이트 명령 처리, 초기화 전송). 둘 다 AXI-Stream 인터페이스 (README).
- 초기화 흐름: 소프트웨어 리셋 → 대기 → 슬립 해제 → 표시 반전 켬 → 표시 켬 → 열·행 주소 명령.
- 칩 셀렉트를 상수 0으로 묶고 SPI 클럭만으로 제어. 사용자 기능은 지정 색으로 전체 채우기뿐이고 상태 머신이 채울 때마다 색을 바꾼다.
- README 기준 SCL 75 MHz까지 안정, 그 이상은 데이터 손상. 버전 1.0, 커밋 5건.

## 검증·재현성
- 테스트벤치·자원 수치·빌드 스크립트 언급 없음(파일 목록은 src, LICENSE, README 등).

## 한계·위험
- 보드와 Vivado 프로젝트가 없어 Basys3 재현은 제약 파일 작성부터 필요. 프레임 버퍼·글꼴 없음. 240x240x16비트 전체 버퍼는 Basys3 BRAM에 맞지 않을 것으로 보이며(내 계산, 240×240×16 = 921,600비트, Basys3 BRAM 용량은 공식 매뉴얼로 확인 필요) 스트리밍 방식이 전제가 된다.
- 라이선스는 MIT(README/LICENSE 파일명으로 확인). 그래도 코드 반입은 사용자 승인 전에는 하지 않는다(G4).

## 재사용 메모
- 내 판단: 디스플레이 사다리의 색상 SPI 단계. 명령/데이터 구분을 AXI-Stream의 사이드밴드로 둔 구조가 FSM과 전송기를 분리해 시험하기 쉽다.
- 개조: AXI-Stream 경계를 IP 표준 레지스터(명령 바이트 FIFO 창, 상태)로 바꾸고, 라인 버퍼 스트리밍으로 제어 루프 값을 그리는 계기판에 연결. ST7735/ILI9341은 초기화 목록만 다르다고 보지만(내 추정) 확인하지 못했다.
