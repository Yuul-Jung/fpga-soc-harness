---
name: st-community-fdcan-8mbps-nucleo
url: https://community.st.com/t5/stm32-mcus/stm32-fdcan-running-at-8-mb-s-on-nucleo-boards/ta-p/730281
source_type: article
vendor: neutral
board: [NUCLEO-G0B1RE, NUCLEO-G474RE, NUCLEO-H563ZI, NUCLEO-H753ZI, NUCLEO-L552ZE-Q, NUCLEO-U575ZI-Q]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M)
language: C (ST HAL)
tools: [STM32CubeMX, STM32CubeProgrammer]
bus: CAN FD
peripherals: [comm-can]
stage: T2
license: unknown (커뮤니티 글, 코드 반입 대상 아님)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/t5/stm32-mcus/stm32-fdcan-running-at-8-mb-s-on-nucleo-boards/ta-p/730281]
---
unverified: source_rev — 커뮤니티 글이라 해당 없음. unverified: 게시일(페이지에서 확인 못 함)

## 요약
ST 커뮤니티 글로, Nucleo 6종에서 FDCAN을 중재 구간 1 Mb/s, 데이터 구간 8 Mb/s로 돌리는 설정을 보드별 클럭 표와 함께 정리했다. 핵심은 FDCAN 커널 클럭을 8의 배수로 잡아 데이터 구간 분주가 맞게 하는 것과, 8 Mb/s를 지원하는 트랜시버를 쓰는 것이다.

## 구조
- 값(글 서술): 대부분의 Nucleo에는 HSE 수정 발진기가 없어 ST-LINK의 MCO 출력을 HSE 바이패스로 쓴다. V3 ST-LINK의 기본 MCO는 HSI/2(8 MHz)라 CAN에는 부적합하므로 CubeProgrammer 등으로 바꿔야 한다고 서술.
- 값(글 서술): 보드별 HSE/FDCAN 클럭(MHz) — G0B1 8/64, G474 24/160, H563 6/192, H753 5/120, L552 8/104, U575 5/160.
- 값(글 서술, H753 120 MHz 예): 데이터 구간 prescaler 1, 15 tq(Seg1 8, Seg2 6, 샘플점 약 60%). 중재 구간 prescaler 1, 120 tq(Seg1 101, Seg2 18, 샘플점 약 85%).
- 값(글 서술): 트랜시버 MCP2562FD(8 Mb/s까지), 종단 저항 120 Ω 2개, 꼬임선 2 m 시험. G0B1·L552·U575는 솔더 브리지 수정이 필요.
- unverified: SJW와 트랜시버 지연 보상은 글이 다루지 않음.

## 검증·재현성
- 테스트벤치·CI 없음. 보드 수정과 CubeMX 설정 절차만 있고, 측정 파형이나 오류율은 본문에서 확인하지 못했다.

## 한계·위험
- 보드 개조(솔더 브리지)와 ST-LINK 펌웨어 설정이 선행되지 않으면 클럭이 들어오지 않는다.
- 트랜시버가 비트율을 못 따라가면 통신이 실패한다고 글이 경고한다.
- 라이선스 미표기 → 코드 반입 금지.

## 재사용 메모
- 내 판단: CAN FD는 이 하네스 카탈로그(wangxuan95-fpga-can, dpiegdon-verilog-can)가 다루는 고전 CAN과 비트 타이밍 모델이 다르다. 중재/데이터 구간을 따로 설정하는 구조는 FPGA CAN IP를 만들 때 BTR 레지스터를 두 벌로 나눠야 하는 근거가 된다.
- 개조: 옮길 부분은 "kernel clock / prescaler / tq 개수 / Seg1·Seg2로 비트 타이밍을 표현"하는 레지스터 설계와 샘플점 계산 표. 못 옮길 부분은 HAL 호출, MCO 클럭 공급(Basys3는 100 MHz 클럭에서 MMCM으로 만들면 됨), 트랜시버는 외부 부품이라 3.3 V 계열 확인 필요.
- 관련: [[wangxuan95-fpga-can]], [[dpiegdon-verilog-can]].
