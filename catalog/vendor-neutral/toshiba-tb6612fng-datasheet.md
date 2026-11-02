---
name: toshiba-tb6612fng-datasheet
url: https://faculty-web.msoe.edu/johnsontimoj/Common/FILES/TB6612FNG.pdf
source_type: report
vendor: neutral
board: [없음 (모듈 데이터시트)]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified: 데이터시트에 HDL 없음
tools: []
bus: none
peripherals: [actuator-servo]
stage: T2
license: 제조사 저작물 (링크·요약만, 반입 없음)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://faculty-web.msoe.edu/johnsontimoj/Common/FILES/TB6612FNG.pdf]
---

## 요약
Toshiba TB6612FNG 듀얼 H-브리지 드라이버 데이터시트(대학 서버 사본, 원본 제조사 문서와의 동일성은 unverified). 아두이노 모듈 시장에서 L298N의 대안으로 쓰이며, 채널당 IN1·IN2·PWM 3선으로 방향·제동·정지를 정한다. FPGA에서 직접 구동하기 쉬운 3.3V 논리 호환 입력이 핵심이다.

## 구조
- 전원 두 계통: VM(모터) 4.5~13.5V 동작(절대최대 15V, 핀 표에는 2.5V 하한이 따로 적혀 본문 내 불일치), Vcc(논리) 2.7~5.5V.
- 입력 문턱: High는 Vcc×0.7 이상, Low는 Vcc×0.3 이하. 입력 핀(IN1, IN2, PWM, STBY)에 약 200kΩ 내부 풀다운. Vcc를 3.3V로 두면 FPGA 3.3V 출력과 직결 가능 (내 판단: Vcc를 보드 3.3V에 묶는 조건에서만).
- 진리표: STBY=L은 출력 Hi-Z. IN1·IN2 같은 값 H/H는 쇼트 브레이크. IN1/IN2 서로 다르고 PWM=H이면 정회전/역회전, PWM=L이면 쇼트 브레이크. L/L+PWM=H는 정지(Hi-Z).
- PWM 최대 100kHz. 채널당 연속 1.2A(평균), 피크 3.2A(듀티 20% 이하 조건). 열 차단 약 175°C(히스테리시스 20°C 설계값).
- 역기전력: 정지·감속·반전 시 모터 전원 쪽으로 전류가 되돌아올 수 있고, 전원의 흡수 능력이 작으면 정격을 넘을 수 있다고 경고.

## 검증·재현성
- HDL·테스트벤치 없음(데이터시트). 자원·타이밍: 해당 없음.

## 한계·위험
- 사본 호스팅이라 최신 개정 여부 unverified. 과전류 보호·오류 출력 핀 서술은 열람 범위에서 확인하지 못함 (unverified: 요약 범위 밖).

## 재사용 메모
- 내 판단: 방향 2비트 + PWM 1비트 + STBY 구성은 AXI4-Lite 레지스터(모드 필드, 듀티, 활성화)로 그대로 옮기기 쉽다. 브레이크/코스트/정·역 4상태를 레지스터 모드 필드로 노출하면 시험 가능.
- 내 판단: 모터 전원(VM)은 보드와 분리하고 GND만 공통, 모터 전원 쪽 벌크 커패시터로 역기전력 완충 (config/project_profile.json 전기 규칙과 일치).
- 개조: 해당 없음 (CPU 비종속 부품 자료). 모터 IP의 출력 로직은 이 진리표를 시험 모델로 쓸 수 있음.
