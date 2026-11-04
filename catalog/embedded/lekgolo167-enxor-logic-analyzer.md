---
name: lekgolo167-enxor-logic-analyzer
url: https://github.com/lekgolo167/enxor-logic-analyzer
source_type: repo
vendor: neutral
board: [Artix-7 xc7a35tcpg236-1]
fit_basys3: yes
cpu: none(순수 RTL)
language: Verilog
tools: [Vivado, Quartus, iCEcube2]
bus: UART (자체 프로토콜)
peripherals: [debug]
stage: T2
license: GPL-3.0
stats: {stars: 156, commits: 95, last_update: 2024-02-20}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://github.com/lekgolo167/enxor-logic-analyzer, https://github.com/lekgolo167/enxor-logic-analyzer/blob/main/README.md]
---

## 요약

순수 Verilog로 작성된 멀티벤더 FPGA 온칩 논리 분석기. Artix-7 **xc7a35tcpg236-1** (Basys3 칩과 동일 계열)을 1차 대상으로 명시하며, Spartan-7·Cyclone IV·iCE40도 지원한다. Python/Tkinter GUI로 파형을 표시하며, .xor JSON 파일로 세션을 저장한다. 별 156개로 비교적 활발한 프로젝트. GPL-3.0.

## 구조

- **최상위**: `LogicAnalyzerTop` — 아래 모듈을 묶는 최상위
- **트리거 컨트롤러**: 에지 트리거(rising/falling) + 프리트리거 비율 10%~90% 선택
- **샘플 레이트 카운터**: 클럭 분주로 측정 주파수 선택
- **타임스탬프 카운터**: 이벤트 간 시간 간격 측정
- **메모리 버퍼**: 블록 RAM(BRAM) 기반 샘플 저장 — 8채널 4096샘플 / 16채널 8192샘플
- **UART 통신**: CLKS_PER_BIT 파라미터로 baud rate 설정, PC↔FPGA 직렬 통신
- **GUI**: `gui.py` (Python Tkinter), 파형 표시·트리거 설정·세션 .xor JSON 저장
- **보드 파일**: Artix-7, Spartan-7, Cyclone IV, iCE40 각각 별도 xdc/qsf/pcf 제공

## 검증·재현성

README 및 소스 목록 직접 열람(L3). Artix-7 xc7a35tcpg236-1 대상 테스트 명시. 별도 CI 없음. BRAM 2개(8채널)~4개(16채널) 사용 추정(내 계산: 4096×8b = 32Kbit, Basys3 BRAM 36Kb 1개로 충분). Python GUI는 별도 PC에서 실행하며 pyserial 의존.

## 한계·위험

- GPL-3.0: 코드를 직접 복사하면 프로젝트 전체 GPL 적용 가능성. 구조 참고만 허용.
- 채널 수 최대 16채널, 샘플 깊이 8192 — ILA(최대 131072) 대비 제한적.
- SUMP 미호환: 자체 UART 프로토콜 사용, PulseView·OLS와 직결 불가. 전용 Python GUI 필요.
- xc7a35tcpg236-1은 Artix-7 패키지 — Basys3의 xc7a35tcpg236은 동일 다이지만 패키지 footprint 차이가 있을 수 있어 xdc 핀 매핑 확인 필요(내 판단: 동일 패키지이므로 Basys3에서 동작 가능성 높음, unverified).
- 최신 갱신 2024-02-20 — 현재 Vivado 2024.2 호환 여부 미확인.

## 재사용 메모

- **Basys3 직결 가능성 높음**: xc7a35tcpg236-1 명시 + Artix-7 xdc 제공. Basys3의 UART 포트에 연결하면 PC GUI에서 바로 파형 확인 가능(내 판단, `fit_basys3: yes`).
- 순수 Verilog로 iverilog/verilator/yosys 모두 처리 가능. 하네스 CI 환경과 호환.
- **개조**: MicroBlaze V SoC 디버그 IP로 쓰려면 ① GPL이므로 RTL 복사 대신 사양 참조해 자체 작성 ② BRAM 1~2개 범위에서 채널·깊이를 프로젝트 `free_slots` 맞게 조정 ③ AXI4-Lite 슬레이브 래퍼로 MicroBlaze가 `[arm]`→`[wait trigger]`→`[read burst]` 흐름 제어 ④ Python GUI 대신 Vitis의 stdio로 텍스트 덤프하거나, UART 채널을 별도 AXI-UART에 연결해 PuTTY로 raw 바이너리 수신. 트리거·샘플·UART 모듈 경계가 명확해 개별 모듈 사양 추출 용이(내 판단).
