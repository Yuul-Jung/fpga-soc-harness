---
name: arduino-forum-oled-freezes-nano-display-call
url: https://forum.arduino.cc/t/oled-freezes-nano-on-display-call/1173785
source_type: article
vendor: neutral
board: [Arduino Nano (ATmega328P)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, Adafruit SSD1306, Adafruit GFX]
bus: I2C
peripherals: [display, sensor]
stage: T1
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://forum.arduino.cc/t/oled-freezes-nano-on-display-call/1173785]
---
## 요약
128x32 SSD1306 OLED(I2C 0x3C)를 붙인 Nano가 첫 `display()` 호출에서 멈추고 화면에 노이즈가 나온 실패 사례다. 작성자는 RAM 부족을 의심했으나 실제 원인은 디스플레이 5V 배선 누락이었다(글 서술).

## 구조
- 구성: Nano + SSD1306 128x32 + DHT11 + 릴레이 + 가변저항. 라이브러리는 Adafruit SSD1306/GFX.
- 수치(글 서술): 시작 후 여유 RAM 약 963바이트, 컴파일 시 IDE 표시 사용량 566바이트. 128x32 프레임 버퍼는 512바이트(답변자가 작성자의 가정 1024바이트를 정정).
- 결론: 5V를 연결하자 브레드보드에서 동작했고, 최소 스케치로 확인한 뒤 센서를 추가했다.
- 부수 논의: 릴레이를 핀에서 직접 구동하는 것은 트랜지스터와 되돌림 다이오드 없이는 위험하다는 지적이 있었으나, 릴레이를 떼도 멈춤은 같아 이 건의 원인은 아니었다.

## 검증·재현성
- unverified: 정량 측정·재현 절차 없음(토론 글).

## 한계·위험
- 증상(첫 전송에서 멈춤, 노이즈)이 SRAM 부족 증상과 겹쳐 오진하기 쉽다는 점이 교훈이다. 포럼 글의 권고는 데이터로만 취급했다(§7).

## 재사용 메모
- 내 판단: FPGA 쪽에서도 "전원 미연결·ACK 없음"과 "버퍼 크기 오산"은 같은 모양의 실패로 보인다. I2C 마스터의 ACK 실패를 상태 레지스터 비트로 올리면 이 오진을 피할 수 있다.
- 내 계산: 프레임 버퍼 크기는 가로×세로/8바이트(128x32 → 512, 128x64 → 1024). BRAM 한 블록(36Kb)에 128x64 모노 버퍼가 충분히 들어간다.
- 개조: 옮길 부분은 "첫 전송 전 ACK 확인 + 오류 비트 노출"이라는 설계 점검 항목(AXI4-Lite I2C IP 상태 레지스터). 옮기지 않는 부분은 AVR RAM 한계 논의.
