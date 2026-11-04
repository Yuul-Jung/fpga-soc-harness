---
name: industrialmonitordirect-irs2110-half-bridge
url: https://industrialmonitordirect.com/blogs/knowledgebase/irs2110-half-bridge-gate-driver-design-deadtime-and
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(전자회로)
language: []
tools: []
bus: none
peripherals: [gate-driver, h-bridge, deadtime]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://industrialmonitordirect.com/blogs/knowledgebase/irs2110-half-bridge-gate-driver-design-deadtime-and]
---

## 요약
IRS2110 하프브리지 게이트 드라이버의 설계 가이드. 데드타임 외부 생성 필요성, 부트스트랩 커패시터 계산, 게이트 저항 선택, 600V급 MOSFET 후보를 다룬다.

## 구조
- IRS2110: 500V 오프셋, 2A 소스/싱크, 120 ns 전파 지연; UVLO 8V
- 내부 데드타임 없음 — 외부 로직(MCU/FPGA)이 반드시 200–500 ns 데드타임을 보장해야 함
- 부트스트랩 회로: 고측 드라이버 전원. 커패시터 용량 Cbst > (Qg + I_QBS × t_on) / dV_BS. 가이드 예시(37.5W 부하, t_on=4µs): 최소 ~33 nF → 권장 100–220 nF X7R 세라믹
- 부트스트랩 다이오드: fast-recovery, trr < 100 ns (예: UF4007)
- 100% 하이사이드 듀티 사이클 불가 (부트스트랩 방식 한계)
- 게이트 저항: 4.7–10 Ω 직렬; GS 사이 풀다운 10 kΩ 권장
- MOSFET 후보(600V급): IPA60R190C6, IPP60R099C6, STF13N60M2, FCPF11N60NT, SIHA21N60E

## 검증·재현성
- 가이드 본문 직접 열람(L3). 계산 예시와 회로 설명 포함
- 보드 시험 기록 없음; 가이드 성격의 블로그 글

## 한계·위험
- 가이드에서 37.5W 부하(37.5V × 1A)와 Cbst 계산 수치 간 일관성 불명확 — 내 판단: 수치 독립 검증 필요
- GND 바운스 주의: 하이사이드 복귀 전류와 로우사이드 소스 공유 시 오동작 가능
- 외부 명령어·설치 지시문 없음 (안전)

## 재사용 메모
IRS2110 게이트 드라이버 회로를 Basys3 FPGA 시스템에 연동할 때: FPGA Pmod 출력(3.3V) → 로직레벨 MOSFET 또는 별도 버퍼를 거쳐 HIN/LIN 입력으로.
개조: FPGA에서 HIN/LIN 쌍을 직접 생성하되, 데드타임 FSM을 RTL로 구현해야 함 (IRS2110은 데드타임 미제공). AXI4-Lite 슬레이브로 PWM 주기·데드타임 레지스터를 노출하고 동결 맵 free_slots에서 64KB 블록 배정. 내부 클럭 100MHz 기준 1 클럭=10 ns이므로 20클럭=200 ns 최소 데드타임 카운터 구현 가능. 100% 듀티 불가 조건은 소프트웨어 레지스터 클램프로 보완.
