---
name: industrialmonitordirect-igbt-shootthrough
url: https://industrialmonitordirect.com/blogs/knowledgebase/igbt-h-bridge-shoot-through-fixing-pwm-timing-driver-issues
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(전자회로·게이트 드라이버)
language: []
tools: []
bus: none
peripherals: [gate-driver, h-bridge, deadtime, igbt, shoot-through]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://industrialmonitordirect.com/blogs/knowledgebase/igbt-h-bridge-shoot-through-fixing-pwm-timing-driver-issues]
---

## 요약

IGBT H-브리지 슛스루 원인과 수정 방법 가이드. PWM 타이밍 오류, 게이트 드라이버 구성 실수, 부족한 데드타임에 의한 슛스루 메커니즘을 설명하고 최소 데드타임 계산식, 통합 하프브리지 드라이버 대안을 제시한다.

## 구조

- 슛스루 메커니즘: 같은 레그의 두 스위치가 스위칭 천이 중 동시에 도통 → 버스-GND 단락. 최악 200A+ 스파이크, 수 마이크로초 내 IGBT 파손
- 최소 데드타임 계산: `t_dt(min) = t_fall(max) + t_propagation(off) + 여유`; 20A IGBT 예시 → 약 340 ns → 실용 권장 500 ns–1 µs
- 소자별 최소 데드타임: 600V IGBT 500 ns–1 µs / SiC MOSFET 100–200 ns (최대 100 kHz PWM 가능)
- 통합 드라이버 (슛스루 보호 내장): IR2304, FAN7390, UCC27710(적응 데드타임 450 ns)
- 50% 듀티 제한: 보완 PWM에서 레그당 듀티 50% 초과 불가 — 초과하면 데드타임에 무관하게 슛스루

## 검증·재현성

- 본문 직접 열람(L3). 계산 예시, 고장 메커니즘, 드라이버 IC 목록 포함
- 하드웨어 시험 기록 없음(가이드 성격 블로그)
- 주의: 본문 IR2110 핀 테이블(HIN/LIN 배선)이 내부적으로 일관성 없음 — 내 판단: 데이터시트 직접 대조 필수

## 한계·위험

- FPGA 전용 고려사항 미포함 — FPGA → 게이트 드라이버 인터페이스(3.3V 로직 레벨, 전파 지연, Pmod 전류 한계)는 별도 검토 필요
- IR2110 핀 표 오류 가능성 (본문 자체 경고 수준) — 반드시 Infineon 공식 데이터시트 확인
- 외부 명령 지시문 없음 (안전)

## 재사용 메모

Basys3 Pmod(3.3V) → IRS2110/IR2304 HIN-LIN 연결 시 적용: Pmod 전류(최대 1mA per pin) 한계 → 버퍼(74HC244 등) 삽입 권장. 데드타임 RTL 구현: 100MHz 클럭 기준 500 ns = 50 클럭 틱 (카운터 6비트), 1 µs = 100 틱 (7비트 충분).
개조: FPGA에서 HIN·LIN 보완 쌍을 생성하는 RTL 모듈 + 데드타임 삽입 FSM을 MicroBlaze V SoC의 AXI4-Lite IP로 래핑. 슛스루 감시 assertion (`!(pwmA && pwmB)`)을 testbench에 추가해 CI에서 타이밍 오류 자동 검출. SiC MOSFET 대상 100–200 ns 데드타임은 Basys3 100MHz 클럭 기준 10–20 클럭 틱으로 충분히 구현 가능. 참고: [industrialmonitordirect-irs2110-half-bridge]
