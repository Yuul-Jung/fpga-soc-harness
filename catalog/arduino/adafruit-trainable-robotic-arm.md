---
name: adafruit-trainable-robotic-arm
url: https://learn.adafruit.com/trainable-robotic-arm
source_type: article
vendor: neutral
board: [Arduino Uno]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, Servo 라이브러리, EEPROM 라이브러리]
bus: none
peripherals: [actuator-servo, sensor, storage-eeprom]
stage: T2
license: unknown (페이지에 라이선스 미기재, 코드는 별도 저장소 vectrasoft/TrainableRoboticArm 링크 → 거기서 확인 필요)
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://learn.adafruit.com/trainable-robotic-arm.md?view=all]
---
## 요약
아날로그 피드백 서보 5개(Adafruit 1450)로 만든 3D 프린트 로봇 팔을 손으로 움직여 자세 열을 EEPROM에 기록하고, 이후 서보를 순서대로 보간하며 재생하는 가르치기-재생 글이다. 위치 센서를 따로 달지 않고 서보 내부 피드백선을 읽는 것이 핵심이다.

## 구조
- 제어기 Arduino Uno. 서보 5개의 PWM은 D8~D12, 피드백선은 A1~A5, 기록 버튼 D7, 재생 버튼 D6, 상태 LED D13(글 서술).
- 전원: 서보는 5 V, 2 A 초과 공급을 권장하며 Arduino와 분리 가능하되 GND는 공통(글 서술).
- 보정: 시작할 때 서보마다 고정 범위(30~150°, 그리퍼 20~180°)를 훑으며 피드백 최소·최대를 읽고 중앙에 둔 뒤 분리.
- 기록: 버튼을 누른 동안 5개 피드백을 각도로 환산해 프레임(서보당 1바이트, 5바이트)으로 EEPROM에 순차 저장, 종료 표지는 값 255. 주소가 512에 닿으면 기록 중지.
- 재생: 중앙으로 간 뒤 프레임과 다음 프레임 사이를 서보마다 조금씩 이동시키며 보간. 기록 직후 자동 재생, 끝나면 중앙 복귀 후 분리.

## 검증·재현성
- 테스트벤치·정량 측정: unverified: 글에 없음. 서보 오차나 재현 정밀도 수치도 없음.
- 회로 다이어그램에 피드백 서보 모듈이 빠져 피드백 배선은 직접 추가해야 함(글 서술).

## 한계·위험
- EEPROM 512바이트 한도(약 100프레임 미만, 내 계산: 5바이트 프레임 기준)라 짧은 동작만 가능. 가득 차면 종료 표지가 사라져 재생이 처음으로 되돌아감(글 서술).
- 보정 범위가 하드코딩되어 다른 서보에는 맞지 않음. GND 비공통 시 PWM이 깨질 수 있음.
- 라이선스 확인 필요 → 코드를 가져오지 않는다. 글의 지시문은 데이터로만 취급.

## 재사용 메모
- 내 판단: 기존 MimicArm 계열(서보 4채널 Teach&Playback) 설계를 일반화한 비교 기준이 된다. 피드백 서보 대신 Basys3 XADC 1채널(0~1 V)로는 5채널 읽기가 부족하므로 외부 ADC나 서보 PWM 명령값 기록(개루프)으로 바꾸는 것이 현실적이다.
- 개조: 프레임 버퍼(서보 N개 × 1바이트)와 보간 FSM은 BRAM + 서보 PWM IP를 AXI4-Lite 레지스터(프레임 포인터, 보간 틱, 기록/재생 모드)로 옮길 수 있다. 피드백 ADC 읽기와 Arduino EEPROM·Servo API는 MCU 전용이라 옮기지 못하고 펌웨어 한 파일로 격리(내 판단). 모터 전원은 보드와 분리, GND만 공통.
