---
name: analog-maxim-interfacing-ds18x20
url: https://www.analog.com/en/technical-articles/interfacing-the-ds18x20ds1822-1wire-temperature-sensor-in-a-microcontroller-environment.html
source_type: article
vendor: neutral
board: [none]
fit_basys3: needs-port
cpu: none
language: C(예제 의사코드)
tools: []
bus: none
peripherals: [sensor, 1-wire(DS18x20)]
stage: T2
license: unknown (Analog Devices 기술 문서, 복제 금지 취급)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.analog.com/en/technical-articles/interfacing-the-ds18x20ds1822-1wire-temperature-sensor-in-a-microcontroller-environment.html]
unverified: 변환 시간(DS18B20 해상도별)과 기생 전원 상세는 이 문서에 없음. DS18B20 데이터시트 직접 열람 필요. 읽기 슬롯 타이밍의 최대·최소 표는 요약 열람이라 수치 재확인 필요.
---

## 요약
Maxim(현 Analog Devices)의 DS18S20/DS18B20/DS1822 1-Wire 온도 센서 마이크로컨트롤러 연결 기술 문서. 리셋/프레즌스, 읽기·쓰기 슬롯, ROM 명령, 스크래치패드 읽기와 CRC 순서를 C 예제로 보여 준다. FPGA 문서가 아니라 FSM의 타이밍 기준표로 쓸 수 있다.

## 구조
- 리셋: 마스터가 버스를 480 µs 동안 Low로 당기고, 해제 후 약 70 µs 지점에서 프레즌스(슬레이브가 Low로 응답)를 샘플한다(문서의 예제 지연값 기준).
- 쓰기 슬롯 60~120 µs, 슬롯 사이 회복 최소 1 µs. 쓰기 1은 슬롯 시작 15 µs 안에 해제한다.
- 읽기 슬롯: 마스터가 1 µs 동안 Low로 당겼다 해제하고, 슬롯 시작 약 15 µs 뒤에 샘플한다. 슬롯 60~120 µs.
- 풀업 4.7 kΩ, 전원 3 V~5.5 V(문서 서술). 버스는 통신과 전원을 함께 제공한다.
- ROM 명령: 0x33 Read ROM(단일 장치), 0x55 Match ROM, 0xCC Skip ROM, 0xF0 Search ROM. 기능 명령: 0x44 Convert T, 0xBE Read Scratchpad. 스크래치패드는 9바이트이고 0·1바이트가 온도 LSB·MSB다.
- CRC는 256항목 룩업 테이블로 계산(`dowcrc = table[dowcrc ^ x]`). 다항식 이름은 문서에 없음.
- ROM 검색 소요 시간 식은 문서에 있으나 표기가 깨져 있어 그대로 쓰지 않는다.

## 검증·재현성
- 코드는 의사코드 수준의 C이며 RTL·테스트벤치는 없다. 예제는 DS18S20 해석(0.5 °C 단위)이라 DS18B20은 해상도 해석을 데이터시트에서 바꿔야 한다고 문서가 밝힌다.

## 한계·위험
- 예제의 Convert T 후 대기(`delay(5)`)는 자리표시이고 실제 변환 시간이 아니다. 변환 시간을 이 문서에서 가져오지 않는다.
- 저작권이 있는 문서이므로 본문을 옮기지 않고 수치만 기록했다.

## 재사용 메모
- 내 판단: 위 µs 수치는 100 MHz 클럭의 1 µs 틱(분주 100) 기준 FSM 상태별 카운트로 바로 바꿀 수 있다. 같은 수치로 [cvut-pehnelt-2014-vhdl-periferie-nexys4](cvut-pehnelt-2014-vhdl-periferie-nexys4.md)의 FSM(리셋 500 µs, 쓰기 0은 80 µs, 읽기 12 µs 샘플)이 문서 허용 범위 안에 있는지 비교할 수 있다.
- 개조: CPU 자료가 아니다. 이 표를 `devices/1-wire/ds18b20.md`의 타이밍 근거로 쓰고, 캡스톤의 1-Wire IP는 비트 단위 마스터(리셋, 쓰기 비트, 읽기 비트)와 바이트·CRC 계층을 분리해 AXI4-Lite 레지스터(명령, 데이터, 상태)로 노출하는 구조가 자연스럽다(내 판단).
