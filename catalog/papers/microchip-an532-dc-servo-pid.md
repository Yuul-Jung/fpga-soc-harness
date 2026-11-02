---
name: microchip-an532-dc-servo-pid
url: https://www.frba.utn.edu.ar/wp-content/uploads/2021/02/An532-DC-Servo-Motor-Control.pdf
source_type: report
vendor: neutral
board: [PIC17C42 + 16R8 PLD (MCU, 비FPGA)]
fit_basys3: needs-port
cpu: none(FSM)
language: C
tools: [PICMASTER 에뮬레이터]
bus: none
peripherals: [actuator, sensor, quadrature-encoder, h-bridge, pid]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://www.frba.utn.edu.ar/wp-content/uploads/2021/02/An532-DC-Servo-Motor-Control.pdf]
unverified: 원본 마이크로칩 게시본(이 URL은 대학 호스팅 사본), 재배포 라이선스
---

## 요약
1993년 앱노트(AN532, Teknic). MCU+PLD 직교 디코더+LMD18200 H-브리지로 DC 브러시 모터의 위치·속도 서보를 구성한다. FPGA 자료가 아니지만 고정소수점 PID의 스케일링, 포화 처리, 샘플 주기 설계를 설명한 고전 자료다(S1 인접 도메인).

## 구조
- 이득 16비트 부호 × 오차 → 32비트 누적, 2^SHIFTNUM(리스팅 4)로 스케일, 중간 16비트를 PWM 값으로 사용, 오버플로 시 포화.
- 양극 결과를 50% 듀티 기준 단극으로 변환하고 0%·100%에 닿지 않게 제한(LMD18200 요구).
- 서보 갱신은 PWM에 동기한 타이머 인터럽트. PWM 약 15.6 kHz를 N=16으로 나눠 표본화, 리스팅은 1 kHz. 서술상 수치 간 일부 불일치(문서 내 1.024 ms 등).
- 적분기는 출력 포화 중 정지(안티 와인드업). 미분은 오차 변화량.
- 튜닝: 에뮬레이터 트레이스를 엑셀로 그려 오버슈트·리플·응답을 보며 반복 조정. 이득은 표본 주기·부하에 종속.

## 검증·재현성
- 측정 정량 결과는 읽은 범위에 없음. 코드 실행 안 함.

## 한계·위험
- 16비트 타이머 한계: 엔코더율 < 약 32,767×표본주파수. 위치 레지스터 24비트, PWM 해상도 약 10비트. 궤적은 선형 속도 램프뿐.
- 1993년 설계로 FPGA 맥락 없음.

## 재사용 메모
- 내 판단: 포화 시 적분 정지, 듀티 상·하한 제한, PWM 동기 표본 같은 규칙은 FPGA PID IP 설계 체크리스트로 그대로 쓸 수 있다.
- 개조: MicroBlaze V에서 PID를 하드웨어 FSM으로 둘 때 같은 스케일링(32비트 누적 후 시프트)과 PWM 동기 트리거를 자체 RTL로 구현하고, 계단 응답 로그는 AXI4-Lite 레지스터 캡처로 대체한다.
