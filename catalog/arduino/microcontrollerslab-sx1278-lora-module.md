---
name: microcontrollerslab-sx1278-lora-module
url: https://microcontrollerslab.com/sx1278-lora-rf-module-pinout-arduino-interfacing-datasheet/
source_type: article
vendor: neutral
board: [Arduino + SX1278(Ra-02) 모듈 (글 서술)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE, LoRa 라이브러리 (Sandeep Mistry, 글 서술)]
bus: SPI
peripherals: [comm-spi]
stage: T1
license: unknown (글에 라이선스 표기 없음)
stats: {last_update: 2026-10-09}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://microcontrollerslab.com/sx1278-lora-rf-module-pinout-arduino-interfacing-datasheet/]
---
변경: 2026-11-03 source_rev 필드 제거(형식 오류). 사유 보존 — unverified: 블로그 글, 커밋 해시 없음

## 요약
SX1278(Ra-02) 433 MHz LoRa 모듈의 핀 배치와 Arduino 연결을 소개하는 입문 글. 레지스터 수준 설명은 없고, 모듈 개요와 LoRa 라이브러리 호출 목록 중심이다(2020-01-22 게시, 2026-10-09 수정 메타데이터).

## 구조
- 모듈: 433 MHz, 외부 안테나, 3.3 V, TTL 신호. 글은 범위 5–10 km, 변조 GFSK·FSK·OOK·GMSK, FIFO 256(글에는 "256-bit"로 표기)을 주장한다. 송신 출력, 수신 감도, 전류: unverified: 글에 수치 없음.
- 핀: 3.3 V(핀 3), GND(2, 9, 16), ANT(1), RESET(4), DIO0–DIO5(5–8, 10, 11, DIO0는 인터럽트로 사용 가능), SCK(12), MISO(13), MOSI(14), NSS(15). 모듈 핀 번호 기준.
- Arduino 쪽: SPI 핀은 보드 SPI 핀에, NSS·RESET·DIO0는 임의 디지털 핀. 호출: setPins, begin(433E6), beginPacket/print·write/endPacket, parsePacket/available/read/packetRssi. 페이로드 최대 255바이트.
- SPI 레지스터 접근 규칙(주소 비트 7), RegOpMode, FIFO 조작: unverified: 글에 설명 없음(데이터시트 미열람).

## 검증·재현성
- 테스트·측정: unverified: 해당 없음. 글의 범위 수치는 마케팅성 주장이며 측정 근거 미확인.

## 한계·위험
- 레지스터 정보가 없어 FPGA 구현의 근거로는 부족하다. 데이터시트(Semtech) 열람이 필요하며 이 사이클에서는 하지 못함.
- 글 서술: 지원하지 않는 주파수 설정은 오동작, 라이브러리는 암호화 없음.
- 라이선스 표기 없음 → 코드 반입 금지. 라이선스 확인 필요.

## 재사용 메모
- 내 판단: 핀 표(NSS/RESET/DIO0)는 SPI 슬롯 + GPIO 출력 1(RESET) + 입력 1(DIO0 인터럽트)로 IP 인터페이스 정의에 바로 쓸 수 있다. 입문 사다리의 최저 단계(핀·호출 개요) 자료.
- 개조: DIO0를 인터럽트 소스로, RESET을 GPIO 출력으로 AXI4-Lite IP에 두고 SPI 레지스터 시퀀스는 펌웨어로 옮긴다(Arduino 라이브러리 호출을 레지스터 읽기·쓰기로 번역해야 함). 옮길 수 없는 부분은 Arduino 라이브러리 구현(MCU 전용).
- 전기: 3.3 V 전용이라 Basys3 I/O와 직결 가능(글 서술 기준 3.3 V).
