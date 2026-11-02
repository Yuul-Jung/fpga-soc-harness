---
name: kmitl-iccas-2003-auto-tune-digital-pid-fpga
url: https://koreascience.kr/article/CFKO200333239336700.pdf
source_type: paper
vendor: amd
board: [Spartan-2 XC2S50-5TQ144 (보드명 미명시)]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified: 소스 언어 미서술(ModelSim XE 시뮬레이션 사용)
tools: [ModelSim XE]
bus: native
peripherals: [sensor, actuator-servo, debug]
stage: T4
license: unknown
stats: {published: 2003}
doc_language: en
verification: L3
checked_at: 2026-11-03
status: 본문 PDF 전체를 열람함. 일부 수식이 garbled로 보여 계수 정의는 확정하지 않음. 코드 공개 여부 unverified
sources: [https://koreascience.kr/article/CFKO200333239336700.pdf]
unverified: 클럭, 자원 수치(LUT/게이트), 소스 코드 공개, 비트폭 외 내부 고정소수점 처리
---

## 요약
ICCAS 2003(경주)에 실린 태국 KMITL 공학부 논문. 디지털 PID 연산기와 자동 튜닝을 한 FPGA(XC2S50)에 넣고, 개루프 계단 응답에서 FOPDT 모델을 추정해 Dahlin 방법으로 이득을 정한다. 오븐 온도 제어로 시험했다.

## 구조
- 튜닝 방식: 릴레이 피드백이 아니라 개루프 단위 계단 시험. FOPDT의 K, τ, 지연 t0를 추정 후 Dahlin 방법으로 PID/PI 계산. t0 > τ/4이면 PID, 아니면 PI 선택(원문 서술). 목표 과도 오버슈트는 5% 이하.
- 조기 종료: 뉴턴 분할차분 외삽으로 정상값을 미리 추정해 완전 정착을 기다리지 않는다(원문 서술).
- 연산기: 속도형(velocity form) 이산 PID. 입력 SP/PV 10비트, Kp/Ki/Kd 8비트, 출력 12비트. 공유 연산기(20비트 3입력 가산기 1, 10비트 가산기 1, 10비트 곱셈기 2)를 상태기계가 순차 사용.
- 입출력: ADC 10비트, DAC 12비트, 4~20 mA 출력으로 위상 제어 히터 구동.

## 검증·재현성
- ModelSim XE로 고정 이득 단계 응답을 확인하고, 오븐 온도 두 가지 계단(→60 °C, 50→70 °C)을 시험. 오버슈트 없음, 정착 약 25초(원문 수치).
- 자원·클럭은 보고되지 않음. 비교 데이터 없음.

## 한계·위험
- 시험 대상이 느린 온도 공정 하나뿐. 외삽 오차는 정량화되지 않았다.
- 곱셈기 2개를 시분할하므로 모터 속도 루프처럼 빠른 공정에는 샘플링 주기 검토가 필요(내 판단).
- 라이선스·코드 없음: 코드 반입 대상이 아니라 사양 참고용.

## 재사용 메모
- 내 판단: 튜닝 알고리즘이 "계단 시험 → 3개 파라미터 추정 → 이득 계산"이라 하드웨어 FSM과 소프트웨어(MicroBlaze V) 분업 경계가 분명하다. 계단 캡처는 FSM, 이득 계산은 CPU로 두는 구성이 자연스럽다.
- 개조: 이 설계는 CPU가 없는 FSM이라 CPU 종속 부분이 없다. PID 연산기를 IP 표준 AXI4-Lite 래퍼(Kp/Ki/Kd 레지스터, SP/PV, 출력, 샘플 트리거)로 만들고, 계단 응답 샘플 캡처 버퍼를 레지스터/BRAM으로 두어 MicroBlaze V가 모델 추정과 이득 쓰기를 맡는 구성으로 옮길 수 있다(내 판단). 모터 속도 루프용으로는 샘플 주기 확인이 필요.
