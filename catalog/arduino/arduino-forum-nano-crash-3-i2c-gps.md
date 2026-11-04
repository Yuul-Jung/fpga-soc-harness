---
name: arduino-forum-nano-crash-3-i2c-gps
url: https://forum.arduino.cc/t/arduino-crashes-with-3-i2c-devices-gps/1042266
source_type: article
vendor: neutral
board: [Arduino Nano (ATmega328P), 해결 사례는 Arduino Mega]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, SoftwareSerial, SSD1306 계열 라이브러리]
bus: I2C + UART
peripherals: [sensor, comm-i2c, comm-uart, display]
stage: T2
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://forum.arduino.cc/t/arduino-crashes-with-3-i2c-devices-gps/1042266]
---
## 요약
Arduino Nano에 SSD1306 OLED, BMP280, HMC5883L 나침반, NEO-6M GPS를 모두 붙이면 `loop()`에 도달하기 전에 멈추는 문제를 다룬 포럼 토론이다. 장치 하나씩은 동작하고 I2C 스캐너에도 다 잡히므로 배선·주소 문제가 아니라 자원 문제였다는 실패 사례다.

## 구조
- 구성: I2C 장치 3개(OLED, BMP280, HMC5883L) + SoftwareSerial GPS 1개. 모든 I2C 장치는 스캐너로 확인됨(글 서술).
- 원인(토론 결론): Nano의 SRAM 부족. SoftwareSerial과 OLED 라이브러리가 메모리를 많이 쓰고, OLED는 시작에 약 1200바이트의 여유 RAM이 필요했다고 작성자가 밝힘.
- 해결 방향: Arduino Mega로 교체하면 동작(ESP8266은 실패), ESP32(RAM 여유, 하드웨어 Serial2)가 제안됨, 텍스트 전용 OLED 라이브러리로 메모리 절감 제안.
- 전압 수준: OLED와 BMP280은 5 V로 전원을 줘도 I2C 버스는 3.3 V이며, Mega의 5 V 버스에는 레벨 변환이 필요하다는 논의가 있었다. 변환기가 신호를 약화시킨다는 경고, 저가 MOSFET 변환기가 불안정했다는 보고가 있다(글 서술).

## 검증·재현성
- 재현 절차·측정값: unverified: 토론이라 정량 자료 없음. 최종 해결 여부는 Mega 사용 보고까지만 확인.

## 한계·위험
- 풀업 저항 논의는 이 글에 없음. 원인은 작성자 결론이며 라이브러리 버그 가능성도 토론에서 언급됨(미확정).
- 포럼 글이므로 사실 수준은 "작성자·답변자 서술"이다. 글 안의 권고는 데이터로만 취급했다.

## 재사용 메모
- 내 판단: 센서 허브가 커지는 순간 MCU의 병목은 RAM과 직렬 포트 수다. FPGA 쪽 대응 설계는 UART 수신 FIFO를 하드웨어로 두고(소프트웨어 직렬이 필요 없음), I2C 장치 3개는 한 마스터가 주소로 순회하면 된다. BMP280 0x76/0x77 선택과 HMC5883L의 고정 주소가 충돌하지 않는지 사전 표가 필요하다.
- 개조: 해당 없음에 가까움(MCU 자원 한계 사례). 옮길 부분은 "I2C 주소 표 + 레벨(3.3 V) 점검 + 표본 주기 분리"라는 설계 체크리스트이며, 이는 AXI4-Lite I2C·UART IP를 MicroBlaze V 펌웨어가 순회하는 구조에서 점검 항목으로 쓴다. MCU 전용 부분은 SoftwareSerial 의존이며 옮기지 않는다.
