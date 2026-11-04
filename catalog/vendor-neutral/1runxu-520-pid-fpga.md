---
name: 1runxu-520-pid-fpga
url: https://github.com/1runxu/520-PID-FPGA
source_type: repo
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [unverified]
bus: none
peripherals: [sensor, actuator, comm-uart, quadrature-encoder, dc-motor, h-bridge]
stage: T4
license: unknown
stats: {commits: 3, stars: 0}
doc_language: en
verification: L2
checked_at: 2026-11-02
sources: [https://github.com/1runxu/520-PID-FPGA]
unverified: 보드, 도구, README 본문(요약 도구에 미포함), 커밋 SHA, 실제 동작 여부. 코드 열람은 페이지 요약 기준이라 L2
---

## 요약
50 MHz 클럭 가정의 Verilog 모터 속도 폐루프. 4체배 엔코더 → RPM 계산 → PID → PWM·H-브리지 출력, 측정 RPM은 UART(115200)로 송출한다.

## 구조 (페이지 요약 기준)
- 모듈: encoder_counter, speed_calc_uart, rpm_converter, motor_pid_controller(데드밴드·적분 제한·출력 제한), motor_speed_controller, motor_control, 최상위 encoder_speed_system.
- 수 형식: 속도·출력 16비트 부호, 이득 Q8(Kp 358≈1.4, Ki·Kd 8≈0.03), 곱셈 32비트. PWM 주기 2500틱.

## 검증·재현성
- 테스트벤치 없음. 실행하지 않았다.

## 한계·위험
- 내가 확인한 불일치 후보: 엔코더 타이머 250,000사이클(5 ms@50 MHz)인데 주석은 1초, DT_Q8과 주석 불일치, 출력 제한이 이전 값을 검사, 목표 RPM 하드코딩(160). 즉 동작 신뢰성은 낮다.
- 라이선스 미확인 → 사양만 사용.

## 재사용 메모
- 내 판단: 모듈 분해(엔코더/속도계산/PID/PWM 분리)는 참고할 만하고, 시간 상수 불일치는 "샘플 주기와 속도 창을 한 곳에서 파라미터화"해야 한다는 교훈이다.
- 개조: 자체 RTL로 샘플 주기·창 길이·Q 형식을 파라미터로 묶고, 데드밴드·적분 클램프 개념만 가져와 IP 표준 레지스터(목표값, 이득, 상태)로 노출한다. 자체 테스트벤치(모델 모터)를 추가한다.
