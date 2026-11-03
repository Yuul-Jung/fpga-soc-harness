---
name: st-community-tim1-complementary-no-deadtime
url: https://community.st.com/t5/stm32-mcus-motor-control/i-am-able-to-generate-a-complementary-pwm-signal-however-due-to/td-p/194047
source_type: article
vendor: neutral
board: [unverified: MCU 모델 미기재]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C
tools: [unverified: 툴체인 미기재]
bus: none
peripherals: [actuator-servo]
stage: T2
license: unknown (포럼 글)
stats: {last_update: 2021-07-23}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.st.com/t5/stm32-mcus-motor-control/i-am-able-to-generate-a-complementary-pwm-signal-however-due-to/td-p/194047]
---
unverified: source_rev — 포럼 글이라 해당 없음

## 요약
TIM1 상보 PWM은 나오는데 BDTR에 설정한 데드타임이 출력에 나타나지 않는다는 질문 글이다. 작성자가 스스로 원인을 추정했으나 해결 계산식은 글에 없다(글 서술, 2021-07-23).

## 구조
- 설정: PSC와 ARR(PWM_STEPS-1)로 주파수 결정, 채널 1·2 PWM 모드 1, 상보 출력(CC1NE, CC2NE) 활성, 채널 3은 ADC 트리거용, BDTR에 MOE + DTGMULT + DTG 값 (글 서술).
- 작성자의 추정: 데드타임 생성 클럭 tDTG가 "FOSC/PSC"가 아니라 더 높은 주파수 기준인 듯하다. 정확한 식은 답이 없음.
- 답변자 없음, 스레드 닫힘.

## 검증·재현성
- 재현 코드 일부만 게시, 측정값 없음. unverified: 원인 확정.

## 한계·위험
- 해결 미확정이라 사실로 쓰면 안 되는 글. 같은 주제의 위 글과 클럭 기준이 다르다는 점만 교훈이다.

## 재사용 메모
- 내 판단: 교훈은 "데드타임 단위가 어느 클럭인지 문서화하지 않으면 값이 어긋난다"이다. FPGA IP에서는 데드타임 단위를 시스템 클럭 1주기로 고정하고 레지스터 설명에 쓴다.
- 개조: 옮길 부분은 ADC 트리거용 별도 채널을 PWM 중심에 두는 구조(전류 샘플 시점) → 샘플 펄스 출력 신호로 자체 설계. 못 옮길 부분은 DTGMULT 인코딩 등 MCU 전용 레지스터. 시험 환경: 데드타임 폭을 클럭 수로 측정하는 TB.
- 관련: [[deepbluembedded-stm32-complementary-pwm-dead-time]].
