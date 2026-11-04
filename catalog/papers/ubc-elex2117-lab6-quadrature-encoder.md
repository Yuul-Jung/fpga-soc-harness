---
name: ubc-elex2117-lab6-quadrature-encoder
url: https://people.ece.ubc.ca/edc/2117.fall2020/lab6.pdf
source_type: course
vendor: intel
board: [CPLD 보드 (4자리 7세그, 모델 미명시)]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [Quartus]
bus: none
peripherals: [sensor, rotary-encoder, 7seg]
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://people.ece.ubc.ca/edc/2117.fall2020/lab6.pdf]
unverified: 보드 정확한 모델, 동결 학기 외 개정, 라이선스
---

## 요약
ELEX 2117 2020년 가을 6번 실습. EN16-H 로터리 엔코더를 두 비트 기억 시퀀스 검출기(상태 기계)와 업다운 BCD 카운터로 읽어 7세그에 표시한다.

## 구조
- 신호: A/B 그레이 코드(시계 방향 11→01→00→10, 반대는 역순). 불가능 전이(00↔11, 01↔10)는 정상이라면 일어나지 않는다고 명시.
- 상태 기계: 밀리형 2비트 또는 무어형 4비트 중 선택. 입력 A, B, 출력 up(방향)과 enable(카운트 허용). 전이표와 출력표를 학생이 채운다.
- 카운터: 클럭 허용·리셋·up·carry·count[3..0] 포트의 BCD 카운터. 시계 방향 증가, 반시계 감소, 원위치 복귀 시 시작값 복원이 검수 기준.
- 전처리: 이전 실습의 디바운스 모듈을 스위치마다 적용, 1 ms 미만 펄스 제거. 별도 동기화기 서술 없음. 내부 풀업 사용.
- 4체배: 문서에 x1/x2/x4 용어는 없고 24 디텐트가 96 스텝에 대응한다는 수치에서 4체배로 읽힘 (내 추론).

## 검증·재현성
- 테스트벤치·시뮬레이션은 요구하지 않고, 면박 영상(시계 100 이상 증가, 반시계 200 이상 감소, 복귀)으로 평가. 실행하지 않았다.

## 한계·위험
- 시뮬레이션 기반 자체 점검 방법이 없음 → 하네스 CI에서 보완할 부분 (내 판단).
- 강의 자료라 일부 모듈(debounce.sv, BCD 카운터)은 이전 실습 것으로 문서에 없음. 라이선스·재배포 조건 미기재.

## 재사용 메모
- 내 판단: 전이표를 학생이 채우는 구조는 "불가능 전이를 오류로 센다"는 시험 항목(오류 카운터)으로 확장하기 좋다. 난이도 사다리의 1단(손 엔코더 표시)에 해당.
- 개조: 상태 기계의 전이표 아이디어만 취해 4체배 디코더를 자체 RTL로 쓰고, 불가능 전이 횟수 레지스터(읽기 전용)와 테스트벤치(정방향 N, 역방향 M, 불가능 전이 주입)를 더한다. 직접 동일 코드 복사 없음.
