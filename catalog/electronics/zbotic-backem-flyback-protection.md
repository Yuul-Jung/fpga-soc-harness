---
name: zbotic-backem-flyback-protection
url: https://zbotic.in/dc-motor-back-emf-protection-flyback-diode-circuit-guide/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(전자회로)
language: []
tools: []
bus: none
peripherals: [h-bridge, flyback-diode, back-emf, motor-protection]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://zbotic.in/dc-motor-back-emf-protection-flyback-diode-circuit-guide/]
---

## 요약
DC 모터 역기전력(Back-EMF)으로 인한 스파이크를 플라이백 다이오드로 보호하는 회로 가이드. H-브리지 4개 스위치 전체 보호, 다이오드 선택 기준, 추가 스너버와 TVS 활용법을 다룬다.

## 구조
- 역기전력 스파이크 크기: V = L × ΔI/Δt; 인덕턴스와 전류 변화율에 비례
- H-브리지 보호: 4개 스위치 모두에 역병렬 플라이백 다이오드 필요
- PWM > 20 kHz 시 1N400x 계열 사용 불가 (복구 시간 너무 느림) → 쇼트키 다이오드 필수
- 다이오드 선택 기준(원문 표 기반):
  - 1N5819: Arduino/저전류 PWM 용도 (1A, 40V)
  - 1N5822/MBR2045: 중전력 1–5A
  - MBR4045: 5A 이상 고전력
- MOSFET 보디 다이오드: 복구 속도가 느려서 별도 쇼트키를 병렬로 추가 권장
- RC 스너버: 10 Ω + 100 nF (날카로운 스파이크 흡수 보조)
- TVS 다이오드: 1.5KE15A, P6KE 계열 (높은 에너지 과도 차단)
- 모터 단자에 세라믹 100 nF 바이패스, 전원 레일에 전해 470–1000 µF 권장

## 검증·재현성
- 가이드 본문 직접 열람(L3). 다이오드 선택 표와 회로 설명 포함
- 보드 시험 기록 없음; 튜토리얼 블로그 성격

## 한계·위험
- 쇼트키 역방향 누설 전류는 고온에서 증가 — 내 판단: 열 설계 고려 필요
- TVS 클램프 전압은 모터 드라이버 IC의 절대 최대 전압보다 낮아야 함
- 외부 명령어·설치 지시문 없음 (안전)

## 재사용 메모
Basys3 FPGA 모터 드라이버 시스템의 외부 회로 설계 참고자료. FPGA 자체에 통합되지 않는 하드웨어 보호 계층.
개조: FPGA 로직 측에서는 소프트 보호(PWM OC 래치, 과전류 감지)를 추가하고, 하드웨어 측에서는 이 가이드의 쇼트키 배치와 RC 스너버를 적용. mmio-motor-safety-wrapper(I-014, used) 캡스톤의 하드웨어 보완 계층으로 활용. 모터 전원은 Basys3 보드 전원과 반드시 GND만 공통으로 분리(전기 규칙). capstone.json external_parts의 io_voltage/supply_voltage/level_shift 필드에서 플라이백 다이오드와 모터 전원 분리를 명시해야 capcheck.py 오류 없음.
