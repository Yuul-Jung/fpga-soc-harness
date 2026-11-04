---
name: billauer-mb-dma-250mbps
url: https://billauer.co.il/blog/?p=1898
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: MicroBlaze
language: C
tools: [Vivado, Linux kernel]
bus: AXI4
peripherals: [AXI-DMA, BRAM, DDR]
stage: T5
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://billauer.co.il/blog/?p=1898, https://billauer.co.il/blog/category/microblaze/]
---

## 요약

billauer.co.il 블로그의 MicroBlaze + Linux + AXI DMA를 이용해 초당 250 MB 데이터 캡처를 구현한 실전 경험 글. 검색 결과 제목 "Capture data at 250 MBytes/sec with Linux on Microblaze" 기준으로 작성 (본문 미열람, L2). S6 실패 사례 — 고속 DMA 구현 과정에서 겪은 버그와 한계가 담겼을 가능성 높음.

## 구조

- **스택**: MicroBlaze(임베디드 Linux) + AXI DMA IP + 고속 데이터 소스(ADC 추정)
- **목표 처리량**: 250 MB/s — AXI-Stream DMA 방식으로 달성 가능한 수준(DDR 기반 필수)
- unverified: 사용 보드(DDR 필요 → Nexys A7·Arty 계열 추정), 실제 DMA 구성(S/G 모드 여부), Linux 드라이버 코드 세부 (본문 미열람)
- unverified: 폴링 vs 인터럽트 중 어느 모드를 최종 채택했는지 미확인

## 검증·재현성

- billauer.co.il 블로그 — 임베디드 Linux + FPGA 분야의 실전 경험을 다루는 기술 블로그로 다수 참조됨
- 검색에서 "Capture data at 250 MBytes/sec with Linux on Microblaze" 제목의 복수 URL 버전 확인 (L2)
- unverified: 코드 예제 품질, 재현 가능성, 최종 성공 여부

## 한계·위험

- T5 수준(Linux + DMA) — Basys3는 DDR 없음·Linux 구동 불가이므로 직접 재현 불가 (fit_basys3: needs-port)
- 250 MB/s 목표는 DDR 메모리 대역폭 의존 — BRAM만 있는 Basys3에서는 대역폭이 ~400 MB/s(단일 포트)이지만 AXI Interconnect 경유 오버헤드로 실질 절반 이하 가능
- 오래된 블로그 글일 경우 XAXIDma 드라이버 API가 최신 Vitis와 다를 수 있음

## 재사용 메모

가져올 수 있는 부분: 고속 DMA 구현의 실패 패턴 — DMA 완료 인터럽트 타이밍, 버퍼 정렬(alignment) 문제, 캐시 일관성(cache coherency) 이슈 등 S6 교훈. Linux에서 AXI DMA 드라이버 초기화·전송 순서.

개조: MicroBlaze V 베어메탈 환경(Basys3)에서는 Linux 드라이버 대신 Vitis BSP의 `XAxiDma_SimpleTransfer()` 폴링 루프로 대체. DDR 대신 BRAM 2영역을 소스·목적으로 사용하면 T3 수준의 BRAM-to-BRAM 폴링 DMA 완성. 옮길 수 없는 부분: Linux DMA 엔진 API, 캐시 일관성 처리 (`dma_sync_single_for_device` 등) — 베어메탈에서는 불필요(캐시 없음). 250 MB/s 목표 — Basys3 BRAM 한계로 대폭 하향.

내 판단: S6 전략의 핵심 자료. 고속 DMA를 Linux+MicroBlaze로 구현하며 겪은 병목 경험은, 베어메탈 Basys3 환경에서 피해야 할 패턴을 역으로 가르쳐 준다. 본문 열람 후 L3 승격 권장.
