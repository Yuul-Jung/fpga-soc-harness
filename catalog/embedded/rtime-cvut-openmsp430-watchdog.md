---
name: rtime-cvut-openmsp430-watchdog
url: https://rtime.felk.cvut.cz/gitweb/fpga/openmsp430.git/blob/38b1caba096d0cf371638f5ce61763dedc770351:/core/omsp_watchdog.v
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(MSP430 주변장치 IP, openMSP430 SoC에 종속)
language: Verilog
tools: [iverilog, verilator, ModelSim]
bus: native(MSP430 peripheral bus, 9비트 주소 per_addr)
peripherals: [watchdog-timer, nmi-handler]
stage: T1
license: LGPL-2.1
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev: 38b1caba096d0cf371638f5ce61763dedc770351
sources: [https://rtime.felk.cvut.cz/gitweb/fpga/openmsp430.git/blob/38b1caba096d0cf371638f5ce61763dedc770351:/core/omsp_watchdog.v, https://opencores.org/projects/openmsp430/core]
---

## 요약

openMSP430 SoC(16-bit MSP430 호환 소프트코어)의 워치독 타이머 주변장치 Verilog 소스 파일.
단일 레지스터(WDTCTL) 인터페이스, 패스워드 보호 쓰기, 4단계 타임아웃 선택, NMI 에지 감지 포함.
LGPL 2.1; FPGA 친화형(단일 클럭 도메인, 클럭 게이팅 없음).

## 구조

- **레지스터**: WDTCTL, 주소 `9'h120` (per_addr 7:0 = 8'h20, MSB는 선택 디코드)
- **쓰기 보호**: 상위 바이트 `per_din[15:8]`이 `0x5A`와 다르면 `wdtpw_error` 신호 발생 (실제 리셋/인터럽트 처리는 SoC 상위에서)
- **카운터**: 16비트 자유 구동 카운터 `wdtcnt`, 오버플로 발생 시 아닌 선택된 비트 탭이 1로 천이하는 순간에 타임아웃 감지
- **타임아웃 선택** (WDTIS[1:0] 비트 2:1 → 선택한 카운터 비트):
  - `00`: bit 15 ≈ 32768 사이클 @SMCLK (~1 s @32 kHz)
  - `01`: bit 13 ≈ 8192 사이클
  - `10`: bit 9  ≈ 512 사이클
  - `11`: bit 6  ≈ 64 사이클 (~2 ms @32 kHz)
- **클럭**: SMCLK 또는 ACLK 선택 (WDTSSEL 비트 2), `aclk_en` / `smclk_en` enable 신호 사용
- **정지**: WDTHOLD 비트 7 = 1 → 카운터 동결
- **클리어**: WDTCNTCL 비트 3 = 1 쓰기 → `wdtcnt` 리셋 (소프트웨어 "kick")
- **타임아웃 출력**: `wdtifg_set` (인터럽트 플래그 세트 신호). 리셋 출력은 이 파일에 없음; SoC 상위에서 처리
- **NMI 경로**: `nmi` 입력 → 3단계 동기화기 → 에지 감지 → `nmie` 활성 시 `nmi_pnd` 플래그 → `wdtnmies` 엣지 선택

**포트 목록** (열람 기준):
- 입력: `mclk`, `puc`, `aclk_en`, `smclk_en`, `dbg_freeze`, `nmi`, `nmie`, `wdtie`, `per_addr[7:0]`, `per_din[15:0]`, `per_en`, `per_wen[1:0]`
- 출력: `nmi_evt`, `per_dout[15:0]`, `wdtifg_set`, `wdtpw_error`, `wdttmsel`

## 검증·재현성

- 소스 파일 직접 열람 완료 (rev 38b1caba, 약 250줄 Verilog)
- openMSP430 전체는 iverilog/ModelSim으로 시뮬레이션 가능하다고 opencores 페이지에 명시
- 워치독 단독 TB는 이 카드에서 확인하지 못함; openMSP430 TB 세트에 포함된 것으로 추정 (unverified)
- LGPL 2.1: 포트 추출과 사양 기록은 가능; 코드 직접 복사는 사용자 승인 필요 (§16.3 G4)

## 한계·위험

- 타임아웃 시 리셋 출력이 없음 — `wdtifg_set`을 SoC 수준에서 받아 처리해야 함. IEC 61508 환경에서는 인터럽트 경유 리셋보다 하드와이어드 리셋 출력이 더 안전하다.
- 단순 카운터 비트-탭 방식(기본 워치독). 윈도우 워치독(WWDT), 챌린지-응답 워치독은 미구현.
- LGPL 2.1: 연결(linking)은 허용되나 수정 배포 시 소스 공개 의무.
- openMSP430 주변 버스는 MSP430 전용 비표준 인터페이스; AXI4-Lite로 직접 연결 불가.

## 재사용 메모

- 워치독 FSM 설계 참고로 적합: 패스워드 보호 레지스터 쓰기, 카운터 비트-탭 타임아웃, 클리어(kick) 메커니즘을 Basys3 AXI4-Lite 래퍼로 재구현 가능.
- `개조:` openMSP430 주변 버스 → AXI4-Lite: `S_AXI_*` 포트로 교체, 주소는 `free_slots`에서 64KB 하나 배정. `wdtpw_error` 패스워드 보호는 AXI 쓰기 데이터의 상위 16비트 패스워드 필드로 대응 가능. 타임아웃 비트-탭 → AXI 레지스터의 TIMEOUT_SEL 필드로 직접 이식. `wdtifg_set` → MicroBlaze V 인터럽트 컨트롤러(AXI INTC) 연결. 리셋 출력이 필요하면 별도 외부 리셋 로직 추가. 옮길 수 없는 것: `mclk`/`aclk_en`/`smclk_en` MSP430 클럭 인에이블 체계 (Basys3에서는 단일 클럭 도메인으로 단순화).
