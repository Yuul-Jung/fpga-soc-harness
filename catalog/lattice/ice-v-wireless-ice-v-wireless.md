---
name: ice-v-wireless-ice-v-wireless
url: https://github.com/ICE-V-Wireless/ICE-V-Wireless
source_type: repo
vendor: lattice
board: [ICE-V Wireless (ESP32-C3-MINI-1 + iCE40UP5k-SG48)]
fit_basys3: needs-port
cpu: none (ESP32-C3가 호스트 MCU, FPGA 내부 CPU 여부 unverified)
language: C (ESP-IDF 펌웨어), Python(호스트 스크립트), HDL(언어 unverified)
tools: [ESP-IDF, KiCad 6, GitHub Actions]
bus: SPI (ESP32↔FPGA, 핀·프로토콜 unverified)
peripherals: [comm-spi, comm-uart, debug]
stage: T3
license: MIT
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://github.com/ICE-V-Wireless/ICE-V-Wireless]
---
unverified: source_rev — 커밋 SHA 열람 권한이 응답 없이 철회되어 확인 못 함

## 요약
ESP32-C3와 iCE40UP5k를 한 보드에 묶은 공개 하드웨어다. ESP32 펌웨어가 USB와 Wi-Fi(TCP 소켓)로 FPGA를 감시·제어하고, FPGA 비트스트림도 ESP32가 올려 준다. "MCU가 와이파이 창구, FPGA가 주변장치"라는 분업의 완결 사례다.

## 구조
- 하드웨어: ESP32-C3-MINI-1(4MB 플래시), iCE40UP5k-SG48, FPGA에 직결된 8MB PSRAM, Pmod 3개, USB-C, LiPo 충전, RGB LED는 FPGA가 구동(README 서술). 회로도 PDF는 `docs/esp32c3_fpga_schematic.pdf`.
- 통신: ESP32와 FPGA는 SPI로 소통한다고만 적혀 있고, 사용 GPIO·FPGA 핀·클럭·명령 형식은 README에 없다. unverified: `Firmware`와 `python` 소스를 열람하지 않음.
- 구성: 전원 투입 시 SPIFFS에 저장된 설정을 FPGA에 적재, 또는 USB/Wi-Fi로 즉시 적재. 저장본도 USB/Wi-Fi로 교체 가능(README 서술).
- 펌웨어(C, ESP-IDF): USB 인터페이스와 Wi-Fi TCP 소켓, LiPo 전압 감시. SSID·암호는 USB로 설정. 빌드는 GitHub Actions(`build-firmware.yml`, `build-gateware.yml`).

## 검증·재현성
- CI 워크플로 두 개가 있음(README 서술). 내용·통과 여부는 unverified: 워크플로 파일 열람하지 않음. 자원 사용·타이밍 수치 없음.

## 한계·위험
- README에 한계 절이 없다. Pmod 전원을 비정류 약 4V로 쓰려면 기판 패턴을 끊고 납땜해야 한다(README 서술).
- 보드가 없으면 재현 불가. 이 저장소를 실행하거나 비트스트림을 받지 않았다(§7).

## 재사용 메모
- 내 판단: 우리 Basys3 SoC에서는 ESP32를 UART/SPI 호스트로 두는 구조와 같다. "텔레메트리 요청 → FPGA 레지스터 읽기 → TCP로 회신" 흐름을 시험 환경 후보로 삼을 수 있다.
- 개조: 옮길 부분은 FPGA 레지스터 창을 SPI로 읽고 쓰는 호스트 프로토콜 개념과 구성 적재 흐름의 분리. 못 옮길 부분은 iCE40 전용 비트스트림 적재, ESP32-C3 펌웨어. 프로토콜 세부는 소스 열람 뒤에 AXI4-Lite 브리지(I-038)와 맞춘다.
- 라이선스 MIT이므로 사양 추출은 가능하나 코드 반입은 사용자 승인 필요(§16.3 G4).
