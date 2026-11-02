---
name: controleng-relay-method-automates-pid-loop-tuning
url: https://www.controleng.com/relay-method-automates-pid-loop-tuning
source_type: article
vendor: neutral
board: [none]
fit_basys3: unknown
cpu: none
language: none
tools: []
bus: none
peripherals: [sensor, actuator-servo]
stage: T4
license: unknown
stats: {published: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
status: 기사 본문 한 페이지를 열람함. 핵심 공식 하나는 원문에서 잘려 있어 이 카드는 표기만 옮김(§6.6)
sources: [https://www.controleng.com/relay-method-automates-pid-loop-tuning]
unverified: 게재일, 히스테리시스 처리(기사에 언급 없음), FPGA 구현 예
---

## 요약
Control Engineering의 기사로, 릴레이(Åström-Hägglund) 방식이 Ziegler-Nichols 한계 이득 시험을 자동화하는 원리를 설명한다. 공정 변수를 설정값 둘레의 한계 사이클로 묶어 궁극 주기와 이득을 읽고 PID를 정한다.

## 구조
- 시험 절차: PID 항을 끈 상태에서 제어 출력을 작은 고정 진폭 a의 양/음 계단으로 번갈아 주고, 공정 변수가 설정값을 교차할 때 부호를 뒤집는다(원문 서술).
- 측정: 궁극 주기 T_U는 출력 구형파의 주기에서, 궁극 이득은 릴레이 진폭 a와 공정 변수 진폭 b에서 얻는다. 기사 표기는 잘려 있고, 일반적으로 알려진 형태는 4a/(πb)임(내 판단, 원문에서 확정 못 함).
- 튜닝 규칙(원문 표기): P = 0.6·P_U, T_I = 0.5·T_U, T_D = 0.125·T_U.

## 검증·재현성
- 기사는 개념 설명이며 코드·실험 데이터 없음.

## 한계·위험
- 기사가 밝힌 한계: 적분/미분 항이 없는 제어기, 본래 진동하는 공정, 적분 공정(레벨 제어), 지연이 아주 작거나 시정수보다 훨씬 큰 경우는 규칙이 달라진다. 한계 사이클은 정현파가 아니라 근사다.
- 잡음: 진폭이 너무 작으면 측정 잡음과 구분되지 않는다. 기사가 히스테리시스 밴드를 다루지 않는 점은 설계 시 별도로 확인해야 한다.

## 재사용 메모
- 내 판단: 릴레이 시험은 교차 검출, 부호 반전, 주기·피크 측정 세 부분뿐이라 곱셈 없이 FSM으로 만들 수 있고, 이득 계산(나눗셈·곱셈)만 CPU 소프트웨어로 두는 분업이 맞다. 시뮬레이션에서는 1차+지연 모터 모델을 붙인 폐루프 테스트벤치로 한계 사이클 주기를 자체 점검할 수 있다.
- 개조: CPU 종속 부분 없음(알고리즘 설명). IP 표준 레지스터로 relay 진폭, 히스테리시스(잡음 대역), 시험 시작/상태, 측정 주기·진폭 레지스터를 두고 MicroBlaze V가 계산한 이득을 PID IP에 쓰는 구조로 옮길 수 있다(내 판단). 모터 전원 분리·한계 사이클 중 출력 클램프를 안전장치로 넣어야 한다.
