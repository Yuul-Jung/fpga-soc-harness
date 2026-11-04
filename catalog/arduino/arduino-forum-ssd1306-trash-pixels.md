---
name: arduino-forum-ssd1306-trash-pixels
url: https://forum.arduino.cc/t/ssd1306-oled-trash-pixels/1209515
source_type: article
vendor: neutral
board: [AVR 계열 Arduino (보드 종류 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, Adafruit SSD1306, Adafruit GFX, OneWire, DallasTemperature, DHT]
bus: I2C
peripherals: [display, sensor]
stage: T1
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://forum.arduino.cc/t/ssd1306-oled-trash-pixels/1209515]
---
## 요약
SSD1306 128x64(0x3C)의 한쪽 구석에 쓰레기 픽셀이 나타났다 사라지는 현상을 다룬 토론이다. 답변자들은 디스플레이가 아니라 AVR의 RAM 문제로 보았고, 매 프레임 `String`을 만드는 코드가 메모리를 조각낸다고 지적했다(글 서술).

## 구조
- 구성: DS18B20 수온 센서(핀 2) + DHT22 기온 센서(핀 3) + OLED. Adafruit 데모는 정상.
- 제안된 해결: `String` 대신 널 종료 문자 배열 사용, 상수 문자열은 `F()` 매크로로 플래시에 두기, 숫자 문자열은 `dtostrf()`로 고정 크기 버퍼(글의 예는 10바이트)에 변환. 한 사용자는 이렇게 고쳐 깨끗한 화면을 얻었다고 보고.
- 부수 지적: 마지막 줄 지우기 함수가 빈 문자열만 출력해 실제로는 지우지 않는다는 지적.

## 검증·재현성
- unverified: 원인은 답변자 판단이며 작성자의 최종 확인은 글이 중간에 끊겨 확인하지 못함.

## 한계·위험
- 글의 대안 라이브러리 언급(u8g2)은 사실 확인 못 함. 포럼 글이라 사실 수준은 "작성자·답변자 서술".

## 재사용 메모
- 내 판단: 같은 현상이 FPGA에서 나오면 원인 후보가 다르다. 프레임 버퍼를 BRAM에 두고 그리는 쪽과 전송 FSM 쪽이 동시에 접근하면 구석 픽셀이 깨질 수 있다. 이중 버퍼 또는 전송 중 쓰기 금지 비트가 필요하다.
- 개조: 옮길 부분은 "문자열 포맷은 소프트웨어에서, 하드웨어는 고정 크기 버퍼만 받는다"는 역할 분담(MicroBlaze V 펌웨어가 포맷 후 AXI4-Lite로 쓰기). 못 옮길 부분은 AVR의 `String` 조각화와 `F()` 매크로.
