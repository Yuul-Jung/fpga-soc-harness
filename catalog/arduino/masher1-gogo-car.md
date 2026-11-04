---
name: masher1-gogo-car
url: https://github.com/masher1/GoGo-Car
source_type: repo
vendor: neutral
board: [Arduino (기종 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, IRremote, NewPing]
bus: none
peripherals: [hid-ir-remote, sensor, actuator-dc-motor, buzzer]
stage: T2
license: GPL-3.0 추정 (저장소에 gpl-3.0.md 파일이 있음, 정확한 선언은 미확인) → 코드 반입 금지
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/masher1/GoGo-Car]
---
## 요약
IR 리모컨으로 방향을 정하고, 주행 중에는 초음파 거리가 가까워지면 부저를 울리며 오른쪽으로 비켜 가는 작은 RC카 저장소다. 원격 명령 입력과 자동 회피 두 경로가 한 펌웨어에 합쳐진 조합이 눈에 띈다.

## 구조
- 구성 요소(README 서술): IR 수신기, 초음파 센서, 부저, 스타터 키트 전자 부품, 다른 장난감 차의 프레임과 바퀴.
- 동작: 평소에는 IR 명령이 방향을 고름. 주행 중 거리가 10 cm 미만이면 부저가 울리고 약 50도 우회전 뒤 계속 탐색. 모터가 역회전하지 못해 "후진" 명령은 180도 회전 후 전진으로 처리(README 서술).
- 파일: Firmware.ino, Buzzer.cpp/h, NewPing.cpp/h, IRremote.h, Switchable.cpp/h(목록 확인, 내용은 미열람).
- 핀 배치, 모드 전환 논리: unverified: README에 없고 소스 미열람.

## 검증·재현성
- 빌드·테스트·CI: unverified: README 범위에서 확인되지 않음. 커밋은 3건으로 표시됨.

## 한계·위험
- 후진 불가(모터 방향 제어 없음), 회피 각도 고정, 우선순위(IR 명령 vs 회피) 규칙이 문서화되지 않음.
- 라이선스: GPL 파일이 있어 코드 조각을 가져오면 전염 위험 → 사실(동작·부품)만 쓴다. 번들 라이브러리(Buzzer, NewPing)는 별도 라이선스 파일 존재.

## 재사용 메모
- 내 판단: "원격 명령 vs 안전 자동 회피"의 우선순위가 명시되지 않은 점이 설계 빈틈이며, 하드웨어에서는 안전 정지가 명령을 항상 이기는 중재 FSM을 레지스터 비트(override)로 두는 편이 안전하다.
- 개조: NEC 디코더(기존 카드 opencores-nec-ir-decoder 참고)와 거리 임계값 비교를 AXI4-Lite 레지스터와 인터럽트로 묶고, 명령→모터 매핑과 회피 동작은 MicroBlaze V 펌웨어로 옮긴다. 옮기지 못하는 부분: Arduino IRremote·NewPing 라이브러리 호출. 모터 전원 분리, 5 V 모듈은 레벨 변환 필요. 코드는 가져오지 않는다.
