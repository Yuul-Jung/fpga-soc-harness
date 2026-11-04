---
name: shashankr-basys3-fpga-robotic-arm
url: https://shashankr.is-a.dev/projects/cmahveq6m0000iw0wfqurjj1q
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [XADC, actuator-servo, potentiometer]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://shashankr.is-a.dev/projects/cmahveq6m0000iw0wfqurjj1q]
unverified: 모듈 구성, 서보 펄스 폭 범위, 소스 저장소, 측정 결과(본문에 없음, 링크된 전체 보고서는 열람하지 않음), 서보 모델·전원
---

## 요약
Basys3의 내장 XADC로 가변저항(전위차계) 전압을 읽어 서보 각도를 실시간으로 바꾸는 소형 "로봇 팔" 프로젝트 소개 페이지. Verilog와 Vivado를 썼다고 적혀 있다.

## 구조
- 신호 흐름: 가변저항 → XADC → 디지털 값 → 서보 각도 (페이지에 기술된 범위). 조이스틱이 아니라 가변저항이다.
- 다관절 팔이나 센서·서보 추가는 확장 가능성으로만 언급됨.

## 검증·재현성
- 테스트벤치, 자원, 타이밍 기록 없음. 소스 공개 여부 unverified.

## 한계·위험
- 페이지 본문이 짧아 정확도, 지연, 잡음 처리, 서보 범위가 적혀 있지 않다. "부드럽다"는 주장에 정량 근거 없음.
- 라이선스 불명. 코드는 가져오지 않는다.

## 재사용 메모
- 내 판단: XADC 값 → 서보 위치 매핑이라는 가장 단순한 입력-출력 조합의 존재 확인용. 구조 근거는 약하다.
- 개조: XADC는 AXI4-Lite IP 표준 레지스터(채널 값 읽기)로 감싸고, 서보 위치 레지스터에 쓰는 소프트웨어 루프로 분리하면 MicroBlaze V 기준 시험 모델이 된다. XADC 입력 범위(0~1 V)는 공식 문서로 확인 필요.
