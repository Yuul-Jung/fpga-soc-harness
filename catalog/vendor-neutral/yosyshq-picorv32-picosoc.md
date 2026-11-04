---
name: yosyshq-picorv32-picosoc
url: https://software.mcgoron.com/Hardware/picorv32/raw/commit/cfd4933272f4c7ce7141a52145a193c188524f82/picosoc/README.md
source_type: repo
vendor: lattice
board: [iCE40-HX8K Breakout (README 기준 시연 보드)]
fit_basys3: needs-port
cpu: PicoRV32
language: Verilog
tools: [Yosys 계열 오픈소스 흐름 (버전 미표기)]
bus: native(PicoRV32 메모리 인터페이스, iomem 확장)
peripherals: [comm-uart, SPI-flash-XIP, GPIO-32]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-02
source_rev: cfd4933272f4c7ce7141a52145a193c188524f82
sources: [https://software.mcgoron.com/Hardware/picorv32/raw/commit/cfd4933272f4c7ce7141a52145a193c188524f82/picosoc/README.md]
unverified: 원본 저장소(YosysHQ/picorv32) 직접 열람과 LICENSE 파일(미러 README만 봄), 자원 사용량(README에 수치 없음), 인터럽트 동작(README에 설명 없음), 코드 본문
---

## 요약
PicoRV32 코어를 중심으로 한 가장 작은 SoC 참조 구성. 내부 SRAM, 메모리맵된 SPI 플래시 실행(XIP), 간이 UART, 사용자 주변장치용 iomem 영역으로 이루어진다. 이 저장소의 PicoRV32 계열 카드가 공통으로 가리키는 기준 메모리맵이다.

## 구조
- 메모리맵(README 서술): 내부 SRAM 0x00000000–0x00FFFFFF(기본 256워드=1 kB), 외부 직렬 플래시 0x01000000–0x01FFFFFF(리셋 벡터 0x01100000), 플래시 컨트롤러 설정 0x02000000, UART 분주 0x02000004, UART 데이터 0x02000008, 사용자 주변장치 0x03000000–0xFFFFFFFF.
- 데모와 테스트벤치는 0x03000000 한 워드에 32비트 GPIO를 둔다.
- UART 데이터 레지스터는 수신 버퍼가 비면 전 비트 1(-1)을 읽는다. 분주 레지스터로 보레이트를 정한다.
- 플래시 설정 레지스터: bit31 MEMIO 사용(리셋값 1, 끄면 비트뱅 모드), bit6 DDR, bit5 QSPI, bit4 연속 읽기, bit3:0 QSPI 더미 사이클.
- 시뮬레이션: `make test`로 테스트벤치(플래시 모델과 firmware.hex 필요), 보드 업로드는 `make prog` (README 서술, 실행하지 않음).

## 검증·재현성
- 직접 빌드·실행하지 않았다(§7). README에 자원 사용량과 타이밍 수치가 없다. unverified.

## 한계·위험
- 시연 보드가 Lattice iCE40-HX8K이므로 Basys3에서는 플래시 모델·핀·클럭을 바꿔야 한다. Basys3용 수정 사례는 [[symbiflow-arch-defs-picosoc-basys3]]와 [[tmahlburg-picosoc-basys3]] 참고.
- 라이선스를 이 미러 페이지에서 확인하지 못했다. 코드는 가져오지 않는다(G0). 라이선스 확인 필요.
- 미러(software.mcgoron.com)를 열람했으므로 원본과 차이가 있을 수 있다.

## 재사용 메모
- 내 판단: 이 메모리맵은 "CPU 밖 주변장치를 0x03000000 이후 한 영역에 두는" 구조라서, 동결 맵의 주변장치 영역 분할과 1:1로 대응시켜 읽을 수 있다.
- 개조: 간이 UART(분주+데이터 2레지스터)와 32비트 GPIO 한 워드의 레지스터 배치를 사양으로만 참고해, IP 표준 AXI4-Lite 래퍼를 자체 RTL로 새로 쓴다. 플래시 XIP와 PicoRV32 전용 IRQ는 옮기지 못한다(MicroBlaze V는 AMD IP 코어, 인터럽트는 INTC 입력으로). 새 슬롯은 `free_slots` [16]부터 제안한다.
