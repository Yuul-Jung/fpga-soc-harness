---
name: symbiflow-arch-defs-picosoc-basys3
url: https://foss-fpga-tools.googlesource.com/symbiflow-arch-defs/+show/refs/heads/bot-conda-lock-update/tests/9-soc/picosoc/README.md
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: PicoRV32
language: Verilog
tools: [SymbiFlow/오픈소스 흐름 (버전 미표기)]
bus: native(PicoSoC iomem)
peripherals: [comm-uart, GPIO-LED, GPIO-switch, ROM-in-fabric]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-02
sources: [https://foss-fpga-tools.googlesource.com/symbiflow-arch-defs/+show/refs/heads/bot-conda-lock-update/tests/9-soc/picosoc/README.md, https://foss-fpga-tools.googlesource.com/symbiflow-arch-defs/+/refs/heads/install-gnupg/tests/9-soc/picosoc/basys3-full_demo_50.v]
unverified: 커밋 SHA(source_rev, 브랜치 이름 URL만 사용), LICENSE, 자원 사용량·WNS, picosoc_noflash 정의와 메모리 크기, 메모리맵(README에 없음)
---

## 요약
PicoSoC에서 외부 SPI 플래시 의존을 없애고 프로그램을 FPGA 내부 ROM(progmem)에 넣어 Basys3에서 돌리는 테스트. 시리얼 메뉴와 LED 점멸로 동작을 확인한다.

## 구조
- README 서술: 외부 플래시 불필요, ROM은 HEX에서 생성한 `progmem.v`(변환 스크립트 `hex2progmem.py`), UART 115200 baud, LD0–LD3이 좌→우로 점멸, 메뉴에 벤치마크 항목이 있다. 압축 명령(C 확장) 미지원이라 펌웨어 아키텍처 지정 필요.
- 최상위 `basys3_demo` 래퍼(wrapper 파일 열람): 포트는 clk, rx/tx, sw[15:0], led[15:0]. 100MHz 입력을 BUFGCE로 2분주해 50MHz를 만들고 SoC·GPIO·리셋에 쓴다.
- 리셋: 6비트 카운터가 가득 찰 때까지 63사이클 유지.
- GPIO: 주소 상위 바이트 0x03 영역 한 워드. 읽으면 상위 16비트에 스위치, 하위 16비트에 LED 레지스터가 보이고, 쓰기는 바이트 단위(wstrb)로 반영한다. IRQ 5–7은 0으로 묶음.

## 검증·재현성
- 직접 빌드하지 않았다. README는 시리얼 출력과 LED 패턴을 기대 결과로 서술한다. 자원·타이밍 수치 unverified.

## 한계·위험
- 브랜치 이름으로 열람했으므로 내용이 바뀔 수 있다(SHA 고정 못 함). 라이선스 불명: 코드 반입 금지, 라이선스 확인 필요.
- 메모리맵과 ROM 크기를 확인하지 못했다.

## 재사용 메모
- 내 판단: "100MHz→50MHz BUFGCE 분주 + 단순 리셋 카운터 + 스위치·LED 한 워드 GPIO"는 Basys3 SoC 래퍼의 최소 형태로, BRAM만 쓰는 부트(`no-dram`)의 기준 사례다.
- 개조: 스위치·LED 레지스터 배치(읽기 시 sw/led 합본)와 리셋 지연 구조를 사양으로만 참고해 IP 표준 AXI4-Lite GPIO 래퍼를 자체 RTL로 쓴다. 동결 맵에 이미 GPIO가 있으면 그 영역을 쓰고 새 슬롯은 만들지 않는다. IRQ 처리와 ROM 생성 스크립트는 MicroBlaze V(Vitis ELF→BRAM)와 방식이 달라 옮기지 못한다.
