---
name: technion-diglab-balance-car-fpga
url: https://diglab.technion.ac.il/?p=4156
source_type: report
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [unverified]
bus: native
peripherals: [sensor, actuator-servo, comm-spi]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://diglab.technion.ac.il/?p=4156]
unverified: 보드명, 자이로 부품명, PID 이득, 자원 사용, 코드 공개 여부 (프로젝트 소개 페이지에 없음)
---

## 요약
Technion 디지털 랩 프로젝트 페이지. 자이로 각도를 받아 SystemVerilog PID로 2륜 균형차의 PWM을 만든다. 바람이나 가벼운 충격에도 균형을 유지했다고 서술한다.

## 구조
- 흐름: 자이로 → Arduino(I2C→SPI 변환만 수행) → FPGA(SPI 슬레이브, 저역통과 + PID → PWM) → 모터 드라이버 → 모터.
- 원하는 각도 입력을 PID에 추가해 주행을 가능하게 했다.

## 검증·재현성
- 정량 지표(정착 시간 등)와 테스트벤치 서술은 없음(unverified).

## 한계·위험
- 얇은 선의 지터가 주된 어려움이었고 FPGA 저역통과로 완화. Arduino 중간 단계가 잡음을 더해 SPI 지원 자이로를 권장한다고 서술.

## 재사용 메모
- 내 판단: Arduino 중계 없이 FPGA가 I2C로 직접 읽는 쪽이 우리 사다리(I-019)와 맞다. 저역통과 + PID + PWM 구조는 모터 사다리 IP(I-017)에 그대로 연결.
- 개조: SPI 슬레이브 입력 대신 IMU I2C 마스터 IP의 각도 레지스터를 입력으로 하고 PID 이득·목표각을 AXI4-Lite 레지스터로 둔다.
