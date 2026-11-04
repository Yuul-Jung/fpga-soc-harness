---
name: xilinx-xup-cdma-lab7
url: https://xilinx.github.io/xup_embedded_system_design_flow/lab7.html
source_type: course
vendor: amd
board: [ZedBoard]
fit_basys3: needs-port
cpu: MicroBlaze
language: C
tools: [Vivado, Vitis]
bus: AXI4
peripherals: [AXI-CDMA, BRAM]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://xilinx.github.io/xup_embedded_system_design_flow/lab7.html]
---

## 요약

AMD XUP(Xilinx University Program) 임베디드 시스템 설계 플로우 강좌의 Lab 7. AXI CDMA(Central DMA) IP를 이용한 메모리-to-메모리 DMA 전송 패턴을 다룬다. 검색 결과 제목 "Direct Memory Access using CDMA" 기준으로 작성 (본문 미열람, L2).

## 구조

- **AXI CDMA**: Xilinx 제공 IP. 소스·목적 주소와 전송 바이트 수를 소프트웨어(C)로 설정하면 버스트 복사가 하드웨어에서 완료됨
- unverified: 사용 보드(ZedBoard 추정, Zynq PS+PL 조합일 가능성 높음). DDR과 BRAM 중 어느 것이 소스·목적인지 미확인
- unverified: 인터럽트 사용 여부, 폴링 대기 방식 세부 미확인
- Vitis(또는 Xilinx SDK) 소프트웨어 드라이버(`xaxicdma_v2_01_a`) 연동 추정

## 검증·재현성

- AMD XUP 공식 GitHub Pages에 게시된 강좌 자료 (xilinx.github.io/xup_embedded_system_design_flow). URL 확인 L2.
- 검색 결과 여러 곳에서 "Lab7 CDMA" 참조로 등장 — 실제 강의에서 사용됨을 간접 확인
- unverified: 빌드 완성도, 자원 사용, WNS

## 한계·위험

- Zynq ZedBoard 기반 추정 — Basys3의 MicroBlaze V 환경에서는 ① Zynq PS 없음 → AXI Interconnect로 MicroBlaze 마스터 대체 ② DDR 없음 → BRAM-to-BRAM 전송으로 범위 축소 ③ 슬레이브 포트 구성 재설계 필요
- CDMA 버스트 길이·FIFO 깊이를 잘못 설정하면 전송 완료 플래그가 늦게 올라오는 타이밍 문제 발생 가능 (내 판단: S6 주의 항목)
- 라이선스: 미확인. AMD XUP 교육 자료로 비상업 사용 가정

## 재사용 메모

가져올 수 있는 부분: AXI CDMA 폴링 루프 패턴(소스 주소 → 목적 주소 → 길이 설정 → BUSY 비트 폴링 → 완료), C 소프트웨어 드라이버 인터페이스 구조.

개조: Basys3 MicroBlaze V 환경에서는 DDR 대신 BRAM 2개(소스·목적 각각 `0x4010_0000` 영역 free_slots 배정)를 AXI Interconnect로 연결하고 AXI CDMA를 그 사이에 삽입하면 BRAM-to-BRAM 폴링 DMA가 가능. CPU 간섭 없는 버스트 블록 복사 → 주변장치 더블 버퍼링에 활용. 옮길 수 없는 부분: Zynq PS의 DDR 성능(1 GB/s급) — Basys3에서는 BRAM 대역폭(단일 포트 약 400 MB/s@100MHz) 한계로 목표 속도 하향 조정 필요(내 판단).

내 판단: DMA 패턴을 MicroBlaze+Vivado IP 환경에서 실습하는 가장 직접적인 공식 자료. L2이므로 본문 열람 후 L3 승격 권장.
