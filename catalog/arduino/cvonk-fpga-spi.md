---
name: cvonk-fpga-spi
url: https://github.com/cvonk/FPGA_SPI
source_type: repo
vendor: neutral
board: [Altera 보드 (기종 unverified), Xilinx 이식 가능은 README 주장]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog/SystemVerilog (토픽 표기 기준), Arduino 쪽 언어 unverified
tools: [unverified: 툴 버전 미기재]
bus: SPI (FPGA 슬레이브)
peripherals: [comm-spi]
stage: T2
license: GPL-3.0 (페이지 표기 → 사실만 추출, 코드 반입 금지)
stats: {commits: 26, last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/cvonk/FPGA_SPI, https://github.com/nachiket72/fpga-arduino_spi]
---
unverified: source_rev — 페이지에 최신 커밋 SHA가 표시되지 않음(meta-release 값은 사이트 빌드 ID로 판단해 쓰지 않음)

## 요약
마이크로컨트롤러(Arduino가 대상)가 SPI로 FPGA 안의 레지스터를 읽고 쓰게 하는 Verilog 구현이다. FPGA가 SPI 슬레이브, Arduino가 마스터다. 프로토콜 세부와 로직 분석기 파형은 저장소 밖 글(Math Talk)에 있다고 README가 안내한다(그 글은 열람하지 못함).

## 구조
- 폴더: `spi_byte_if/`, `spi_msg_if/`, `schematic/`, `logic_traces/` (README 목록, 이름만 확인하고 내용은 열람 못 함).
- 포크 `nachiket72/fpga-arduino_spi`(커밋 15건, GPL-3.0)는 같은 원본의 포크이며 Arduino가 피연산자를 만들고 FPGA가 연산 결과를 돌려주는 예로 설명된다(포크 README 서술). 원본 26건과 달라 변경 범위는 unverified.
- SPI 모드, 핀 배선, 5V↔3.3V 레벨 변환: README 본문에 없음 → unverified (`schematic/` 폴더에 있을 가능성만 있음).

## 검증·재현성
- 테스트벤치 언급 없음. 빌드 방법·자원 수치 없음. 모두 unverified.

## 한계·위험
- 라이선스가 GPL-3.0이라 코드·주석을 저장소에 옮기지 않는다.
- Basys3용 xdc 없음(Altera 지향). 마이크로컨트롤러 5V 신호가 FPGA 입력에 직접 닿는지 문서에서 확인되지 않았으니 배선을 따라 하지 말 것.

## 재사용 메모
- 내 판단: "마스터가 레지스터 주소를 SPI로 보내 읽고 쓰는" 구조는 AXI4-Lite 레지스터 파일과 개념이 같아, SPI 슬레이브 → 레지스터 파일 → 주변장치 IP 계층 분리의 참고가 된다.
- 개조: 옮길 부분은 바이트 계층(`spi_byte_if`)과 메시지 계층(`spi_msg_if`)의 2단 분리 아이디어. 새 RTL은 IP 표준 레지스터 래퍼 뒤에 SPI 슬레이브 프런트엔드를 붙이는 식으로 자체 작성. 못 옮길 부분은 Altera 전용 프로젝트 파일과 원본 코드 자체(GPL).
- 라이선스 확인 필요: 코드 반입 금지(GPL-3.0, §16.3 G0).
