---
name: columbia-4840-dc-motor-controller
url: https://www.cs.columbia.edu/~sedwards/classes/2022/4840-spring/reports/DC-Motor-Controller-report.pdf
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: 미확인 (HPS 언급 없음, C 소프트웨어가 구동)
language: SystemVerilog, C, MATLAB/Simulink
tools: [Quartus, Platform Designer, MATLAB/Simulink]
bus: unverified: 보고서가 버스 이름을 밝히지 않음 (Platform Designer 주변장치)
peripherals: [actuator-servo, sensor]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://www.cs.columbia.edu/~sedwards/classes/2022/4840-spring/reports/DC-Motor-Controller-report.pdf]
---

## 요약
Columbia CSEE 4840(2022 봄) 학생 2인 보고서. DE1-SoC에서 L298N H-브리지와 엔코더 달린 PMDC 기어모터를 PWM으로 구동하고, 전류(내부 루프)와 속도(외부 루프) 2단 PI 제어를 C로 돌린다. 하드웨어는 PWM·ADC·7세그, 제어는 소프트웨어로 나눴다. 모터 제어 사다리(A 트랙)의 중급 사례.

## 구조
- 하드웨어(SystemVerilog): ADC.sv(LTC2308, SPI형 12비트 8채널), hex7seg.sv, pwm.sv. 소프트웨어(C): fpga_main.c, pi_controller, pwm 드라이버. 설계 검증용 MATLAB/Simulink 모델 2종(연속, 이산화).
- PWM: 25 kHz, 50 MHz 클럭 기준 한 주기 2000 카운트, 듀티 지령 0~2000(11비트, 16비트 쓰기 포트로 전달). 제어기 출력 -12~+12 V를 듀티와 방향으로 변환.
- 엔코더: 회전당 7펄스, 3.3 V 논리, GPIO 입력. 100 kHz로 센서 샘플링해 10 ms 창(100 Hz)마다 펄스 수를 보고하고 초기화. 최고 속도 5700 RPM에서 창당 약 7개, 설계 목표는 1000 RPM에서 창당 1개 이상(보고서 서술).
- 제어: 전류 PI(안티와인드업, 역기전력 전향 보상, 출력 제한)와 속도 PI. 영차 유지 이산화, 샘플링 100 kHz(Ts 10 µs). 속도 교차 주파수는 전류 교차의 1/5. 모터 파라미터(R 0.2 Ω, L 0.002 H 등)는 실측이 아닌 근사값.
- 사용자 입력: 스위치(활성화, 방향, 수동/자동 모드), 전위차계는 ADC로 읽음, GPIO로 ENA·IN1·IN2 구동.

## 검증·재현성
- 300 rad/s 계단 지령을 연속·Simulink·C 구현에서 비교(보고서 서술). 자원 사용, 타이밍, 레지스터 주소: unverified: 보고서에 없음.
- 소스 저장소 링크: unverified: 보고서에서 확인하지 못함 → 코드 열람 불가.

## 한계·위험
- 보고서가 밝힌 미완: ADC 값이 제어 루프에 연결되지 않았고 전류 되먹임이 완성되지 않음.
- L298N 출력 전압 강하 2 V(보고서 서술), 모터 전원 12 V 최대 → 보드와 전원 분리 필수.
- 라이선스 정보 없음 → unknown. 코드를 가져오는 재사용은 라이선스 확인 필요.

## 재사용 메모
- 내 판단: PWM 25 kHz에 2000 카운트(50 MHz 기준)라는 수치는 Basys3 100 MHz 클럭에서는 4000 카운트로 같은 주파수가 된다(내 계산). 듀지령 레지스터 폭 11비트는 AXI4-Lite 32비트 레지스터에 맞게 확장하기 쉽다.
- 내 판단: 엔코더 창 계수 방식(10 ms 창, 저속에서 창당 1~7 카운트)은 분해능이 낮다. A 트랙 IP에서는 창 카운트와 함께 마지막 에지 간격(주기 측정)을 같이 읽는 레지스터를 두면 저속 정밀도를 높일 수 있다.
- 개조: 다른 CPU(HPS 계열) 자료이므로 PWM/엔코더 레지스터와 FSM만 IP 표준 AXI4-Lite 래퍼로 옮기고, 100 kHz 전류 루프는 MicroBlaze V 소프트웨어로는 부담일 수 있어 PI를 하드웨어 FSM으로 옮길지 별도 검토(내 판단). HPS 전용 드라이버 부분은 옮길 수 없다.
