---
name: urjc-tfg-2018-fpga-balancing-robot
url: https://gsyc.urjc.es/jmplaza/students/tfg-fpgas-balancing_robot-juan_ordo%c3%b1ez-2018.pdf
source_type: paper
vendor: lattice
board: [IceZum Alhambra (iCE40HX1K), IceZum Alhambra II]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [IceStudio, IceStorm]
bus: none
peripherals: [sensor, actuator-servo, comm-uart]
stage: T4
license: unknown
stats: {published: 2018}
doc_language: en
verification: L2
checked_at: 2026-11-02
status: 본문 앞부분만 열람(3장 중간까지 잘림, 4장 결과 미열람)
sources: [https://gsyc.urjc.es/jmplaza/students/tfg-fpgas-balancing_robot-juan_ordo%c3%b1ez-2018.pdf]
unverified: 정량 결과, 4장, 라이선스, PWM 해상도
---

## 요약
URJC 학사 졸업 프로젝트(TFG, 2018). iCE40 FPGA에 PD 제어와 PWM을 구현해 2륜 균형 로봇을 만들었다. IMU 읽기와 센서 융합은 Arduino Nano가 MPU6050의 DMP로 처리한다.

## 구조
- Arduino → FPGA는 16200 baud 단방향 직렬 + 각도 부호 핀. FPGA: 수신 FSM(IDLE/START/DATA/STOP), 바이트 정렬, P·D 모듈, PWM(12 MHz 카운터 비교).
- 모터 드라이버 MC33926. 필터 이론(상보, 칼만)은 서술하나 구현에는 안 씀. 총 시제품 비용 약 240.45 EUR(문서 기재).

## 검증·재현성
- 동작한다고 서술, 영상 링크만 있고 정량 수치는 확인 못 함.

## 한계·위험
- 1K 메모리가 설계 규모를 제한, 적분항 없음, 직렬 링크 단방향.

## 재사용 메모
- 내 판단: "FPGA는 제어·PWM만, 센서 융합은 외부"라는 최소 분업 사례로, 우리 사다리에서 IMU 필터 IP를 만들기 전 1단계(쉬운 단계)에 해당한다.
- 개조: 단방향 직렬 수신 FSM은 IP 표준의 입력 레지스터로 대체하고, P·D에 적분과 클램프를 추가한 PID IP로 확장.
