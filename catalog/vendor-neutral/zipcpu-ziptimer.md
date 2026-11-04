---
name: zipcpu-ziptimer
url: https://github.com/ZipCPU/zipcpu/blob/master/rtl/peripherals/ziptimer.v
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(IP 코어, ZipCPU 버스 직결)
language: Verilog
tools: [sby (Symbiyosys formal), yosys]
bus: ZipCPU 버스 (Wishbone 유사, 단일 32비트 레지스터)
peripherals: [timer-countdown, timer-irq, timer-periodic, timer-oneshot]
stage: T1
license: GPLv3
stats: {stars: 1636, commits: 826, last_update: 2024-10}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://zipcpu.com/zipcpu/2018/04/17/ziptimer.html, https://github.com/ZipCPU/zipcpu/tree/master/rtl/peripherals]
---

## 요약 (3줄 이내)

ZipCPU 프로세서의 주변장치 타이머 IP. 단일 32비트 레지스터 하나로 카운트다운 타이머를 제어하며, 0에 도달하면 `o_int` 인터럽트를 발생한다. 원샷과 주기(자동 재로드) 모드를 파라미터·비트 설정으로 선택한다.

## 구조

- 단일 소스 파일: `rtl/peripherals/ziptimer.v`
- 파라미터:
  - `BW` (버스 폭, 기본 32): 비트 폭
  - `VW` (카운터 폭, `BW-1`=31): 실제 카운트 폭
  - `RELOADABLE` (1=주기 모드 가능, 0=원샷만): 주기 모드 활성화
- 주요 포트 (블로그 2018-04-17 기준):
  - `i_clk`, `i_reset`: 클럭·리셋
  - `i_ce`: 클럭 인에이블 (분주 가능)
  - `i_wb_cyc`, `i_wb_stb`, `i_wb_we`, `i_wb_data[BW-1:0]`: 버스 쓰기
  - `o_wb_ack`, `o_wb_data[BW-1:0]`: 버스 읽기
  - `o_int`: 인터럽트 출력
- 단일 레지스터 (오프셋 없음):
  - 쓰기: `{reload_flag, count[VW-1:0]}` → 카운터 로드 & 시작
  - 읽기: 현재 카운터 값 반환
  - 비트31=0 → 원샷 (0에 도달하면 멈춤), 비트31=1 → 주기 (자동 재로드, `RELOADABLE=1` 필요)
- 클럭 인에이블(`i_ce`)을 외부 분주기에 연결하면 프리스케일러 없이 긴 주기 구현 가능

## 검증·재현성

- Symbiyosys 공식 검증(sby) 적용 — 블로그에서 formal proof 언급 확인
- 별도 시뮬레이션 테스트벤치 없음 (formal 중심)
- ZipCPU 전체 SoC에서 수년간 프로덕션 사용 (1,636 stars, 826 commits)
- iverilog·verilator 린트 통과 여부: `unverified: 직접 확인 안 함`

## 한계·위험

- **GPLv3**: 소스 반입 시 하네스 전체가 GPLv3 영향을 받을 수 있음 — 반입 전 사용자 승인 및 라이선스 검토 필수
- **ZipCPU 전용 버스**: AXI4-Lite가 아닌 ZipCPU 내부 버스. MicroBlaze V 연결을 위해 버스 프로토콜 변환 래퍼 필요
- 비교(compare) 출력 없음 — 원샷·주기·인터럽트만 지원
- 캡처 입력 없음 — 외부 이벤트 타임스탬프 불가
- README에 Vivado 합성 자원 없음 — `unverified: 미합성`

## 재사용 메모

- GPLv3이므로 소스 직접 복사 금지 (자동 모드 §16.3 G4). 사양(레지스터 비트 정의, FSM 동작)만 뽑아 자체 RTL 작성에 참고한다.
- 가져올 수 있는 설계 패턴: 단일 레지스터 카운트다운 패턴, 재로드 비트를 활용한 원샷/주기 토글 방식, 클럭 인에이블 기반 프리스케일러 아이디어
- 주기 타이머 구현의 최소 복잡도 기준점으로 활용 (약 50~80줄 Verilog 예상)
- 개조: 버스 인터페이스를 AXI4-Lite(또는 IP 표준 직결 버스)로 교체하고, 레지스터를 오프셋 기반 복수 레지스터(CTRL, LOAD, STATUS)로 확장. 나머지 카운트다운 FSM과 인터럽트 로직(`o_int` 토글)은 직접 이식 가능. 캡처·비교가 필요하면 EF_TCC32 패턴 추가.
