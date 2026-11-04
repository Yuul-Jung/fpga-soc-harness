---
name: meiniki-logip
url: https://github.com/meiniKi/logIP
source_type: repo
vendor: neutral
board: [Basys3]
fit_basys3: yes
cpu: none(순수 RTL)
language: Verilog
tools: [Vivado, Icarus Verilog]
bus: UART (SUMP 프로토콜)
peripherals: [debug]
stage: T2
license: GPL-3.0
stats: {stars: 7, commits: 171, last_update: 2023-05-14}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://github.com/meiniKi/logIP, https://github.com/meiniKi/logIP/tree/main/boards/basys3]
---

## 요약

FPGA 온칩 소프트 논리 분석기. SUMP 프로토콜을 구현해 Sigrok/PulseView·OLS(OpenLogicSniffer) 클라이언트에서 그대로 쓸 수 있다. Basys3 보드 전용 합성·프로그래밍 스크립트가 저장소에 포함되어 있어 `fit_basys3: yes`로 판정했다(내 판단). GPL-3.0.

## 구조

- **최상위**: `logIP` → `tuart_rx` + `tuart_tx` + RAM(LUT RAM 또는 Xilinx BRAM) + `core`
- **core 하위**: `ctrl`(제어 FSM), `indec`(명령 디코더), `ramif`(메모리 인터페이스), `sampler`(채널 샘플링), `trigger`(트리거 로직), `rdback`(데이터 읽기)
- **채널**: 최대 32채널(파라미터로 설정)
- **트리거**: 4단계 복합 트리거 지원
- **통신**: UART → PC, SUMP 프로토콜(baud rate 파라미터화)
- **메모리**: LUT RAM 또는 Xilinx BRAM 선택 가능
- **보드 지원**: `boards/basys3/` 폴더에 `synth.tcl`·`prog.tcl` 포함

## 검증·재현성

README와 `boards/basys3/` 폴더 직접 열람(L3). Basys3 대상 합성 스크립트가 별도 제공됨. CI/테스트벤치 존재 여부 미확인. Sigrok/PulseView에서 SUMP 장치로 연결해 쓰는 예시가 README에 기술됨.

## 한계·위험

- GPL-3.0: 코드를 가져와 프로젝트에 포함하면 프로젝트 전체가 GPL이 될 수 있음. 구조 참고 및 자체 RTL 재작성으로 우회 필요.
- 최신 갱신 2023-05-14, 별 7개 — 소규모 프로젝트로 장기 유지보수 불확실.
- 트리거 복잡도와 채널 수에 따라 BRAM/LUT 소모량이 달라짐 — Basys3(BRAM 50개)에서의 최대 구성 미확인.
- 샘플 메모리 깊이 미명시(README 기준); 실제 Basys3 자원 제약에 맞게 조정 필요.

## 재사용 메모

- **Basys3 직접 적용 가능**: `boards/basys3/` 합성 스크립트가 있어 xdc·클럭 교체 없이 사용 가능성 높음(L3 근거).
- SoC 디버그 IP로 활용: 논리 분석기를 Basys3 SoC의 내부 신호에 연결해 AXI 버스 트래픽·UART·SPI·I2C 파형을 PC에서 PulseView로 실시간 관찰 가능.
- **개조**: MicroBlaze V SoC에 넣으려면 ① GPL 대신 자체 SUMP 프로토콜 구현(레퍼런스로만 참조) ② AXI4-Lite 슬레이브 래퍼로 MicroBlaze가 `[트리거 설정]`→`[시작]`→`[읽기]` 명령 순서 제어 ③ 샘플 메모리는 `free_slots` 외부 BRAM 블록 또는 AXI BRAM Controller 연결 ④ SUMP UART 채널은 별도 UART IP로 분리해 Vitis에서 PulseView 연결. 코어 RTL(sampler·trigger·rdback)은 사양만 참조해 AXI 준수 버전으로 신규 작성해야 함(내 판단).
