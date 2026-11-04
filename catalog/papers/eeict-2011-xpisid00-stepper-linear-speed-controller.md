---
name: eeict-2011-xpisid00-stepper-linear-speed-controller
url: https://www.fekt.vut.cz/conf/EEICT/archiv/sborniky/EEICT_2011_sbornik/03-Doktorske%20projekty/03-Kybernetika%20a%20automatizace/10-xpisid00.pdf
source_type: paper
vendor: amd
board: [Avnet Spartan-3A Evaluation Kit (XC3S400A)]
fit_basys3: needs-port
cpu: MicroBlaze
language: VHDL, C
tools: [unverified: 본문 요약에 도구 버전 없음]
bus: PLB
peripherals: [actuator-servo]
stage: T4
license: unknown
stats: {pages: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://www.fekt.vut.cz/conf/EEICT/archiv/sborniky/EEICT_2011_sbornik/03-Doktorske%20projekty/03-Kybernetika%20a%20automatizace/10-xpisid00.pdf]
---

## 요약
EEICT 2011 학회 논문으로, 스테퍼 모터의 선형 가감속 속도 프로파일을 MicroBlaze용 PLB 주변장치로 구현한 사례다. 프로파일 계산 중 무거운 부분은 소프트웨어 드라이버가 시작 전에 처리하고, 하드웨어는 FSM으로 펄스만 만든다.

## 구조
- 소프트웨어(C)가 시작 전 첫 스텝 간 지연과 감속 시작 스텝을 부동소수점으로 계산한다 (논문 서술).
- 하드웨어(VHDL) FSM은 정지, 가속, 등속, 감속 4상태이며, 모션이 시작되면 CPU 개입 없이 돈다 (논문 서술).
- 스텝 간 지연의 제곱근 항을 테일러 급수로 줄여 재귀식 c_n = c_(n-1) − 2c_(n-1)/(4n+1) 형태로 갱신한다. 나눗셈은 최대 33클럭 걸리는 CORDIC 계열 분주기로 처리한다.
- 마이크로스텝: 기준 타이머를 마이크로스텝 인덱스 테이블 값과 비교해 PWM을 만들고 스텝 카운터로 권선에 배분한다.
- 레지스터 맵·포트 폭: unverified: 요약 열람에 상세 없음.

## 검증·재현성
- 50MHz에서 기준 타이머 최소 주기 0.68µs, 400스텝/회전 모터 기준 최대 약 23,100 rad/s로 서술(설계상 수치이며 실측 아님).
- 자원: MicroBlaze가 LUT 47%, 스테퍼 컨트롤러 1개당 19% (XC3S400A). 컨트롤러 2개 + MicroBlaze가 들어간다고 서술.
- 모터 실측 응답 그래프: unverified: 설계 수준 타이밍만 보고됨.

## 한계·위험
- 라이선스 unknown. 코드는 가져오지 않는다.
- 부동소수점 계산을 CPU 소프트웨어에 의존하므로 MicroBlaze V에서는 FPU 유무 확인 필요 (내 판단).
- PLB는 구세대 버스라 그대로 쓸 수 없다.

## 재사용 메모
- 내 판단: "CPU가 시작 파라미터(초기 지연, 감속 시작점)를 계산하고 FSM이 실행"하는 분업은 AXI4-Lite 레지스터 몇 개로 옮기기 쉽고, 시뮬레이션 테스트벤치에서 FSM 단독 시험이 가능하다.
- 내 판단: 스텝 지연 갱신에 쓰는 나눗셈은 Basys3 DSP로 정수 근사(아래 stepmotion-vp-steps-per-time 방식)로 대체하면 33클럭 분주기가 필요 없다.
- 개조: PLB 인터페이스를 AXI4-Lite 래퍼(IP 표준)로 교체. FSM과 마이크로스텝 테이블 비교 로직은 그대로 옮길 수 있고, 소프트웨어 드라이버는 `cpu_irq_*.c`와 무관한 CPU 비종속 코드로 둔다.
