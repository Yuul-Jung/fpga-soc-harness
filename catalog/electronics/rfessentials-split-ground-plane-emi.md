---
name: rfessentials-split-ground-plane-emi
url: https://rfessentials.com/rf-knowledge-base/how-do-i-design-a-split-ground-plane-on-a-pcb-without-creating-emi-problems/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none
language: none
tools: []
bus: none
peripherals: [ground-plane, split-gnd, EMI, mixed-signal, pcb-layout]
stage: T1
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://rfessentials.com/rf-knowledge-base/how-do-i-design-a-split-ground-plane-on-a-pcb-without-creating-emi-problems/]
---

## 요약 (3줄)
PCB 분할 GND 플레인 설계 시 EMI 문제를 피하는 방법을 다룬 rfessentials.com 가이드. 현대 권장안은 단일(통합) GND 플레인이며, 분할이 불가피한 경우에만 스타 접지와 스티칭 커패시터 기법을 사용한다. 신호선이 분할 간극을 넘는 순간 EMI가 급증하는 원리를 반환 전류 경로 개념으로 설명.

## 구조

**단일 vs. 분할 GND 플레인**
- 현대 설계 권장: 단일 통합 GND 플레인 + 플로어 플랜으로 디지털·아날로그 영역 구분
- 분할 GND 플레인은 레거시 기법으로, 대전류 시스템 또는 절연 요구 시에만 적용
- 2005년 이전 데이터시트의 분할 GND 레이아웃은 2층 기판 관행이므로 현재 기준 재검토 필요

**EMI 실패의 가장 흔한 원인**
- 신호선이 분할 간극을 가로지르면 반환 전류가 우회 → 큰 복사 루프 형성 → EMI 급증
- 모든 레이어(내층 포함)의 신호선이 경계를 넘는지 확인 필수

**스타 접지(단일 연결점) 규칙**
- 두 GND 영역을 연결하는 지점은 1개. ADC/DAC 혼합신호 IC 위치가 이상적
- 연결 브리지 폭: 2~5 mm로 넓게 → 임피던스 감소
- 브리지에 10 nF + 100 pF 디커플링 커패시터: 고주파에서 저임피던스, DC 분리 선택 가능

**전원 경로 규칙**
- 한쪽 회로는 같은 쪽 레귤레이터에서만 전원 공급
- 경계를 넘어야 하면 페라이트 비드 또는 인덕터로 필터링

**다층 기판 적용**
- 분할이 불가피하면 GND 레이어 하나에만 적용, 나머지 GND 레이어는 연속 유지
- 연속 레이어가 연속적인 반환 경로를 확보해 EMI를 보조 억제

**스티칭 커패시터**
- 간극을 가로질러 100 pF~10 nF COG 커패시터를 10~20 mm 간격으로 배치
- 10 MHz 이상에서는 사실상 단락(반환 경로 확보), DC에서는 분리 유지

**ADC 클럭 배선**
- ADC 클럭은 디지털 GND 쪽에서 ADC까지 배선, 아날로그 GND 쪽으로는 연장 금지
- ADC IC 자체를 경유하는 경우를 제외하고 분할 경계를 넘는 클럭 배선 금지

## 검증·재현성
- rfessentials.com(RF/EMC 전문 지식 베이스). 본문 직접 열람
- 반환 전류 경로 개념은 Henry Ott의 EMC 교과서와 일치

## 한계·위험
- RF·아날로그 혼합 설계 관점 중심. 순수 디지털 FPGA 보드(Basys3)에는 단일 GND 플레인 원칙만 적용해도 충분
- 고속 DDR·MGT 계열 신호 종단 규칙은 미포함

## 재사용 메모
- Basys3 주변장치 보드 설계 시 디지털 GND(FPGA I/O)와 모터 전원 GND(H-브리지)를 분리하는 경우 직접 적용. 모터 드라이버 보드의 전원 GND와 신호 GND를 스타 접지로 연결하고, 연결 브리지 2~5 mm 폭 준수
- 개조: RTL 직접 연관 없음. 하드웨어 단계(PCB 설계)에서 AXI GPIO PWM 출력이 H-브리지를 구동하는 보드에 적용. 구체적으로: MicroBlaze V의 PWM IP → 로직 버퍼(3.3V) → H-브리지(12V+) 경계에서 GND 분리 + 스타 접지 + 광커플러/MOSFET 드라이버 디커플링 필요
