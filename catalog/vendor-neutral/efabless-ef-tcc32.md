---
name: efabless-ef-tcc32
url: https://github.com/efabless/EF_TCC32
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(IP 코어)
language: Verilog
tools: [cocotb, iverilog]
bus: AHB-Lite | APB | Wishbone (AXI4-Lite 없음, 래퍼 필요)
peripherals: [timer-compare, timer-capture, timer-pwm, timer-irq]
stage: T2
license: MIT
stats: {stars: 11, commits: 약30, last_update: 2024-10}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/efabless/EF_TCC32, https://github.com/efabless/EF_TCC32/blob/main/hdl/rtl/bus_wrappers/EF_TCC32_AHB.v, https://github.com/efabless/EF_TCC32/blob/main/verify/utb/EF_TCC32_coco_AHB.py, https://github.com/efabless/EF_TCC32/blob/main/EF_TCC32.yaml]
---

## 요약 (3줄 이내)

Efabless 오픈 PDK 생태계용 32비트 타이머·캡처·비교 IP. MIT 라이선스이며 AHB-Lite, APB, Wishbone 버스 래퍼를 모두 제공한다. 타임아웃·카운터 매치·캡처 이벤트 3종 인터럽트와 프리스케일러, 원샷·주기 모드, PWM 비교 출력을 지원한다.

## 구조

- 최상위: `EF_TCC32.v` (코어) + 버스 래퍼 3종 (`EF_TCC32_AHB.v`, `EF_TCC32_APB.v`, `EF_TCC32_WB.v`)
- 버스 없이 직접 연결 가능한 단일 클럭 동기 설계
- 주요 포트 (EF_TCC32.yaml 기준):
  - `ctr_in` (입력): 외부 캡처 트리거 신호
  - `pwm` (출력): PWM 비교 출력
- 주요 레지스터 (AHB 기준, 열람 확인):

| 오프셋 | 이름 | 접근 | 설명 |
|--------|------|------|------|
| 0x00 | TMR (Timer Value) | RO | 현재 카운터 값 |
| 0x04 | PR (Period) | RW | 타이머 주기 |
| 0x08 | CMPVAL (PWM Compare) | RW | PWM 비교값 |
| 0x0C | MATCHVAL (Counter Match) | RW | 카운터 매치 임계값 |
| 0xF00 | RIS (Raw Interrupt Status) | RO | 원시 인터럽트 |
| 0xF04 | MIS (Masked Interrupt Status) | RO | 마스크 후 인터럽트 |
| 0xF08 | IM (Interrupt Mask) | RW | 인터럽트 마스크 |
| 0xF0C | IC (Interrupt Clear) | W1C | 인터럽트 소거 |

- 인터럽트 비트: `to_flag`(타임아웃), `match_flag`(카운터 매치), `cp_flag`(캡처 이벤트)
- 프리스케일러: 별도 필드에서 클럭 분주 가능 (YAML 명세 확인)
- 모드: 원샷(one-shot) / 주기(periodic) 선택 가능

## 검증·재현성

- `verify/utb/` 디렉터리에 cocotb 기반 AHB 테스트벤치 존재 (`EF_TCC32_coco_AHB.py`)
- iverilog로 시뮬레이션 가능 (cocotb 실행 환경 필요)
- Efabless 플랫폼의 ASIC 타겟 IP이므로 FPGA 합성 사례는 README에 없음 — 내 판단: AXI4-Lite 래퍼 추가 후 Vivado 합성 가능성은 높으나 미확인

## 한계·위험

- **AXI4-Lite 래퍼 없음**: AHB/APB/Wishbone만 제공. MicroBlaze V 연결을 위해 AXI4-Lite ↔ AHB 브리지 또는 직접 AXI4-Lite 래퍼 작성 필요
- Basys3용 xdc·Vivado 프로젝트 없음 (ASIC 플로우 전용 개발)
- README에 Vivado 합성 자원(LUT/FF/BRAM) 수치 없음 — `unverified: 미합성 미기록`
- stars 11, 소규모 저장소이나 Efabless 공식 IP 라이브러리 소속으로 품질 관리 존재
- 버스 래퍼의 타이밍 제약(setup/hold) 미기록 — `unverified: 타이밍 미확인`

## 재사용 메모

- MIT 라이선스이므로 소스 복사 가능하나, 자동 모드에서는 사용자 승인 없이 복사하지 않는다 (§16.3 G4)
- 가져올 수 있는 부분: 코어 로직(`EF_TCC32.v`)의 프리스케일러, 캡처·비교 로직, 3-종 인터럽트 설계 패턴
- MicroBlaze V 연결 방안: ① 오픈소스 AHB-to-AXI4-Lite 브리지 삽입 ② 코어를 그대로 쓰고 AXI4-Lite 래퍼를 직접 작성 (IP 표준 `config/ip_standard.json` 준수)
- 메모리 맵 슬롯: `free_slots` 중 하나에 64KB 할당 제안 필요 (캡스톤에서 결정)
- 개조: 버스 인터페이스(AHB→AXI4-Lite)와 인터럽트 연결(`to_flag`→MicroBlaze V IRQ 슬롯 1개) 교체 필요. 나머지(카운터 FSM, 캡처 에지 검출, PWM 비교 로직)는 그대로 쓸 수 있다. CPU 비종속 구조라 개조 범위가 좁다.
