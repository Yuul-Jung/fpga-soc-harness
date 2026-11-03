---
name: waveshare-esp32-tb6612-encoder-speed-pid
url: https://waveshare.com/wiki/Tutorial_III:_Motor_With_Encoder_Control_Demo_3
source_type: article
vendor: neutral
board: ["ESP32 다기능 드라이버 보드 (Arduino IDE, 보드 상세 unverified: 페이지에 모델명 없음)"]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32)
language: C++ (Arduino)
tools: [Arduino IDE]
bus: none
peripherals: [actuator-servo, sensor]
stage: T2
license: 페이지에 라이선스 표기 없음 (라이선스 확인 필요, 코드 반입 금지)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://waveshare.com/wiki/Tutorial_III:_Motor_With_Encoder_Control_Demo_3]
---

## 요약
TB6612 H-브리지로 구동하는 DC 감속모터 2채널의 속도를 홀 엔코더 되먹임 PID로 맞추는 Waveshare 튜토리얼. 100 ms마다 엔코더 카운트로 RPM을 구하고 PID 출력을 8비트 PWM에 넣는 가장 단순한 형태의 속도 루프다.

## 구조
- 모터 DCGM3865(감속비 1:42), 홀 엔코더 모터축 1회전당 11펄스 → 출력축 1회전 462카운트 (페이지 서술).
- 엔코더: 채널 하나의 상승 에지에서 인터럽트, 다른 채널 값으로 방향(+1/-1) 결정. 1체배(단일 에지)이며 4체배 아님.
- PWM 100 kHz, 8비트(0–255). 최소 PWM은 최대의 1/5(51)로 두어 저속 정지(스톨)를 피함.
- PID: 주기 100 ms, 속도 = 카운트 ÷ 축 PPR × 60 × (1000/주기) RPM, 매 주기 카운트 초기화. 적분은 오차의 단순 합(시간 스케일·와인드업 방지 없음), 출력 ±255 제한. 변수는 double.
- 이득 Kp=0.05, Ki=0.05, Kd=0, 목표 100 RPM. 핀 배치는 ESP32 기준(PWMA 25, AIN1 21, AIN2 17 등).

## 검증·재현성
- 측정 결과 없음: 페이지는 예상 동작(정방향 3초, 역방향 3초, 정지 3초 반복)만 서술하고 속도·오차 데이터는 없음.
- 업로드 절차에 "엔코더 없는 모터를 연결"하라는 서술이 있어 엔코더 코드와 모순(페이지 오기로 보임, 내 판단).
- 테스트벤치·CI 없음. 코드는 rar 첨부(열람하지 않음, unverified).

## 한계·위험
- 이득이 왜 그 값인지 근거 없음. 적분 와인드업·샘플 주기 보정 없음 → FPGA 이식 시 그대로 따르면 안 됨(내 판단).
- 라이선스 미표기. ESP32 전용 핀·LEDC API에 의존.

## 재사용 메모
- 내 판단: 모터 사다리(엔코더→PID)의 "펌웨어 쪽 기준선"으로 쓸 만하다. 카운트-RPM 환산식과 최소 PWM(스톨 방지) 개념은 AXI4-Lite 레지스터(카운트, 목표, PWM 최소값)로 옮길 수 있다.
- 개조: 이 자료는 CPU 비종속 개념(카운터·샘플 타이머·PID)이라 MicroBlaze V 기준에서 엔코더 카운터와 PWM은 RTL 래퍼에, PID 계산은 펌웨어(고정소수점)에 둔다. 옮길 수 없는 부분은 ESP32 인터럽트·LEDC 호출이며 `cpu_irq_<cpu>.c` 한 파일 격리 원칙에 해당(내 판단). 4체배와 와인드업 방지는 새로 설계.
