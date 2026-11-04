---
name: mg04-fpga-button-long-short-press
url: https://mg-04.github.io/posts/2025/02/lab1
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: []
bus: none
peripherals: [hid-ps2]
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: 2025-02}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://mg-04.github.io/posts/2025/02/lab1]
---

## 요약

FPGA 버튼 디바운스 + 짧은 누름(short) / 긴 누름(long) 구분 FSM을 설명한 블로그 포스트. 50MHz 클럭 기준이며 보드 종류는 불명확(Basys3 아님). SystemVerilog 사용. 0.5초 임계값으로 short/long을 가르고, long 판정 후 6Hz 반복 출력을 구현한다.

## 구조

- 디바운스 카운터: 24비트 `deb_counter`, 임계값 `0x7fff`(약 0.6ms @ 50MHz)로 입력 안정화.
- 버튼 FSM 4상태: `off` → (눌림) → `short` → 0.5s 초과 → `long` → (뗌) → `off`. `unused` 상태 존재(dead state 처리용).
- 긴 누름 반복: `long` 상태에서 6Hz(약 8,333,333 클럭 @ 50MHz) 타이머로 반복 펄스 생성.
- 단일 버튼(`KEY == 4'b1110`) 처리; 멀티 버튼 미지원.
- 25비트 `PRESS_THRESHOLD = 25_000_000`(0.5s @ 50MHz).

## 검증·재현성

- 블로그 포스트이며 보드 동작 사진·보드명 없음. 소스 파일 첨부 여부 미확인. unverified: 시뮬레이션/CI 결과 없음.
- 타이밍 수치와 FSM 상태 전이도는 포스트 본문에서 직접 열람(L3 등급 근거).

## 한계·위험

- 50MHz 기준 수치 — Basys3 100MHz 이식 시 모든 타이머 임계값 2배 조정 필요.
- SystemVerilog 문법 → Verilog-2001로 재작성 필요(iverilog 호환).
- 보드명, 라이선스, 소스 저장소 불명확.
- unverified: Basys3 XDC, 버튼 극성(active-high vs active-low) 명시 없음.

## 재사용 메모

- off→short→long 3단계 FSM 구조는 Basys3 디바운스 IP 설계의 기준이 된다. 타이머 비트폭과 임계값만 100MHz로 조정하면 직접 적용 가능.
- 6Hz 반복 펄스는 AXI4-Lite 슬레이브의 인터럽트 소스 또는 메뉴 스크롤 트리거로 활용 가능.
- 개조: SystemVerilog → Verilog-2001로 재작성 후 MicroBlaze V AXI4-Lite 래퍼에 삽입. CPU 독립 FSM이므로 버스 종속성 없음. `개조:` 임계값 및 FSM 상태 레지스터를 AXI 슬레이브 CSR로 노출하면 소프트웨어 가변 임계값 지원 가능.
