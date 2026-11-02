---
name: arief-2026-ijecbe-artix7-36v-bldc-hall-sixstep
url: https://ijecbe.ui.ac.id/go/article/view/244
source_type: paper
vendor: amd
board: [Artix-7 (보드명 미기재)]
fit_basys3: needs-port
cpu: none(FSM)
language: unknown
tools: []
bus: none
peripherals: [actuator-servo, sensor]
stage: T2
license: CC-BY-4.0 (논문)
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-02
sources: [https://ijecbe.ui.ac.id/go/article/view/244]
---

## 요약
Artix-7 FPGA로 36V BLDC 모터를 홀센서 6스텝(사다리꼴) 방식으로 구동하고 하드웨어에서 검증한 2026년 논문(저자 Arief, Triputra, Udhiarto). 초록 페이지 기준이며 본문 PDF는 열람하지 않았다(검색 요약 기준, L2).

## 구조
- 홀센서 섹터 해독 + 양방향 상 순서, 20kHz 반송파 10비트 듀티 PWM(카운터 방식), 데드타임 보호 게이트 출력 논리.
- 측정(초록 기준): 속도가 듀티에 거의 선형, 전 듀티에서 약 2425 r/min, 공급 전류 약 0.49A, 최소 기동 듀티 2%.
- 데드타임 값, 게이트 드라이버, HDL 언어, 자원 사용: unverified: 초록에 없음.

## 검증·재현성
- 무부하 개루프 시험만 했고 폐루프 속도 제어와 부하 성능은 평가하지 않았다고 명시.

## 한계·위험
- 소스 코드·xdc 공개 여부 unverified. 본문 미열람이라 L2.

## 재사용 메모
- 내 판단: FOC 이전 단계(홀센서 6스텝 + 데드타임)의 기준 수치를 줄 수 있다. 사다리의 입문 칸을 채운다.
- 개조: 같은 Artix-7이므로 핀·클럭만 Basys3로 옮기면 된다. 홀센서 3입력은 3.3V Pmod로, 인버터 전원은 보드와 분리(GND 공통), 5V 이상 신호는 레벨 변환. 6스텝 FSM과 PWM은 IP 표준 레지스터(듀티, 방향, 홀 상태 읽기)로 새로 쓴다.
