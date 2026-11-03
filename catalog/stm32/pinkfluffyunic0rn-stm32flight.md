---
name: pinkfluffyunic0rn-stm32flight
url: https://github.com/PinkFluffyUnic0rn/stm32flight
source_type: repo
vendor: neutral
board: [자작 FC 보드 2종: STM32F405RGT6, STM32H723VGT6]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M)
language: C
tools: [unverified: 빌드 도구는 README 첫 페이지에 없음]
bus: none
peripherals: [sensor, comm-uart, actuator-servo, debug]
stage: T4
license: GPL-3.0
stats: {stars: 9, commits: 421, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://github.com/PinkFluffyUnic0rn/stm32flight]
---
unverified: source_rev — 페이지에서 저장소 커밋 SHA가 보이지 않음. 코드·위키 미열람(메인 페이지만 읽음)이라 L2.

## 요약
STM32F405와 H723 두 보드용 오픈소스 드론 비행 제어기다. 자세·고도·위치까지 여러 안정화 모드를 지원한다고 소개한다. 루프 구조와 필터는 페이지에 없고 위키에 있다고 한다(미열람).

## 구조
- 센서: 두 보드 모두 ICM-42688-P(자이로·가속도), QMC5883L(지자기), DPS368(기압). H7 보드는 외부 LIS3MDL 추가(페이지 서술).
- 입출력: ELRS CRSF 수신기, Dshot-300/600 ESC 출력, MSP OSD, ELRS 텔레메트리, ESP8285를 통한 Wi-Fi 설정.
- 안정화 모드: 회전속도, 자세, 요, 가속도, 고도, 위치(GNSS) — 모드별 센서 조합이 표기됨.
- 루프 주기, PID 이득, 필터: unverified: 위키 미열람.

## 검증·재현성
- 빌드·테스트 방법, CI: unverified. H7 보드 회로도가 저장소에 있다고 한다.

## 한계·위험
- GPL-3.0이라 코드 조각을 옮기지 않고 사실(센서 구성, 모드 구성)만 사용한다(§16.3 G0).
- 별 9개, 포크 2개 규모의 개인 프로젝트다. 숫자는 사실 기록일 뿐 품질 판단 근거가 아니다.

## 재사용 메모
- 내 판단: "모드마다 센서 조합이 다르다"는 구성은 비행 제어기 캡스톤을 자세 모드 하나(자이로+가속도)에서 시작해 단계적으로 늘리는 사다리로 쓸 수 있다.
- 개조: 옮길 부분은 센서 계층(SPI IMU 읽기→표본 FIFO)과 모드별 제어 계층의 분리 구조, ESC용 고속 직렬 펄스 출력(Dshot) 대신 일반 PWM 출력 IP. 못 옮길 부분은 Cortex-M 코드 전체와 GNSS·지자기 융합. 위키 열람 후 루프 주기를 보강해야 한다.
