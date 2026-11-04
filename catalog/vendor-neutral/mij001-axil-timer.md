---
name: mij001-axil-timer
url: https://github.com/mij001/axil-timer
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(IP 코어)
language: SystemVerilog
tools: [Icarus Verilog, Verilator, Python UVM]
bus: AXI4-Lite
peripherals: [timer-countdown, timer-periodic, timer-oneshot, timer-irq]
stage: T2
license: MIT
stats: {stars: 미확인, commits: 30, last_update: 2024-10}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/mij001/axil-timer, https://github.com/mij001/axil-timer/blob/main/rtl/axil_timer.sv, https://github.com/mij001/axil-timer/blob/main/rtl/timer_core.sv]
---

## 요약 (3줄 이내)

AXI4-Lite 직결 다운카운팅 타이머 IP (SystemVerilog). 주기·원샷 모드와 프리스케일러, IRQ 출력을 갖추고 SVA 단언 + UVM 1.2 제약 랜덤 테스트벤치를 제공한다. FPGA 합성 사례 없이 시뮬레이션 검증 중심이다.

## 구조

- 소스: `rtl/axil_timer.sv` (AXI4-Lite 래퍼), `rtl/timer_core.sv` (코어 FSM)
- AXI4-Lite 슬레이브: 단일 주변장치 주소 범위
- 레지스터 맵 (GitHub README 기준):

| 오프셋 | 이름 | 접근 | 설명 |
|--------|------|------|------|
| 0x00 | CTRL | RW | EN(0), PERIODIC(1), IRQ_EN(2) |
| 0x04 | LOAD | RW | 재로드 값 (카운터 초기값) |
| 0x08 | COUNT | RO | 현재 카운터 값 (읽기 전용) |
| 0x0C | STATUS | W1C | EXPIRED(0) 플래그 (W1C 소거) |
| 0x10 | PRESCALE | RW | 프리스케일 분주비 |

- PERIODIC 비트=1이면 카운터 만료 후 LOAD 값으로 자동 재로드
- EN 비트=0이면 카운터 정지, 1이면 시작
- IRQ 출력: EXPIRED=1 & IRQ_EN=1일 때 `irq` 핀 High
- 프리스케일러: PRESCALE 레지스터 값으로 클럭 분주, 긴 주기 지원

## 검증·재현성

- SVA(SystemVerilog Assertion): 카운트다운 불변식, 재로드 조건 단언
- UVM 1.2 테스트벤치: 제약 랜덤 (constrained-random) 테스트, Icarus + Verilator 모두 통과
- 뮤테이션 테스트 적용(README 언급): 테스트 커버리지 강도 확인
- Icarus Verilog 및 Verilator 린트 클린 확인 (열람 기준)
- FPGA 합성 사례 없음 — `unverified: Vivado 합성 미확인`
- 보드 테스트 없음 — S1 등급 (시뮬레이션 통과 추정, CI 미확인)

## 한계·위험

- **SystemVerilog**: iverilog에서 일부 구문 제한 가능. Verilator 권장. Verilog-2001 혼용 프로젝트에서는 추가 검토 필요
- 캡처 입력 없음 — 외부 이벤트 타임스탬프 기능 없음
- 비교(PWM 출력) 없음 — 단순 IRQ 발생 타이머로만 동작
- Basys3 xdc·제약 파일 없음 — 합성·배치배선 미검증
- 소규모 저장소 (commits 30, stars 미기록) — 커뮤니티 검증 부족

## 재사용 메모

- MIT 라이선스이므로 소스 복사 가능하나 자동 모드에서는 사용자 승인 없이 복사하지 않는다 (§16.3 G4)
- 가장 직접 재사용 가능한 카드: AXI4-Lite 버스 래퍼 패턴 (`axil_timer.sv`)이 IP 표준(`config/ip_standard.json`)의 AXI4-Lite 슬레이브 패턴과 가장 가깝다
- 레지스터 맵(CTRL/LOAD/COUNT/STATUS/PRESCALE)이 명확하고 MicroBlaze V에 직접 매핑하기 쉬움
- UVM 테스트벤치 구조가 캡스톤 검증 접근법으로 참고 가능
- 개조: SystemVerilog → Verilog-2001 변환 필요 (SVA 제거, 로직/always @→reg/always). AXI4-Lite 래퍼 그대로 쓰거나 IP 표준 래퍼로 대체. 캡처·비교가 필요하면 EF_TCC32 레지스터 패턴 참고해 별도 필드 추가. IRQ 연결은 MicroBlaze V의 인터럽트 컨트롤러 슬롯 1개에 직결 가능.
