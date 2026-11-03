---
name: circuitdigest-feroflyf405-open-source-fc
url: https://circuitdigest.com/news/feroflyf405-an-open-source-drone-flight-controller-designed-from-scratch-on-the-stm32f405-with-inav-ported
source_type: article
vendor: neutral
board: [FeroFlyF405 (자작 4층 PCB 50x65 mm)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C
tools: [INAV (커스텀 target 파일), KiCad]
bus: none
peripherals: [sensor, comm-uart, comm-can, debug]
stage: T4
license: CERN-OHL-P-2.0 (하드웨어, 기사 서술). 펌웨어 target은 별도 저장소, 라이선스 unverified
stats: {last_update: 2026-10-06}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://circuitdigest.com/news/feroflyf405-an-open-source-drone-flight-controller-designed-from-scratch-on-the-stm32f405-with-inav-ported]
---
unverified: source_rev — 기사 글이라 해당 없음. 하드웨어·target 저장소는 열람하지 않음.

## 요약
STM32F405 기반 비행 제어기를 처음부터 설계하고 INAV를 이식한 사례를 소개하는 기사다(2026-10-06 게시). 설계자가 겪은 문제 목록이 구체적이라 실패 사례로 가치가 있다.

## 구조
- MCU STM32F405, 센서 LSM6DSL IMU·DPS368 기압계, 모터 출력 12개, CAN(부품 품절로 미실장), I2C, UART 3개.
- 전원: 3S LiPo 입력, 벅 컨버터로 5V, 레귤레이터로 3.3V.

## 검증·재현성
- 비행 시험에서 한쪽으로 기울었고, 설계자는 모터 3이 느리고 ESC3가 보정되지 않은 탓으로 본다. 아직 깨끗하게 날지 못한다고 서술한다.

## 한계·위험
- 모터 출력 3이 DMA 없는 타이머 채널에 있어 INAV에서 DShot·OneShot을 못 쓴다(V1.1이 해결한다고 서술).
- INAV가 기압계를 I2C 0x76에서 찾는데 DPS368은 기본 0x77이라 target 매크로로 고쳤다.
- 피치·롤이 약 10초 뒤 표류. IMU를 바꿔도 같았고 ahrs_dcm_kp를 2000에서 4000으로 올리자 약 3도로 줄었다. 원인은 불명(설계자 서술).
- SBUS 전용 입력과 XT30 커넥터 없음.

## 재사용 메모
- 내 판단: "타이머 채널의 DMA 가능 여부를 핀 배정 단계에서 확인한다"와 "센서 I2C 주소를 문서에서 대조한다"는 두 교훈은 Basys3 IP에도 그대로 점검표 항목이 된다(채널별 기능 제약, 주소 불일치).
- 개조: 옮길 부분은 IMU 표류를 자이로 적분과 가속도 보정의 이득 비(상보 필터 이득)로 다루는 방법을 레지스터화하는 설계, 시험 시 모터별 출력 편차를 비교하는 점검 항목. 못 옮길 부분은 INAV 코드와 CAN 통합.
