---
name: element14-eoi-blog3-custom-ip-pwm
url: https://community.element14.com/challenges-projects/design-challenges/eye-on-intelligence-challenge/b/blog/posts/blog-3---custom-ip-implementation
source_type: article
vendor: amd
board: [Zynq-7000 계열 Digilent 보드 (모델 미명시)]
fit_basys3: needs-port
cpu: Zynq PS (ARM)
language: C
tools: [Vivado, Vitis Unified IDE]
bus: AXI4-Lite
peripherals: [actuator-servo, PWM-IP, GPIO]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://community.element14.com/challenges-projects/design-challenges/eye-on-intelligence-challenge/b/blog/posts/blog-3---custom-ip-implementation]
unverified: 정확한 보드 모델, Vivado/Vitis 버전, 게시일, RTL 원문(글에 PWM 동작 서술만 있고 소스는 미확인), 라이선스
---

## 요약
element14 설계 챌린지 블로그의 세 번째 글. Vivado "새 AXI4 주변장치 만들기" 마법사로 PWM 생성 IP를 만들고, 인스턴스 3개를 서로 다른 주파수·듀티로 구동하며 Vitis C 드라이버로 제어한다.

## 구조
- 인터페이스: AXI4-Lite slave, 데이터 32비트, 마법사 최소치인 레지스터 4칸 사용 (글 서술).
- 레지스터(글 서술): 오프셋 0 PERIOD(읽기/쓰기), 4 COMPARATOR(읽기/쓰기), COUNTER는 읽기 전용(오프셋은 글에 명시 없음, `unverified`). 기본 베이스 0x43C00000에서 인스턴스마다 다른 베이스.
- 동작: 카운터가 PERIOD에서 리셋되고, COMPARATOR가 카운터보다 크면 pwm 출력이 high.
- 소프트웨어: `PWMGen.c/.h` 세 함수 — 주파수(PERIOD = FCPU / f), 듀티(COMPARATOR = 비율 × PERIOD), 시간(COMPARATOR = 시간 × FCPU), FCPU 기본 100 MHz. 예시는 1 Hz 50%, 50 Hz 1 ms(서보 형태), 1 kHz 75%.

## 검증·재현성
- 보드에서 LED·Arduino 헤더 핀으로 확인한 서술. 테스트벤치·CI·자원 수치는 글에 없음.

## 한계·위험
- 글이 적은 한계: 정수 나눗셈이라 주파수가 이산값, PERIOD는 32비트 이내, PWM_n(반전) 출력은 수동 XDC 필요, Vitis에서 XSA만 바꾸면 갱신이 안 되어 비트스트림을 다시 가져와야 하는 버그.
- Zynq PS 기준이라 CPU·베이스 주소(0x43C0_0000 대)가 우리 동결 맵과 다르다.

## 재사용 메모
- 내 판단: PERIOD/COMPARATOR/COUNTER 3레지스터 PWM은 모터 사다리 입문(서보·DC 모터)의 가장 작은 IP 사양 근거다. 서보 신호(50 Hz, 1 ms 펄스)가 같은 IP로 나온다는 점이 쓸모 있다.
- 개조: 레지스터 배치와 PWM 카운터 FSM만 취해 IP 표준 래퍼로 새로 쓰고 `free_slots`에 한 칸 제안한다. Zynq 베이스 주소와 PS 전용 부분은 버린다. 마법사 템플릿 코드는 가져오지 않는다. 모터 전원은 보드와 분리(전기 규칙).
