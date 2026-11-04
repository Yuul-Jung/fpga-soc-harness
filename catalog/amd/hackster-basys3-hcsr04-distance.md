---
name: hackster-basys3-hcsr04-distance
url: https://www.hackster.io/biswabhusan2190/distance-measurement-using-basys3-39a6c2
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: unknown
cpu: none(FSM)
language: unverified
tools: []
bus: none
peripherals: [sensor, HC-SR04, 7seg]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2026-11-02 /verify 재열람 시도 실패(WebFetch 권한 요청 미응답) — 이번 사이클 미대조, rechecked_at 미기록
sources: [https://www.hackster.io/biswabhusan2190/distance-measurement-using-basys3-39a6c2, https://forum.digilent.com/topic/5279-ultrasonic-module-hc-sr04-with-basys3/]
unverified: 소스 코드 링크 없음, Pmod 핀 배정, 레벨 변환 여부, HDL 언어(Verilog/VHDL 병기), 게시일
---

## 요약
Basys3로 HC-SR04 초음파 거리를 재어 7세그먼트에 표시하는 Hackster 글. 트리거 펄스, 에코 폭 측정, 거리 환산을 FSM으로 묶는다.

## 구조
- 10 μs 트리거 펄스를 만들고, Basys3 100 MHz 클럭으로 에코 구간을 센다(글 서술).
- FSM이 순서를 제어하고, 계산기가 클럭 수를 cm로 바꾼다(식은 글에 없음).
- 표시는 7세그 드라이버. 확장 계획으로 잡음 필터, VGA 표시, PC로 UART 전송을 언급.
- 보조 출처: Digilent 포럼에 같은 센서를 Basys3에서 쓰려는 질문이 있으나 보존본에 답변은 보이지 않았다. Pmod를 일반 GPIO로 쓸 수 있는지 묻는 내용까지만 확인.

## 검증·재현성
- 코드·테스트벤치·자원 수치 없음(글에 링크 없음).

## 한계·위험
- 레벨 문제: HC-SR04 echo는 일반적으로 5V 출력이라는 것이 내 판단이며, 이 글과 포럼 보존본 어디에도 레벨 변환 서술이 없다. 3.3V 보드 정책(§17.2)상 echo 분압/변환이 필요.

## 재사용 메모
- 내 판단: 사양이 가장 단순한 거리 센서 입문(T1) 근거. 코드가 없어 구조 설명용으로만 쓴다.
- 개조: 측정 FSM(트리거 10 μs → 에코 폭 카운트 → cm 환산)을 AXI4-Lite 래퍼의 TRIG/DIST/STATUS 레지스터로 옮긴다. 5V 모듈이므로 echo에 레벨 변환 부품을 BOM에 둔다.
