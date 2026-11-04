---
name: element14-fmilburn-arduino-dc-motor-encoder-part1
url: https://community.element14.com/products/arduino/b/blog/posts/simple-arduino-dc-motor-control-with-encoder-part-1
source_type: article
vendor: neutral
board: [Adafruit M4 Feather Express (ATSAMD51)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ATSAMD51)
language: C++ (Arduino)
tools: [Arduino IDE]
bus: none
peripherals: [actuator-servo, sensor]
stage: T1
license: 페이지에 표기 없음 (라이선스 확인 필요)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://community.element14.com/products/arduino/b/blog/posts/simple-arduino-dc-motor-control-with-encoder-part-1?pifragment-7298=2]
---

## 요약
작성자 fmilburn(2020-01)이 TB6612FNG(Pololu 보드)로 소형 감속 DC 모터 2개와 홀 엔코더를 먼저 개방 루프로 점검하는 1부. 구동기 7핀 배선, 최소 PWM, 정방향·역방향·제동 시험 순서를 보여 준다. PID는 후속 글 몫이다.

## 구조
- 구동기: TB6612FNG, 채널당 최대 1.2 A, 최대 15 V(글 서술; 다른 자료는 13.5 V 표기 → 값은 데이터시트 카드 우선). 모터는 12 V 정격이지만 6 V에서 사용, 전원은 전류 제한 100 mA 벤치 전원.
- 핀: PWMA=5, AIN2=6, AIN1=9, BIN1=10, BIN2=11, PWMB=12, STBY=13.
- 방향표: L/H 정방향, H/L 역방향, L/L 제동. 8비트 PWM, 최소 PWM은 최대의 1/3로 잡아 모터가 실제로 돌게 함.
- 엔코더: 자석 4개 디스크 + 홀 센서 2채널, 오실로스코프로 A채널만 관찰. 한 채널이면 속도 제어에 충분하다는 주장(검증 없음). PPR 값 unverified: 글에 수치 없음.

## 검증·재현성
- 정성 평가만 있음(모터·엔코더가 기대대로 동작). 펄스율·속도·카운트 수치 없음. 시험 코드는 `delay()` 차단형이고 ramp 20단계 × 2초.

## 한계·위험
- 폐루프·인터럽트 카운팅 코드 없음(1부 범위 밖). 코드 주석(RPM)과 실제 클램프(PWM)가 불일치하고 오타가 있다고 글이 밝힘.
- 단일 채널 방식은 방향 정보를 코드로만 안다 → 역방향 구동 시 카운트 부호 오류 위험(내 판단).

## 재사용 메모
- 내 판단: "개방 루프 점검 → 최소 PWM 찾기 → 폐루프" 순서는 모터 사다리의 첫 단(T1)으로 그대로 쓸 수 있다. Basys3에서는 STBY를 GPIO 한 비트로, 최소 PWM과 램프를 레지스터로 두면 같은 점검 절차를 시험 가능.
- 개조: PWM·방향·STBY는 AXI4-Lite 모터 IP 레지스터로, 램프 시험은 펌웨어로 옮긴다. 옮길 수 없는 것은 SAMD51 `analogWrite` 해상도 API(MCU 전용). 3.3 V FPGA 출력으로 TB6612FNG 논리 입력(2.7~5.5 V, 다른 카드 기준)을 직접 구동할 수 있어 레벨 변환은 불필요하나 모터 전원은 분리(내 판단).
