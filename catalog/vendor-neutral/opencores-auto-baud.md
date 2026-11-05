---
name: opencores-auto-baud
url: https://opencores.org/projects/auto_baud
source_type: repo
vendor: neutral
board: [XC2V200]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog, VHDL
tools: [ISE]
bus: none
peripherals: [comm-uart]
stage: T1
license: BSD
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://opencores.org/projects/auto_baud]
---

## 요약
CR(캐리지 리턴, 0x0D) 문자를 기준으로 보레이트를 자동 감지하는 FSM 모듈. 단순 1회 측정(auto_baud.v)과 연속 추적(auto_baud_with_tracking.v) 두 가지 변형이 Verilog·VHDL로 각각 제공된다.

## 구조
- 파일: `auto_baud.v`(1회 측정), `auto_baud_with_tracking.v`(연속 추적), 같은 내용의 VHDL 버전도 있음.
- 동작: CR(0x0D = 1_0000_11b)의 비트 패턴 중 가운데 5개 "0" 구간 길이를 클럭으로 카운트해 보레이트 계수를 산출. 클럭 범위 30~100 MHz, 감지 보레이트 300~115200 bps 지원(README 기준).
- 출력: `baud_rate_o` — 측정된 보레이트 계수. 주변 UART 수신기에 연결하면 자동 조정 가능.
- `auto_baud_with_tracking.v`: CR이 들어올 때마다 보레이트를 갱신하는 적응 추적 방식. 내 판단: 연결이 안정되기 전에 CR이 여러 번 오는 경우에 적합.
- 타깃 보드: XC2V200 (Xilinx Virtex-2). Basys3(XC7A35T)에 직접 프로젝트는 없음.

## 검증·재현성
- 테스트벤치: unverified — 프로젝트 페이지에서 테스트벤치 존재를 확인하지 못함.
- 시뮬레이션 결과: unverified — 스크린샷·로그가 있는지 열람하지 못함.
- 보레이트 허용 오차(통신에 필요한 ±3~5%): unverified.
- CI: unverified — OpenCores 프로젝트이므로 CI 없을 가능성 높음.

## 한계·위험
- 타깃이 XC2V200(구형 ISE 도구)이므로 Vivado용 프로젝트가 없음. UCF 제약이 XDC로 교체 필요.
- CR 기반 감지라 첫 CR이 들어오기 전까지 보레이트가 미결정 상태임. 일부 프로토콜(이진 데이터 먼저 전송)에는 적용 불가.
- 테스트벤치가 없어 단독 검증이 어려움. 연동 시뮬레이션으로 확인 필요.
- OpenCores 저장소는 Git이 아닌 SVN 기반이어서 커밋 히스토리 접근이 불편함.

## 재사용 메모
- 내 판단: MicroBlaze V SoC T1 단계에서 UART 초기화 없이 보레이트를 자동 설정하는 기능이 필요할 때 직접 적용 가능. 호스트 PC가 CR로 먼저 접속을 알리는 프로토콜과 조합하면 편리하다.
- 개조: AXI4-Lite 슬레이브 래퍼를 추가하면 MicroBlaze V가 보레이트 감지 결과를 레지스터로 읽을 수 있음. `baud_rate_o`→ AXI 읽기 전용 레지스터, `enable_i`·`reset_i` → 쓰기 레지스터로 연결. 소스는 BSD이지만 Verilog로 재작성해 자체 IP 표준을 따르는 것이 AXI4-Lite 통합에 더 쉬움. 옮길 수 없는 부분: ISE용 UCF 제약(Vivado xdc로 교체)·VHDL 코드(Verilog 재작성 필요).
