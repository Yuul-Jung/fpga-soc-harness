---
name: arduino-forum-spi-interface-with-fpga-3-3voltage-issue
url: https://forum.arduino.cc/t/spi-interface-with-fpga-3-3voltage-issue/56385
source_type: article
vendor: neutral
board: [Arduino Uno, Spartan 3AN (답변자 서술)]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified
tools: [unverified]
bus: SPI
peripherals: [comm-spi]
stage: T2
license: unknown (포럼 글, 코드 반입 대상 아님)
stats: {last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://forum.arduino.cc/t/spi-interface-with-fpga-3-3voltage-issue/56385, https://hackaday.io/project/38-arduino-compatible-fpga-shield/log/10202-level-translation-mods, https://shillehtek.com/blogs/news/arduino-txs0108e-3-3v-5v-level-shift]
---
## 요약
Arduino Uno(5V)로 3.3V 기준 FPGA와 SPI 통신할 때의 전압 문제를 묻는 토론이다. 해결안은 Arduino를 3.3V로 낮추기, 레벨 변환 칩, 저항 분압의 세 갈래였고, 한 답변자는 저항 분압(Arduino 출력)과 직결(FPGA 출력)로 안정적으로 쓴다고 보고했다(글 서술).

## 구조
- 제안 1: 3.3V 구동. 한 답변자는 ATmega328이 16MHz에 약 4.5V가 필요하다고 보아 8MHz Pro 설정을 권했고, 3.3V로 16MHz가 될 수도 있으나 사양 보증은 아니라고 했다.
- 제안 2·3: 레벨 변환 보드/칩, 저항 분압. 방향 논리: Arduino 입력은 3.3V를 읽을 수 있으므로 변환은 Arduino 출력(MOSI, SCK, SS)에만 필요하고 MISO는 직결 가능(글 서술).
- 보조 사례(같은 주제, 다른 출처): Hackaday FPGA 쉴드 개발 로그는 5V Uno를 지원하려고 SN74CBTD3384 변환 회로를 넣어 보드를 다시 제작했고 10MHz급 성능을 의도했다고 적음. shillehtek 글은 TXS0108E에서 OE를 HIGH로 묶어야 동작하고, 약한 내부 풀업 때문에 I2C에는 BSS138형을 권한다고 적음.

## 검증·재현성
- 수치(분압 저항값, SPI 클럭)는 글에 없음 → unverified. 재현 절차 없음.

## 한계·위험
- 포럼 글이라 사실 수준은 답변자 서술. Spartan 3AN 보고는 한 사람의 경험이다.
- "Arduino 입력은 3.3V 호환" 주장은 사용 MCU의 VIH 사양 확인 없이는 일반화 금지(내 판단).

## 재사용 메모
- 내 판단: Basys3 Pmod 입력은 3.3V이므로 방향별 처리(Arduino 출력 3신호만 변환, MISO는 FPGA 출력 3.3V를 직결)는 전기 규칙(보드 I/O 3.3V, 5V 모듈은 레벨 변환)과 맞지만, 직결 가능 여부는 MCU 데이터시트로 확인해야 한다. 안전한 기본값은 양방향 변환 칩 사용.
- 개조: 옮길 부분은 "SPI 슬레이브 프런트엔드를 FPGA에 두고 Arduino를 마스터로 쓴다"는 역할 분담과 방향별 변환 점검표. 못 옮길 부분은 Spartan 3AN 구체 배선.
