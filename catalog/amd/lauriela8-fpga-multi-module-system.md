---
name: lauriela8-fpga-multi-module-system
url: https://github.com/lauriela8/FPGA_Multi_Module_System
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: unknown
cpu: none(FSM)
language: Verilog
tools: [Vivado, VSCode]
bus: none
peripherals: [sensor, comm-uart, 7seg, HC-SR04, DHT11]
stage: T2
license: unknown
stats: {stars: 0, commits: 14}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2026-11-02 /verify 재열람 시도 실패(WebFetch 권한 요청 미응답) — 이번 사이클 미대조, rechecked_at 미기록
sources: [https://github.com/lauriela8/FPGA_Multi_Module_System]
unverified: xdc 제공 여부(src 폴더 내용 미열람, 하위 경로 열람 불가), 클럭·보율·타이밍 수치, 자원 사용량, 테스트벤치 존재, 라이선스, README 원문 언어, 최신 커밋 SHA
---

## 요약
Basys3에서 시계·스톱워치, HC-SR04 초음파 거리, DHT11 온습도, UART 명령 수신을 한 시스템으로 묶은 Verilog 프로젝트(README 기준 2025-05-27~2025-06-17 작업). 센서값을 7세그먼트와 UART로 함께 내보낸다.

## 구조
- 스위치 sw[5], sw[6]으로 표시 모드(시계 / 거리 / 온습도)를 고른다.
- HC-SR04: 거리를 7세그와 UART 문자열(`Distance = xxxxcm` 형태)로 출력. FIFO와 FSM으로 송신한다.
- DHT11: 전용 FSM이 데이터 동기화와 유효성 검사를 하고, 온습도를 7세그와 UART 문자열(`Temp = XXC / Humi = XX%` 형태)로 출력.
- UART 수신: FIFO + FSM 파서가 명령 RESET, CLEAR, SR, DHT, UP, DOWN을 받는다.
- 폴더: `src/`, `README.md` (루트에서 확인한 것).

## 검증·재현성
- README는 각 모듈을 설계·검증했다고만 서술. 테스트벤치, CI, 자원, WNS: unverified (위 사유).

## 한계·위험
- 센서 신호의 전압 레벨(HC-SR04 echo 5V 등) 서술은 열람한 README 범위에 없음. unverified.
- 라이선스 없음 표기 → unknown. 코드 반입 금지, 사양만 참고.

## 재사용 메모
- 내 판단: "센서 둘 + 표시 모드 선택 + UART 명령 질의"는 센서 허브의 가장 작은 완결 형태이며, 우리 SoC에서는 센서별 AXI4-Lite 상태·데이터 레지스터와 `sw`/UART 대신 CPU가 읽는 구조로 바꿀 수 있다.
- 개조: DHT11 FSM·HC-SR04 측정 FSM·UART 명령 파서의 동작을 사양으로 뽑아 IP 표준 래퍼(레지스터: START, STATUS, DATA, 오류 플래그)의 자체 RTL로 새로 쓴다. 7세그 모드 선택은 CPU 소프트웨어로 옮긴다. 라이선스 확인 필요.
