---
name: howtomechatronics-max7219-matrix-tutorial
url: https://howtomechatronics.com/tutorials/arduino/8x8-led-matrix-max7219-tutorial-scrolling-text-android-control-via-bluetooth/
source_type: article
vendor: neutral
board: [Arduino Uno/Nano 계열]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, MaxMatrix 라이브러리]
bus: none (3선 직렬: DIN/CLK/CS)
peripherals: [display, comm-bt]
stage: T1
license: unknown (페이지 저작권 표기, 라이브러리 라이선스 미기재 → 코드 반입 금지)
stats: {last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://howtomechatronics.com/tutorials/arduino/8x8-led-matrix-max7219-tutorial-scrolling-text-android-control-via-bluetooth/, https://github.com/tardate/LittleArduinoProjects/blob/master/playground/LED8x8/MaxRawDemo]
---
## 요약
MAX7219 8x8 모듈을 Arduino에서 구동하고 글자를 흘려 보내며, HC-05로 안드로이드에서 문구를 바꾸는 튜토리얼이다. 프레임 형식은 설명하지 않고 라이브러리 함수로 감싼다. 보조로 본 tardate의 MaxRawDemo 페이지가 "16비트 한 프레임 = 레지스터 주소 8비트 + 데이터 8비트, CS 상승 에지에서 래치"라고 밝힌다.

## 구조
- 핀: VCC, GND, DIN, CLK, CS, 체인용 DOUT. 예제는 DIN·CLK·CS를 임의 디지털 핀(7, 6, 5)에 연결.
- 체인: 앞 보드 DOUT → 다음 보드 DIN, 나머지 선은 공유. 라이브러리의 모듈 수가 실제와 같아야 함. 저자 권장 최대 8개.
- 라이브러리 함수(글 서술): 초기화, 밝기(0~15), 점 찍기, 지우기, 스프라이트 쓰기, 좌측 이동, 열 쓰기. 폰트는 PROGMEM에 둠.
- 다중화 동작: 칩이 동시에 최대 8개 LED만 켜고 빠르게 훑어 정지 영상처럼 보이게 한다.

## 검증·재현성
- 레지스터 맵(디코드·밝기·스캔 한계·종료·시험)은 이 두 페이지에 없음 → unverified: 데이터시트 열람 필요(큐).

## 한계·위험
- 댓글 보고: FC-16 보드는 소프트웨어로 회전 보정이 필요한 경우가 있음, 모듈을 많이 연결하고 밝게 하면 Arduino 5V 핀이 과부하일 수 있어 외부 5V 권장, Pro Mini에서 불안정 보고.
- 핀 충돌: 블루투스 SoftwareSerial 핀이 DIN과 겹쳐 저자가 핀을 고쳤고, HC-05 기본 속도가 9600인 경우 예제의 38400과 맞지 않을 수 있다는 보고.
- 전기: 모듈은 5V 구동. Basys3 Pmod는 3.3V이므로 DIN/CLK/CS 입력 문턱과 전원 방식은 데이터시트 확인 필요(unverified), 5V는 보드와 분리해 GND만 공통(전기 규칙).
- 페이지는 저작권 표기가 있고 라이브러리 라이선스를 명시하지 않아 코드·이미지는 가져오지 않았다.

## 재사용 메모
- 내 판단: MAX7219는 CS 상승에서 래치하는 16비트 프레임이라 SPI 마스터 FSM이 작다. 8x8 모듈을 4개 체인하면 한 갱신에 프레임 4개를 연속 전송(내 계산: 행 8줄 × 4모듈 × 16비트 = 512비트)하면 된다.
- 개조: 옮길 부분은 라이브러리 함수 구분(초기화/밝기/한 줄 쓰기/이동)을 AXI4-Lite 레지스터(프레임 버퍼 창 + 밝기 + 갱신 비트)로 나누는 구조. 못 옮길 부분은 AVR 전용 PROGMEM·SoftwareSerial.
