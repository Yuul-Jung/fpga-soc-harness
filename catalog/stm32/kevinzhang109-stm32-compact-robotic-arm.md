---
name: kevinzhang109-stm32-compact-robotic-arm
url: https://dev.to/kevinzhang109/building-a-compact-stm32-robotic-arm-for-smart-material-handling-4fak
source_type: article
vendor: neutral
board: [STM32F407ZET6 (보드명 미기재)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C
tools: [Keil, STM32 HAL]
bus: none
peripherals: [actuator-servo, comm-eth, sensor]
stage: T3
license: unknown (블로그 글)
stats: {last_update: 2025-10-08}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://dev.to/kevinzhang109/building-a-compact-stm32-robotic-arm-for-smart-material-handling-4fak]
---
unverified: source_rev — 글이라 해당 없음. 소스 저장소 링크는 확인하지 못함.

## 요약
STM32F407 한 개로 서보 6개짜리 소형 로봇 팔을 구동하고, 안드로이드 앱이 Wi-Fi TCP로 명령을 보내는 구성이다(2025-10-08). 폐루프 PID는 앞으로의 과제로 적혀 있다.

## 구조
- 펌웨어 모듈: 초기화, 통신, 동작, 피드백. 앱 명령을 해석해 서보별 PWM으로 바꾼다(글 서술).
- 서보: YF-6125MG 3개(25 kg·cm), MG996R 3개(13 kg·cm).
- 피드백: 위치 센서와 리미트 스위치를 언급하나 종류는 미기재. IMU·토크 센서는 제안 단계.

## 검증·재현성
- 조립 후 서보별 영점·오프셋을 저장하는 보정을 거치자 관절당 편차가 1° 미만, 앱-서보 지연은 평균 약 40 ms(글 서술, 측정 방법 unverified).

## 한계·위험
- 개루프 서보 위치 지령이라 부하 변화에 따른 오차 보정이 없다. 글에서 YF-6125MG를 연속 회전형이라 서술하는 점은 위치 제어와 맞지 않아 보이며 확인하지 못했다(unverified).
- 전원 구성 미기재.

## 재사용 메모
- 내 판단: "명령 해석 → 관절별 PWM → 영점·오프셋 보정 테이블"의 3단 구조는 서보 PWM IP 여러 채널과 오프셋 레지스터로 옮기기 쉽다.
- 개조: 옮길 부분은 관절별 영점·오프셋 레지스터, 명령 프로토콜의 틀(TCP 대신 UART 브리지). 못 옮길 부분은 Wi-Fi 스택과 앱. 서보 6채널은 Basys3 Pmod 핀 수로 가능하나 서보 전원은 분리해야 한다(내 판단, 전원 근거 자료 없음).
