---
name: ppisa-rpi-rt-control
url: https://github.com/ppisa/rpi-rt-control
source_type: repo
vendor: neutral
board: [RaspberryPi]
fit_basys3: needs-port
cpu: none(Linux RT + RTEMS)
language: C
tools: [PREEMPT_RT, RTEMS, Simulink, GCC]
bus: SPI
peripherals: [actuator-servo, sensor, comm-spi, comm-can]
stage: T2
license: unknown
stats: {stars: 19, commits: 55, last_update: 2024-01-01}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://github.com/ppisa/rpi-rt-control]
unverified: README 본문 열람 불가 (PROVENANCE_REQUIRED). 커널 버전·PREEMPT_RT 버전·라이선스·GPIO 핀 번호·cyclictest 결과 미확인.
---

## 요약 (검색 요약 기준)

체코 공과대학교(CVUT) Pavel Pisa 연구팀의 RPi 실시간 제어 실험 저장소. GNU/Linux(PREEMPT_RT)에서 제어 응용을 운영하는 교육 목적 예제 묶음이다. DC 서보, PMSM/BLDC, CAN/CANopen 2관절 팔까지 세 가지 모터 제어 사례를 포함한다.

## 구조

- **`kernel/modules/rpi_gpio_irc_module.c`**: 직교 엔코더(IRC) 소프트웨어 디코더 커널 드라이버. GPIO 핀에 연결된 센서 출력을 읽어 카운터 값을 반환.
- **`appl/rpi_simple_dc_servo`**: 사용자 공간 DC 모터 제어 애플리케이션. IRC 드라이버 사용, PWM + GPIO 방향 직접 접근.
- **`simulink/rpi_dc_motor_control.slx`**: DC 서보를 Simulink로 모델링. PWM 출력·IRC 읽기를 C S-함수로 구현. Lintarget 프로젝트 연동.
- **`simulink/rpi_pmsm_motor_control.slx`**: 3상 BLDC/PMSM 제어 Simulink 모델. Microsemi AGL125V5-VQ100 FPGA 칩을 SPI로 연결해 IRC 카운터·3채널 PWM·홀센서 전류 ADC를 처리.
- **`rtems/rpi_simple_dc_servo`**: DC 서보를 RTEMS RTOS로 포팅. IRC 처리를 RTEMS 드라이버로 구현.
- **관련 작업**: CAN/CANopen 스텝모터 2관절 팔 (SocketCAN, Simulink 모델).
- **언어**: C (커널 모듈, 사용자 공간), Simulink (.slx)
- **저장소 통계**: 19 stars, 7 watchers, 1 fork, 55 commits, 1 issue (내 열람: GitHub main page)

## 검증·재현성

- 테스트벤치 없음 (교육 실험 저장소)
- Simulink 코드 생성 경로(Lintarget)와 RTEMS 포팅 존재 → 실제 동작 확인 가능성 있음
- PMSM 모델의 SPI 연결 Microsemi FPGA 칩 사용은 특수 하드웨어 필요
- unverified: 커널 버전, PREEMPT_RT 패치 버전, 라이선스, 빌드 절차 (README 열람 불가)

## 한계·위험

- 라이선스 미확인: GitHub 메인 페이지에 라이선스 표시 없음 → 코드 재사용 전 확인 필요
- PMSM 경로는 Microsemi FPGA (AGL125V5-VQ100) 전용 하드웨어 의존
- 최신 갱신일 불명확 (GitHub stars 19개, 활동 낮음)
- README 직접 열람 미완료 (열람 권한 오류)

## 재사용 메모

- **S7 사다리 위치**: "전문" 단계 — 실제 직교 엔코더 커널 드라이버 + DC 서보 사용자 공간 애플리케이션 + PMSM Simulink 모델까지 다루는 완성형 사례.
- 개조:
  - `rpi_gpio_irc_module.c`의 직교 엔코더 디코더 FSM 구조 → Basys3 Verilog 직교 엔코더 카운터(mmio-pwm-qenc-checker 패키지의 `qenc_decoder.v`)와 동등한 역할. GPIO 인터럽트 방식을 AXI-Lite 레지스터 폴링/인터럽트 방식으로 변환 가능.
  - `rpi_simple_dc_servo`의 PWM 주기·방향 GPIO 패턴 → Basys3 AXI-PWM IP(`pwm_core.v`)의 duty cycle 레지스터 쓰기·방향 비트로 1:1 대응.
  - PMSM Simulink 경로의 SPI 연결 Microsemi FPGA → Basys3 Pmod SPI로 교체 불가(하드웨어 전용 IP). 단, "SPI로 외부 FPGA에 명령 전달" 아키텍처 패턴은 RPi4 PREEMPT_RT → Basys3 AXI-SPI Lite 연결로 옮길 수 있음(내 판단).
  - 옮길 수 없는 부분: RTEMS RTOS 경로 (Basys3는 Linux 없음), Microsemi FPGA 전용 IP.
