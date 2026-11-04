---
name: lcsc-mosfet-selection-motor-control
url: https://www.lcsc.com/blog/how-to-select-a-mosfet-for-motor-control/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(전자회로)
language: []
tools: []
bus: none
peripherals: [mosfet, h-bridge, motor-driver, gate-driver]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.lcsc.com/blog/how-to-select-a-mosfet-for-motor-control/]
---

## 요약
모터 제어용 MOSFET 선택 가이드 (2026-05-13). VDS·ID·Rds(on)·Qg·열 저항의 5가지 기준과 로직레벨 VGS(th) 중요성을 설명한다. LCSC 쇼핑 가이드 성격이지만 선택 수치가 구체적이다.

## 구조
- VDS 선택: 최대 버스 전압 × 1.25 이상 (안전 마진)
- ID 선택: 최대 피크 전류 × 1.2 이상; 모터 스톨 시 정격 전류의 5–10배 고려
- Rds(on):
  - 중전력(5–30A): < 20 mΩ
  - 고전력(> 30A): < 5 mΩ
  - 95–98% 효율 목표: < 10 mΩ
- 로직레벨 VGS(th): 1.0–2.5V; MCU/FPGA 3.3V 직구동 시 2.5V 미만 필수
- 게이트 전하 Qg: 고전력 애플리케이션에서 < 100 nC 권장 (스위칭 손실 최소화)
- 열 관리: Tj < 125°C; 주변 온도 대비 ΔT < 40°C; TO-220 패키지 RθJC < 1°C/W
- PWM 주파수 범위: 10–100 kHz
- 언급 브랜드: WINSOK, Slkor, UMW (LCSC 내 가용)

## 검증·재현성
- 가이드 본문 직접 열람(L3). 수치 기준 표와 선택 절차 설명 포함
- LCSC 제품 판매 사이트의 블로그 성격; 특정 모델 추천은 상업적 편향 가능성

## 한계·위험
- 내 판단: 추천 브랜드(WINSOK·Slkor·UMW)는 LCSC 판매 제품 위주라 중립적이지 않음; 수치 기준은 일반적으로 타당
- 패키지 열 저항은 보드 레이아웃·방열판에 따라 크게 달라짐 — 추가 열 계산 필요
- 외부 명령어·설치 지시문 없음 (안전)

## 재사용 메모
Basys3 FPGA에서 직접 MOSFET H-브리지를 구동할 때 부품 선정 근거자료.
개조: Basys3 Pmod 출력이 3.3V이므로 VGS(th) < 2.5V 로직레벨 MOSFET이 필수. ID는 목표 모터 스톨 전류 × 1.2 계산 후 여유 선정. capstone.json external_parts의 io_voltage(3.3V), supply_voltage(모터 전원), level_shift("none" 또는 "buffer-required") 필드 작성 시 이 수치를 근거로 사용. mmio-motor-safety-wrapper(I-014) 슛스루 보호와 조합 시 최소 데드타임(200ns 이상)을 RTL에서 보장해야 Rds(on) 열 계산이 의미 있음.
