---
name: wangxuan95-fpga-sdcard-file
url: https://github.com/WangXuan95/FPGA-SDcard-File
source_type: repo
vendor: amd
board: [Nexys4]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [storage-sd, comm-spi]
stage: T1
license: GPL-3.0
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
rechecked_at: 2026-11-07
sources: [https://github.com/WangXuan95/FPGA-SDcard-File]
---

## 요약
SPI 모드로 SD 카드의 FAT16/FAT32 파일을 이름으로 읽어 바이트 스트림으로 내보내는 Verilog 모듈(README 제목은 SPI 판 리더). 데모는 루트 디렉터리의 텍스트 파일 하나를 읽는다.

## 구조
- 지원 카드: SDv1.1, SDv2, SDHCv2, 파일 시스템 FAT16·FAT32(README 표). 비연속 블록에 저장된 파일도 읽는다고 명시.
- 파일명은 대소문자 구분 없음. SPI 클럭은 `SPI_CLK_DIV`로 정하고 README는 일반적인 값으로 500 kHz를 언급(재열람: `SPI_CLK_DIV` 기본 50, `clk` 50 MHz 가정). 내 계산: Basys3 100 MHz 클럭에서 500 kHz는 분주값 100.
- 같은 작성자의 SD 버스 방식 형제 프로젝트가 있다고 README가 적음(별도 카드 대기, 큐 참조).

## 검증·재현성
- 데모 보드는 Nexys4(Artix-7)만 기재. 자원 사용량과 시뮬레이션 방법은 이 README에서 확인하지 못함: unverified: 사유 — 본문에 없음.

## 한계·위험
- 읽기 전용, FAT16/FAT32만. 쓰기 경로 언급 없음(README에 쓰기 설명이 없다는 의미이며 구현 부재를 단정하지 않음).
- 라이선스 GPL-3.0 → 코드 복사 금지.
- 최종 갱신일·커밋 수: unverified: 페이지에서 날짜 확인 불가.

## 재사용 메모
- 내 판단: 블록 읽기 위에 FAT를 얹는 계층 구조(SPI 초기화 → 섹터 읽기 → FAT 탐색 → 바이트 출력)의 참고 사례. Nexys4와 Basys3는 같은 Artix-7 계열이라 핀·클럭 포팅만으로 가능할 가능성이 있으나 확인하지 않았다.
- 내 판단: Basys3 Pmod SD 연결은 디지런트 Pmod MicroSD 매뉴얼(1번 핀 CS, 2번 MOSI, 3번 MISO, 4번 SCK)에 맞추면 된다.
- 내 판단: 라이선스가 GPL-3.0이므로 코드는 가져오지 않고 계층 구조만 참고한다(HARNESS §6.3). 포팅이 필요하면 사용자 승인과 라이선스 검토를 먼저 받는다.
