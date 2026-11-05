---
name: amd-axi-timebase-wdt-pg083
url: https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/axi_timebase_wdt.html
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: MicroBlaze
language: Verilog
tools: [Vivado 2024.2]
bus: AXI4-Lite
peripherals: [WDT-basic, WDT-window, heartbeat-WDTOUT]
stage: T2
license: Xilinx IP License (Vivado IP catalog 포함)
stats: {stars: 0, commits: 0, last_update: 2024-01}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://www.amd.com/en/products/adaptive-socs-and-fpgas/intellectual-property/axi_timebase_wdt.html, https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841776/Axi+Watchdog, https://edf.docs.amd.com/en/latest/zephyr/periph/zephyr-axi-wdt-driver-support.html]
---

## 요약 (3줄 이내, 내 표현으로)

AMD(Xilinx) 공식 AXI4-Lite 워치독 타이머 IP(axi_timebase_wdt). 기본 WDT 모드와 윈도우 WDT 모드를 모두 지원하며, WDTOUT 신호로 하트비트 핀 출력이 가능하다. Artix-7(Basys3)을 포함한 Vivado IP 카탈로그에 기본 포함되어 있어 MicroBlaze SoC에 AXI4-Lite 슬레이브로 바로 연결할 수 있다.

## 구조

- **IP 이름**: `axi_timebase_wdt` (PG083 문서)
- **버스**: AXI4-Lite 슬레이브
- **레지스터** (Zephyr 드라이버 소스 기준, 검색 요약):
  - `TWCSR0_OFFSET` — 타임워치독 제어/상태 레지스터 0 (WDT 활성화, WEN 비트, WDTOUT 출력 모드)
  - `TWCSR1_OFFSET` — 타임워치독 제어/상태 레지스터 1 (윈도우 경계 설정)
  - `TLR_OFFSET` — 타임워치독 로드 레지스터 (카운트다운 초기값)
- **동작 모드**:
  - 기본(Basic) 모드: 타임아웃 1회 경과 시 WDTOUT 어서트 → 2회 경과 시 리셋
  - 윈도우(Window) 모드: 서비스 너무 이름(창 열리기 전) 또는 너무 늦음(창 닫힌 후) 모두 리셋 발생
- **WDTOUT**: 액티브-로우 출력; 하트비트 핀 또는 시스템 리셋 연결 가능
- **클럭**: AXI4-Lite 클럭 도메인 (Basys3 50 MHz 가능)
- unverified: PG083 PDF 직접 열람 불가(검색 요약 기준). 실제 레지스터 오프셋 주소는 직접 확인 요망

## 검증·재현성

- Vivado IP 카탈로그에서 직접 추가 가능 — 별도 RTL 작성 불필요
- Linux 커널 드라이버 `drivers/watchdog/of_xilinx_wdt.c` 존재 (기본 모드 지원)
- Zephyr RTOS `drivers/watchdog/wdt_xilinx_axi.c` 존재 (기본 + 윈도우 모드)
- unverified: Basys3 실제 합성 자원(LUT/FF)과 WNS — Vivado 프로젝트 없음(IP 단독 추가 형태)

## 한계·위험

- IP 라이선스: Vivado 번들 IP로, 소스코드 수정·재배포는 Xilinx IP 라이선스 조건에 따름
- PG083 전체 사양서는 AMD 계정 로그인 없이 접근 불가 (자동 모드 열람 차단)
- unverified: 윈도우 모드 타이밍 파라미터 범위(최소/최대 창 폭)
- 기본 WDT 모드의 WDTOUT는 `1회 경과 후` 어서트이므로 리셋 전에 하트비트로 감지할 수 있으나, 윈도우 모드에서는 창 위반 즉시 리셋 가능성 있음(드라이버 주석 기준)

## 재사용 메모

- MicroBlaze V SoC(AXI4-Lite, 동결 맵)에 직접 사용 가능. 동결 맵의 `free_slots` 중 64KB 1개 배정 후 `integration.compat = compatible` 선언.
- 개조: WDTOUT를 MicroBlaze 외부 리셋 핀 또는 GPIO 하트비트 출력에 연결하면 §17.3의 보드 동작 확인(S3) 경로가 간단해짐. 윈도우 WDT 모드는 MicroBlaze 펌웨어(C 드라이버)에서 창 경계값 조정 — CPU 종속 부분은 `cpu_irq_mbv.c` 한 파일로 격리 가능.
- 카탈로그 대비 차별점: `mij001-axil-timer`(순수 타이머)와 달리 WDT 전용 IP이므로 타임아웃·리셋 로직이 IP 내부에 완결됨. 7세그 카운트다운 시각화(I-110 등)의 근거 IP로 쓸 수 있음.
