---
name: sparkfun-acs712-current-sensor
url: https://learn.sparkfun.com/tutorials/acs712-low-current-sensor-hookup-guide/all?print=1
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: [Arduino IDE]
bus: analog-out
peripherals: [current-sensor, ADC, hall-effect]
stage: T2
license: unknown
stats: {stars: null, commits: null, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://learn.sparkfun.com/tutorials/acs712-low-current-sensor-hookup-guide/all?print=1, https://embedded-lab.com/blog/a-brief-overview-of-allegro-acs712-current-sensor-part-1/]
---

## 요약

Allegro ACS712 홀 효과 전류 센서의 SparkFun 튜토리얼. 센서 동작 원리, 오프셋·게인 보정 절차, Arduino ADC 인터페이스, 노이즈 저감 방법을 설명한다. MCU 기준 작성이지만 FPGA XADC 연동 설계에 직접 참조할 수 있는 아날로그 사양을 담고 있다.

## 구조

**센서 동작 원리**
- 전류 경로(IP+/IP−)에 내부 구리 스트립을 통해 전류가 흘러 자기장 발생, 옆에 있는 홀 소자가 이를 출력 전압으로 변환
- 전류 경로와 센서 회로가 전기적으로 절연되어 있음 (내부 도체 저항 ≈ 1.2 mΩ)
- 센서를 부하와 직렬로 연결해야 함

**출력 전압 공식**
- V_OUT = VCC/2 + S × I
  - S(감도): 05B = 185 mV/A(±5A), 20B = 100 mV/A(±20A), 30A = 66 mV/A(±30A)
  - 무전류 시 출력 ≈ VCC/2 (5V 공급 기준 2.5V)
  - 비율계량(ratiometric): VCC 변동 시 V_OUT과 감도 모두 비례해 변함

**필터링**
- 내부 R_F(핀 6)에 C_F를 GND에 추가하면 RC 저역통과 필터 구성
- C_F 없을 때 최대 대역폭 80 kHz; C_F = 1 nF(데이터시트 권장)으로 줄어듦
- 보드 버전(증폭 포함): C1 필터 커패시터로 대역폭 34 kHz 고정, 제거 시 80 kHz 복원되나 노이즈 증가

**ADC 인터페이스**
- 10비트 ADC 기준: 1 LSB = 4.88 mV
- 전류 계산: I = (V_OUT − Vref) / S
  - 05B, 10비트, 5V 기준: 감도 ≈ 37.9 count/A (1023 × 0.185 / 5)
- 여러 샘플을 평균 → settling delay를 두고 반복 측정 후 가산, 평균

**보정 절차 (2단계)**
1. 오프셋(Vref): 무전류 상태에서 Vref 포트를 ADC 중간값(≈ 2.5V)에 맞춤. 단방향 DC 측정이면 더 낮게 설정 가능
2. 게인(감도): 멀티미터로 확인한 기준 전류를 흘려 게인 포트 조정, 목표 감도와 일치시킴
3. 게인 조정 후 Vref가 미세하게 이동하므로 재측정 필요

## 검증·재현성

- SparkFun 가이드는 Arduino 라이브러리 예제 코드와 함께 단계별로 보정·측정 과정을 검증
- embedded-lab Part 1은 PIC18 ADC 인터페이스 측정값을 실제 수치(zero point, 감도)로 제시
- 직접 RTL 시뮬레이션 없음 (아날로그 사양 참조 목적)

## 한계·위험

- MCU(Arduino) 기반 가이드이므로 FPGA XADC로 직접 사용 불가. XADC 입력 범위(0~1V)에 맞는 분압 필요
- ACS712 출력 2.5V는 XADC 최대 허용 1V를 초과함 → 반드시 분압 또는 레벨 변환 필요
- 자화된 금속 공구가 근처에 있으면 오독 가능
- 비율계량 특성: ADC 기준 전압과 센서 공급 전압이 일치해야 측정 오차 상쇄
- 라이선스: SparkFun 튜토리얼(CC BY-SA 4.0 추정), embedded-lab 블로그(라이선스 미기재) — 코드 복사 전 확인 필요

## 재사용 메모

**아날로그 프런트엔드 설계에 직접 참조:**
- XADC 연동 시 ACS712 출력(0~5V)을 R1·R2 분압기로 0~1V로 스케일 다운 필요
  - 예: R1 = 4kΩ, R2 = 1kΩ → 출력 × 0.2 (5V → 1V). 최대 오차 전류에서 1V를 넘지 않도록 여유 고려
  - XADC 입력 임피던스 높아 분압기 출력 임피던스 최소화 (op-amp 버퍼 삽입 권장)
- 무전류 기준점(Vref)은 소프트웨어 보정으로 오프셋 제거 가능 — 기동 시 ADC 판독값을 Vref로 저장

**디지털 필터링 (Verilog/FPGA):**
- MCU의 "샘플 평균" → FPGA에서 이동 평균 필터(moving average, N=16~256)로 대응
- 개조: MicroBlaze V AXI4-Lite 슬레이브로 `CURRENT_VALUE`, `CALIB_OFFSET`, `AVG_WINDOW` 레지스터 제공. 아날로그 프런트엔드 (R1·R2 분압 + op-amp 버퍼) → VAUXP/VAUXN → XADC IP(AXI4-Lite DRP) → Verilog 이동 평균 블록 → AXI4-Lite 레지스터 → MicroBlaze V 펌웨어 순으로 연결. CPU 종속 없는 부분: ADC 드라이버 FSM, 이동 평균 RTL, 레지스터 맵 — 이 부분은 PicoRV32나 커스텀 CPU로도 그대로 쓸 수 있음.
