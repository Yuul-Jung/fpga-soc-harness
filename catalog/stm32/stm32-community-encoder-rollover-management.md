---
name: stm32-community-encoder-rollover-management
url: https://community.st.com/stm32-mcus-products-25/quadrature-encoders-roll-over-management-109514
source_type: article
vendor: neutral
board: [STM32F407 (글 서술)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ARM Cortex-M4)
language: C
tools: [unverified: 툴체인 미기재]
bus: none
peripherals: [sensor]
stage: T1
license: unknown (포럼 글)
stats: {last_update: "unverified: 날짜 확인 못 함"}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://community.st.com/stm32-mcus-products-25/quadrature-encoders-roll-over-management-109514]
---
unverified: source_rev — 포럼 글이라 해당 없음

## 요약
STM32F407에서 5축 모터의 16비트 엔코더 타이머를 32비트 위치로 확장할 때 롤오버를 어떻게 다루느냐는 질문과 답변이다. 한 바퀴가 160,000 펄스인 고해상도 엔코더가 예다(글 서술). 확정된 해결은 없이 닫혔다.

## 구조
- 질문: TIMx_CR1의 읽기 전용 DIR 비트로 롤오버 방향을 알 수 있느냐. 이 질문에 대한 확정 답은 글에 없다.
- 답변 1: 오버플로 인터럽트에서 상위 워드를 증감하는 방식은 고해상도에서 불안정하다(위치가 0 근처일 때 인터럽트 순간 부호가 뒤집혀 방향이 틀릴 수 있음, 답변자 서술).
- 답변 2: 1 ms 간격(오버플로 주기당 10~20회) 또는 약 10 kHz 인터럽트로 읽고, 현재·이전 값의 상위 2비트(사분면)를 비교한다. 0→3이면 상위 워드 감소, 3→0이면 증가(답변자 서술).
- 부가: 32비트 타이머로 옮기는 방안 언급. 용어 논쟁(encoder vs decoder)은 본질과 무관.
- 링크된 선행 글은 죽은 링크로 열람 불가(글 서술).

## 검증·재현성
- 검증 코드·수치 없음. 사분면 방식의 정확도는 답변자 주장일 뿐 시험 결과는 글에 없다.

## 한계·위험
- 포럼 글이라 사실 수준은 "작성자·답변자 서술". 신뢰성 판정은 하지 않는다.

## 재사용 메모
- 내 판단: FPGA에서는 카운터를 처음부터 32비트로 만들면 이 문제가 사라진다. 대신 같은 원리가 고속 이벤트를 느리게 읽을 때 읽기 사이 변화량이 반 범위를 넘으면 안 된다는 샘플링 규칙으로 남는다. 이는 속도 측정용 창 계수에 그대로 적용된다.
- 개조: 옮길 부분은 사분면(상위 2비트) 비교로 부호 있는 델타를 만드는 아이디어와 "읽기 주기 ≤ 오버플로 주기/10" 제약을 IP 표준 문서 주의사항으로 쓰는 것. 못 옮길 부분은 STM32 타이머 오버플로 인터럽트 구조. 시험 환경은 롤오버 경계(0xFFFF→0, 0→0xFFFF) 주입 테스트벤치로 자체 작성.
- 관련: [[deepbluembedded-stm32-timer-encoder-mode]].
