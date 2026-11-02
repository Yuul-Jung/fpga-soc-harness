---
name: tees-isie-2017-compass-search-self-tuning-pid-dc-drive
url: https://research.tees.ac.uk/en/publications/hardwaresoftware-co-design-techniques-for-compass-search-self-tun/
source_type: paper
vendor: neutral
board: [NI RIO (모델 미명시)]
fit_basys3: needs-port
cpu: unverified: 소프트코어 여부 미서술
language: LabVIEW-FPGA
tools: [LabVIEW FPGA]
bus: unverified
peripherals: [actuator-servo, sensor]
stage: T4
license: 저작권 표기 있음(전권 보유, 오픈 라이선스 없음)
stats: {published: 2017}
doc_language: en
verification: L2
checked_at: 2026-11-03
status: 저장소 서지 페이지(초록)만 열람. 본문 접근 없음
sources: [https://research.tees.ac.uk/en/publications/hardwaresoftware-co-design-techniques-for-compass-search-self-tun/]
unverified: 본문 미열람 - FPGA 소자, HW/SW 분할, 자원·타이밍, 탐색 단계 크기, 튜닝 시간, 코드 공개
---

## 요약
ISIE 2017(에든버러)에 실린 Teesside 대학 논문. DC 모터 구동용 자가 튜닝 PID를 HW/SW 공동 설계로 구현하고, 폐루프 임펄스 응답을 이상 응답과 맞추도록 compass 직접 탐색으로 이득을 조정한다(초록 기준).

## 구조
- 두 가지 튜닝 구조를 구현했다고 서술. 여기에 가진 신호를 넣고 폐루프 응답을 측정해 목표 응답과 비교한다(초록 서술).
- NI RIO 하드웨어 + LabVIEW-FPGA 도구로 온라인 튜닝, 위치 제어 DC 모터에서 검증(초록).

## 검증·재현성
- 정량 결과, 자원, 타이밍은 본문 미열람으로 unverified.

## 한계·위험
- 초록 수준이며 LabVIEW 종속 구현이라 RTL이 공개될지 불명. 전권 보유 표기라 반입 불가로 취급.

## 재사용 메모
- 내 판단: 모델이 필요 없는 탐색형 튜닝은 "응답 오차 비용 계산(FPGA) + 후보 이득 갱신 규칙(CPU)" 분업으로 옮기기 쉽다. 탐색 한 번이 시험 한 번이라 시간이 길어지는 점은 확인 필요.
- 개조: CPU 종속 없음(초록 기준). 비용 함수 누적기(오차 제곱합)를 IP 표준 레지스터로 노출하고, 이득 후보 갱신과 시험 시나리오 순서는 MicroBlaze V 소프트웨어가 맡는 구성(내 판단). 본문 확인 전에는 구현 세부를 가정하지 않는다.
