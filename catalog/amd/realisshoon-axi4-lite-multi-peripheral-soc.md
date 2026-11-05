---
name: realisshoon-axi4-lite-multi-peripheral-soc
url: https://github.com/realisshoon/axi4-lite-multi-peripheral-soc
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: MicroBlaze
language: SystemVerilog
tools: [Vivado 2020.2, Vitis]
bus: AXI4-Lite
peripherals: [GPIO, UART, timer, I2C, SPI, INTC]
stage: T3
license: unknown
stats: {stars: 0, commits: 1, last_update: unverified}
doc_language: ko
verification: L2
checked_at: 2026-11-06
source_rev:
sources: [https://github.com/realisshoon/axi4-lite-multi-peripheral-soc]
---

## 요약 (3줄 이내, 내 표현으로)

Basys3 + MicroBlaze 기반 AXI4-Lite 다중 주변장치 SoC 포트폴리오 프로젝트. GPIO×4·커스텀 UART·타이머·I2C LCD·SPI 등 사용자 정의 IP와 Xilinx AXI INTC를 함께 연결하고, SystemVerilog/UVM 환경으로 SPI와 I2C를 검증한 한국어 프로젝트.

## 구조
- **CPU:** Xilinx MicroBlaze, AXI Interconnect + Local BRAM
- **커스텀 주변장치:** GPIO×4, UART (커스텀), 타이머, I2C LCD, SPI
- **Xilinx IP:** AXI UARTLite (콘솔 디버그), **AXI Interrupt Controller**(`0x4120_0000`), Local BRAM
- **인터럽트 컨트롤러 주소:** `0x4120_0000` (AXI INTC, Xilinx PG099 기준)
- **소프트웨어:** Vitis C 애플리케이션. 인터럽트 핸들러 등록·MicroBlaze 연동
- **툴:** Vivado 2020.2, Vitis

## 검증·재현성
- SPI UVM 환경: AXI4-Lite 마스터 시퀀스 + 모니터 + 스코어보드 → 32 Pass / 0 Fail, 100% 기능 커버리지, 100% SPI 버스 커버리지
- I2C UVM 환경: 별도 작성, 결과 미공개
- Basys3 보드 실동작 여부 미확인 (L2: README 수준만 열람)
- 커밋 1건: 프로젝트 구성 완료 여부 불명

## 한계·위험
- 라이선스 미명시 — 코드 재사용 전 확인 필요
- Star 0, 커밋 1건: 유지보수 가능성 낮음
- RTL 소스 미열람 (L2). 실제 IP 품질·완성도 미확인
- Vivado 2020.2 기준. Vivado 2024.2(현재 권장)와의 호환성 미확인
- AXI INTC 주소 `0x4120_0000`이 `config/soc_address_map.json` 동결 맵과 충돌할 수 있음 — 직접 통합 전 맵 확인 필요

## 재사용 메모
- AXI INTC(`0x4120_0000`)를 Vivado 블록 다이어그램에 연결하고 Vitis에서 XIntc API로 사용하는 최소 완성 예시로 참고 가능. MicroBlaze V에서도 같은 흐름
- UVM SPI 검증 환경(AXI4-Lite 마스터 시퀀스 패턴)은 우리 커스텀 AXI4-Lite INTC IP 검증 환경 설계 시 구조 참고 가능
- 개조: AXI INTC 주소(`0x4120_0000`)가 동결 맵에 없으면 `free_slots` 배정 필요. MicroBlaze → MicroBlaze V 전환 시 XIntc 드라이버 재컴파일과 xparameters.h 재생성 필요. 커스텀 주변장치 RTL은 L2로만 봐서 개조 가능성 판단 보류
