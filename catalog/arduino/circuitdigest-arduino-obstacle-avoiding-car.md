---
name: circuitdigest-arduino-obstacle-avoiding-car
url: https://circuitdigest.com/microcontroller-projects/arduino-obstacle-avoiding-car
source_type: article
vendor: neutral
board: [Arduino Uno]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE]
bus: none
peripherals: [sensor, actuator-servo, actuator-dc-motor, actuator-led]
stage: T2
license: unknown (페이지에 라이선스 미기재; 별도 GitHub Circuit-Digest/Obstacle-Avoiding-Car-Using-Arduino 저장소는 미열람)
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://circuitdigest.com/microcontroller-projects/arduino-obstacle-avoiding-car]
---
## 요약
HC-SR04를 MG90 서보에 얹어 좌·중·우 거리를 재고, L298N으로 4륜 감속 모터 2채널을 구동해 가까운 장애물을 피하는 반응형 RC카 글이다. 정지 → 3방향 스캔 → 여유가 큰 쪽 회전 → 재주행의 단순한 상태 흐름이 코드에 그대로 드러난다.

## 구조
- 부품: Arduino Uno, HC-SR04, MG90 서보 1개, L298N, RGB LED 3개, 12 V Li-ion, LM2596 강압(5 V)(글 서술).
- 핀(글 코드 기준): TRIG D2, ECHO D4, 서보 D5, 모터 IN1~IN4 D8/D7/D12/D11, ENA D6, ENB D3.
- 흐름: 서보 중앙 후 거리 측정 → 12 cm 이상이면 직진하며 50 ms마다 확인 → 12 cm 이내면 정지 → 좌·중·우 스캔 → 양쪽 모두 25 cm 이하면 직진, 아니면 여유가 큰 쪽으로 약 415~425 ms 회전(시간 기반) 후 재개.
- 전원: 서보에 별도 5 V와 100 µF 병렬 커패시터 권장, 업로드할 때 외부 Vin 분리(글 서술). 예상 구동 45~90분(2200 mAh, 글 추정).

## 검증·재현성
- 정량 시험 자료: unverified: 글에 없음. 센서 사용 범위는 글이 10~50 cm로 설명.

## 한계·위험
- 글 내부 불일치: 본문은 ENA/ENB를 D9/D10으로 쓰나 코드는 D6/D3이고 D9/D10은 LED와 겹침. 일부 구간은 L293D로 적혀 L298N과 충돌.
- `distances[3]`에 인덱스 3을 쓰는 범위 초과, 전방 값이 판단에 안 쓰임, 후진 함수는 미호출, U턴 분기는 주석 처리(글 서술).
- 회전은 시간 기반이라 배터리·바닥에 따라 각도가 달라지고, 엔코더·IMU 피드백이 없음. 부드러운 면(천, 폼)에서 초음파 오차.
- "미로를 푼다"는 주장이 있으나 코드는 반응형 회피뿐(글 서술 대조).
- 라이선스 확인 필요 → 코드를 가져오지 않는다.

## 재사용 메모
- 내 판단: 3방향 스캔 후 결정 규칙은 테스트벤치에서 합성 거리 열로 검증하기 좋은 순수 조합 논리다. 이 글의 핀·텍스트 불일치는 "명세와 코드를 대조하는 하네스의 검사 사례"로도 쓸 수 있다.
- 개조: HC-SR04 트리거/에코 측정 FSM(기존 카드 hackster-basys3-hcsr04-distance)과 서보 스캔 PWM, 거리 임계값 비교를 AXI4-Lite 레지스터(거리 3개, 임계값, 상태, 인터럽트)로 묶고, 회전 시간은 엔코더 카운트 기반으로 바꿀 수 있다. HC-SR04의 5 V 에코는 3.3 V 레벨 변환 필요, L298N 모터 전원은 보드와 분리하고 GND만 공통. Arduino `delay()` 기반 흐름은 옮기지 못하므로 FSM으로 다시 쓴다(내 판단).
