---
name: opencores-roboarm-stepper
url: https://ftp.gwdg.de/pub/misc/opencores/cores/robotic/roboarm.shtml
source_type: repo
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [unverified: 페이지에 없음]
bus: none
peripherals: [actuator-servo]
stage: T1
license: unknown
stats: {last_update: 2001-04-25}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2001년 작성된 오래된 코어. 미러 페이지 기준
sources: [https://ftp.gwdg.de/pub/misc/opencores/cores/robotic/roboarm.shtml]
---

## 요약
OpenCores 미러에 올라 있는 로봇 팔용 스테퍼 구동 코어. 풀스텝과 하프스텝 시퀀스를 만들어 4선 권선 패턴을 내보내는 가장 단순한 형태의 FSM이다.

## 구조
- 최상위 ROBO_ARM: 입력 CLK, DIR_SEL, STOP, STEP_SEL, 출력 ARM_IN[3:0].
- 모듈: 풀스텝용 2비트 카운터와 패턴 매핑, 하프스텝용 3비트 카운터(8상태)와 패턴 매핑, 선택 MUX (페이지 서술).
- 스텝 간격은 외부 클럭 분주에 맡긴다. 페이지는 스텝 간 1~5ms를 요구한다고 적는다.
- 출력단은 달링턴 트랜지스터 4개 + 권선별 프리휠링 다이오드 (페이지 서술).

## 검증·재현성
- 테스트벤치, 리셋 입력, 합성 결과: 없음 (페이지에 언급 없음).

## 한계·위험
- 라이선스 unknown → 코드 반입 금지, 구조만 참고.
- 비표준 패키지(`work.std_arith`)에 의존해 이식성이 낮다 (페이지 서술).
- 리셋이 없어 시뮬레이션에서 초기값이 X가 된다 (내 판단).
- 가감속, 위치 지정, 원점 복귀 없음.

## 재사용 메모
- 내 판단: 28BYJ-48/ULN2003 같은 4선 단극 모터의 입문 단계(T1) 기준 설계로 쓸 수 있다. 자체 RTL에는 리셋과 `step_tick` 입력을 추가한다.
- 내 판단: 하프스텝 8상태 표는 데이터시트 값이므로 자체 RTL에서 새로 작성하고, 자체 점검 테스트벤치로 8상태 순서를 `!==`로 비교한다.
- 개조: 해당 없음 (CPU 비종속 자료). 레지스터는 DIR, STOP, MODE, DIV를 IP 표준 맵으로 제안.
