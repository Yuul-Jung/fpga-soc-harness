---
name: digilent-pmod-shield-refmanual
url: https://reference.digilentinc.com/add-ons/pmod-shield/refmanual?redirect=1
source_type: article
vendor: neutral
board: [Digilent Pmod Shield + Arduino Uno R3형 헤더 보드, chipKIT/Arty (문서 서술)]
fit_basys3: needs-port
cpu: none(MCU 호스트 보드)
language: unverified
tools: [unverified]
bus: SPI, I2C, UART, GPIO (Pmod 포트 매핑)
peripherals: [comm-spi, comm-i2c, comm-uart]
stage: T2
license: unknown (Digilent 문서, 코드 반입 대상 아님)
stats: {last_update: "2017-05-05 (문서 Rev B 표기)"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://reference.digilentinc.com/add-ons/pmod-shield/refmanual?redirect=1, https://digilent.com/blog/pmod-and-microcontroller-connection-guide-part-2/]
---
## 요약
Pmod 모듈을 Arduino Uno R3형 헤더 보드에 꽂게 해 주는 Digilent 확장 보드의 참조 문서다. 어느 Pmod 포트가 어느 Arduino 핀(SPI, I2C, UART, PWM, 아날로그)에 연결되는지 표로 정리되어 있다. 반대 방향(Arduino 모듈 → Basys3 Pmod)의 어댑터는 아니다.

## 구조
- 매핑(문서 서술, Uno 열): JC 윗줄이 SPI(JC1=SS/D10, JC2=MOSI/D11, JC3=MISO/D12, JC4=SCK/D13), JB2/JB3=UART TX/RX(D1/D0), JD4=SCL(A5), JE7=SDA(A4), JC7=INT0(D2), JC9=A1.
- JA는 단일열 Arduino 스타일 보드와 호환되지 않고, JD·JE는 그런 보드에서 Pmod를 직접 지원하지 않는다.
- I2C 풀업은 점퍼(JP10, JP11)로 켜고 끈다. 다른 장치가 풀업을 제공하면 제거한다.
- 전원: 호스트에서 3.3 V, 5.0 V, GND, VIN을 받는다. J2는 외부 I2C 장치용 3.3 V를 제공한다.
- 보조 출처(Digilent 블로그): Pmod 대부분이 SPI·I2C·UART·GPIO이고 6핀·12핀 케이블이나 점퍼로 호스트 포트가 모자랄 때 연결한다고 설명. 이 글에는 레벨 변환·5V 주의가 없다.

## 검증·재현성
- 문서에 Pmod별 시험 결과나 CI는 없다. unverified.

## 한계·위험
- 문서는 포트별 로직 레벨 허용치를 적지 않았다고 요약됨 → 5V 장치를 3.3V 호스트에 직접 연결하기 전에 호스트 데이터시트 확인 필요(문서 서술 + 내 판단).
- 핀 기능이 호스트 보드마다 달라 문서의 보드별 표 확인 필요.

## 재사용 메모
- 내 판단: 6핀 SPI Pmod의 신호 순서(SS, MOSI, MISO, SCK)를 Basys3 Pmod 래퍼의 핀 이름 규약으로 쓰면 Arduino SPI 핀 이름과 1:1로 대응해 배선 오류가 줄어든다.
- 개조: Arduino ↔ Basys3 연결 변환판을 설계할 때 이 문서의 매핑을 "Arduino 핀 → Pmod 핀" 역표로 뒤집어 쓴다. 못 옮길 부분: PIC32 전용 행, chipKIT 전용 점퍼.
