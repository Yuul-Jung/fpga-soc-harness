---
name: makiuto-stm32-foc-from-scratch
url: https://makiuto.github.io/p/field-oriented-control-foc-on-stm32-from-scratch-practical-bldc-motor-contr.html
source_type: article
vendor: neutral
board: [STM32F407 (글 서술; 보드명 미기재)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C
tools: [PlatformIO, FreeRTOS, STM32 HAL/LL]
bus: none
peripherals: [actuator-servo, sensor]
stage: T4
license: unknown (페이지 푸터 "BSD" 표기, 연결된 저장소 라이선스는 미확인 — 라이선스 확인 필요)
stats: {last_update: 2025-12-23}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://makiuto.github.io/p/field-oriented-control-foc-on-stm32-from-scratch-practical-bldc-motor-contr.html]
---
unverified: source_rev — 연결된 저장소(github.com/sirojudinMunir/stm32-FOC)는 열람하지 않음

## 요약
STM32F407로 BLDC 모터 FOC를 라이브러리 없이 구현하는 영상 챕터형 글이다(2025-12-23). 게이트 드라이버 DRV8302, 자기 엔코더 AS5047을 쓴다(글 서술). 본문에 수치가 없고 챕터 목록만 확인했다.

## 구조
- 챕터 제목에서 확인: 중앙 정렬 PWM, Clarke·Park 변환, 전류 센서와 전류 제어.
- 스택: PlatformIO, FreeRTOS, HAL과 LL.
- PWM 주파수, 데드타임, 제어 주기, 정현파 표: unverified: 글에 없음.

## 검증·재현성
- 측정·시험 자료 없음(unverified). L2 사유: 글은 목차 수준이라 구현 내용 열람 못 함.

## 한계·위험
- 영상 중심 글이라 텍스트만으로 사양 추출 불가. 저장소 라이선스 미확인이므로 코드 참조 금지.

## 재사용 메모
- 내 판단: FOC 학습 순서(중앙 정렬 PWM → 변환 → 전류 제어)는 모터 사다리 최상 단계의 챕터 구성 참고가 된다. 구현 사양은 저장소를 L3로 열람해야 얻을 수 있다.
- 개조: 옮길 부분은 챕터 순서와 Clarke/Park의 고정소수점 파이프라인화(자체 RTL, CORDIC 또는 표) . 못 옮길 부분은 FreeRTOS 태스크 구조와 MCU 타이머 연동. 근거: [[wangxuan95-fpga-foc]]가 FPGA 쪽 대응 사례.
