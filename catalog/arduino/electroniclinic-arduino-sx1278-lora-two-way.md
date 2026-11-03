---
name: electroniclinic-arduino-sx1278-lora-two-way
url: https://www.electroniclinic.com/arduino-sx1278-lora-based-two-way-communication-system/
source_type: article
vendor: neutral
board: [Arduino 2대 + SX1278 LoRa 433 MHz 모듈 (글 서술, 보드 모델 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, LoRa 라이브러리, Adafruit_SSD1306]
bus: SPI
peripherals: [comm-spi, sensor, display]
stage: T2
license: unknown (글에 라이선스 표기 없음 → 코드 반입 금지)
stats: {last_update: 2024-09-21}
doc_language: en
verification: L3
checked_at: 2026-11-03
source_rev: "unverified: 블로그 글, 커밋 해시 없음"
sources: [https://www.electroniclinic.com/arduino-sx1278-lora-based-two-way-communication-system/]
---

## 요약
Arduino 두 대가 SX1278 LoRa 모듈로 주소 지정 양방향 메시지를 주고받는 블로그 예제. 마스터는 가변저항 값을 보내고, 슬레이브는 버튼 상태를 보내며 받은 값을 OLED에 표시한다(2021-10-07 게시, 2024-09-21 갱신).

## 구조
- 배선(글 서술): VCC 3.3 V, MISO 12, MOSI 11, SCK 13, NSS 10. 레벨 변환 언급 없음(모듈은 3.3 V 소자).
- 라이브러리: SPI, LoRa(무선), Adafruit_GFX·SSD1306(슬레이브 OLED, I2C 0x3C).
- 설정: `LoRa.begin(433E6)`. 코드 주석은 915 MHz로 되어 있어 값과 모순 → 실제 호출값 기준으로 기록.
- 패킷: 헤더(목적지, 발신지, 메시지 ID, 길이) + 페이로드. 마스터 주소 0xBB, 슬레이브 0xFF(브로드캐스트와 같은 값). 수신 측은 길이 일치와 주소(자신 또는 브로드캐스트)를 확인해 수락.
- 루프: 타이머 송신 후 `parsePacket()`으로 수신 처리. 송신 간격은 난수로 조정(주석은 2–3초, 계산식은 약 100–150 ms로 불일치).

## 검증·재현성
- 테스트벤치·CI·자원 수치: unverified: 해당 없음(MCU 스케치). 독자 댓글에 초기화 후 시리얼 출력이 비는 문제가 흔하다는 서술(글 서술 기준).

## 한계·위험
- 확인·재시도·충돌 처리 없음(글 서술 기준 구조상 확인). 길이 필드 1바이트라 긴 메시지는 분할 필요.
- `while (!Serial);`가 USB 시리얼 없이는 시작을 막음, Arduino `String` 반복 사용으로 메모리 단편화 가능, 버튼 상태를 변화 시에만이 아니라 반복 송신. 일부 변수 미사용·주석 불일치.
- 라이선스 불명 → 코드를 가져오지 않는다. 라이선스 확인 필요.
- 주파수 대역은 지역 규정 확인이 필요하다(글이 주파수 불일치를 알리지 않음, 내 판단).

## 재사용 메모
- 내 판단: 목적지/발신지/ID/길이 헤더는 FPGA에서 프레임 파서(바이트 FSM)로 만들기 쉽고, 주소 필터와 길이 검사는 하드웨어 몫, 재전송·ACK 정책은 펌웨어 몫으로 나누면 이 예제의 약점(확인 없음)을 보완한다.
- 개조: LoRa 라이브러리 호출은 SX1278 SPI 레지스터 접근으로 풀어야 하므로 SPI 바이트 엔진 + FIFO 접근을 AXI4-Lite 레지스터 IP로 두고, 패킷 헤더 규칙은 펌웨어 구조체로 옮긴다. 옮길 수 없는 부분은 Arduino LoRa 라이브러리 내부와 Arduino 타이머·String 사용(MCU 전용).
- 전기: 3.3 V 모듈이라 Basys3 I/O와 직결 가능, 안테나 연결 없이 송신하지 않을 것(일반 RF 주의, 이 글에는 언급 없음).
