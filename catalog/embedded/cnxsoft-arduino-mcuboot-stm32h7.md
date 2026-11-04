---
name: cnxsoft-arduino-mcuboot-stm32h7
url: https://www.cnx-software.com/2022/04/13/arduino-mcuboot-secure-bootloader/
source_type: article
vendor: neutral
board: [Arduino Portenta H7, Nicla Vision]
fit_basys3: needs-port
cpu: Cortex-M7(STM32H7)
language: C
tools: [Arduino IDE, imgtool.py, mcuboot-arduino-stm32h7]
bus: none
peripherals: [storage-spi-flash, comm-uart]
stage: T3
license: unknown
stats: {stars: N/A, commits: N/A, last_update: 2022-04-13}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.cnx-software.com/2022/04/13/arduino-mcuboot-secure-bootloader/, https://github.com/arduino/mcuboot-arduino-stm32h7, https://blog.arduino.cc/2022/04/12/introducing-the-arduino-secure-boot/]
---

## 요약

Arduino가 MCUboot 기반 보안 부트로더를 STM32H7 보드(Portenta H7, Nicla Vision)에 적용한 사례. 1차 슬롯은 내부 플래시, 2차 슬롯과 스크래치는 외부 QSPI 플래시를 사용하는 이종 플래시 레이아웃이 특징. 이미지 서명·암호화 적용, 슬롯 스왑 후 미확인 시 자동 복구, 키 없으면 검증 건너뜀.

## 구조

- **1차 슬롯(SLOT 0)**: STM32H7 내부 플래시 → 현재 실행 이미지.
- **2차 슬롯(SLOT 1)**: QSPI 외부 플래시 → `update.bin`(업데이트 이미지).
- **스크래치 영역**: QSPI 플래시 → `scratch.bin`(스왑 중간 버퍼).
- **이종 플래시 레이아웃**: 내부+외부 플래시를 각 슬롯에 배치하는 MCUboot의 플렉서블 파티션 기능 활용.
- **서명·암호화**: 이미지 서명 검증 후 부팅. 플래시에 키가 없으면 검증 건너뜀(하위 호환).
- **확인·복구**: 새 스케치가 `boot_set_confirmed()` 호출 안 하면 다음 부팅 때 이전 스케치로 복구.
- **부트스트랩**: 1차 슬롯 비어 있으면 2차 슬롯에서 로드.
- **중간 재설정 복구**: 스왑 중 전원 끊겨도 이미지 트레일러로 복구.
- **OTA 전송 방식**: Arduino의 기존 OTA 업그레이드 흐름 재사용(세부 미공개).

## 검증·재현성

- Arduino Portenta H7, Nicla Vision에서 동작 확인(Arduino 공식 릴리스).
- 키 생성·이미지 서명·부트로더 전환 절차는 GitHub 저장소에 단계별 가이드.
- Zephyr·NuttX·Apache Mynewt에서도 이론적으로 작동(미검증).
- unverified: GitHub 저장소(arduino/mcuboot-arduino-stm32h7) 직접 열람 불가(PROVENANCE_REQUIRED).

## 한계·위험

- 플래시에 키가 없으면 서명 검증이 비활성화됨 — 보안 의존성 주의.
- QSPI 플래시 슬롯 크기는 보드 HW에 종속.
- Mbed OS 기반 Arduino 보드 대상. STM32H7 외 MCU 이식 미확인.

## 재사용 메모

Basys3 SoC에서 가장 직접적으로 적용 가능한 패턴: Basys3의 외부 Pmod 포트에 SPI Flash 모듈(W25Q 계열)을 2차 슬롯으로 연결하고, 내부 BRAM을 1차 슬롯(실행 이미지)으로 쓰는 이종 플래시 OTA 구조. `개조:` MCUboot 자체는 소프트 CPU 환경에서 동작하지 않으므로, MCUboot의 "overwrite-only + imgtool 서명 헤더 검증" 패턴을 MicroBlaze V C 코드로 재구현하는 것이 현실적. SPI Flash AXI 마스터 IP(library/rtl) 위에 SHA256 검증 루틴 추가가 핵심 — 내 판단.
