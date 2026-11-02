---
name: wangxuan95-fpga-foc
url: https://github.com/WangXuan95/FpOC
source_type: repo
vendor: neutral
board: [DE10-Nano (예시), Cyclone IV 데모]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [iverilog, GTKWave, Quartus(altpll)]
bus: none
peripherals: [actuator-servo, sensor, comm-i2c, comm-spi, comm-uart]
stage: T4
license: GPL-3.0
stats: {stars: 993, forks: 275, commits: 18}
doc_language: en
verification: L3
checked_at: 2026-11-02
source_rev: unverified
sources: [https://github.com/WangXuan95/FpOC]
---

## 요약
BLDC/PMSM용 FOC(자계 지향 제어)를 순수 Verilog로 쓴 저장소. 각도 센서(AS5600, I2C)와 3션트 전류 ADC(AD7928, SPI)로 전류 루프(토크 제어)까지 닫는다. 알고리즘부(`foc_top`)와 보드 의존부(센서·ADC·PLL)를 분리한 층 구조가 특징이다.

## 구조
- 모듈(README 기준): fpga_top, uart_monitor, i2c_register_read(AS5600), adc_ad7928, foc_top, clark_tr, park_tr(sincos 사용), pi_controller, cartesian2polar, svpwm(7구간), hold_detect.
- 변환 흐름: Clarke → Park 대신 극좌표 입력 SVPWM(각도 뺄셈으로 Park 대체) → 3상 PWM. 내부 연산 16비트 부호 정수, 센서·ADC는 12비트 가정.
- 클럭: 입력 50MHz, PLL로 36.864MHz → SVPWM 18kHz(clk/2048). 메인 클럭 40MHz 미만 제약은 AD7928 SPI 한계에서 온다.
- 전류 샘플링: 하단 3암이 모두 켜진 구간에서 ADC 시작(hold_detect, `SAMPLE_DELAY`로 정착 지연). 시작 시 회전자를 전기각 0으로 정렬(`INIT_CYCLES`).
- 파라미터: POLE_PAIR, MAX_AMP, ANGLE_INV, Kp/Ki 31비트 입력.
- 모니터: 115200 8N1 단방향 UART로 d/q축 실제·목표 전류 출력.

## 검증·재현성
- SIM 폴더: iverilog + GTKWave, 테스트벤치 tb_clark_park_tr, tb_svpwm. 모터 모델이 없어 닫힌 루프 전체는 시뮬레이션하지 않는다(README 기준).
- 실제 모터(저전력 짐벌 모터)에서 d/q 전류가 계단 목표를 따라간 직렬 플롯이 README에 있다. 드라이버 MP6540, 맞춤 아두이노 형상 보드(Gerber 제공).
- 자원 사용·타이밍: unverified: README에 없음. 최신 커밋 날짜·SHA: unverified: 페이지에 표시되지 않음.

## 한계·위험
- 라이선스 GPL-3.0 → 코드 복사 불가, 포트·레지스터·구조만 참고(§16.3 G0). 코드 주석은 중국어.
- 데모 PLL이 Altera altpll이라 Xilinx에서는 MMCM으로 교체 필요. 12V급 드라이버 보드와 모터는 별도 전원 필요.

## 재사용 메모
- 내 판단: 최상 단계(FOC)의 구조 교과서로 쓸 만하다. 순서(엔코더 → PWM → 샘플링 창 → 변환 → PI)가 모듈로 나뉘어 있어 사다리를 짜기 쉽다. GPL이라 자체 RTL로 다시 쓴다.
- 개조: 알고리즘부를 AXI4-Lite IP 표준 래퍼(Kp/Ki/목표 전류/POLE_PAIR 레지스터, 측정 d/q 읽기)로 옮길 수 있다. AS5600(I2C)·AD7928(SPI)은 Basys3 Pmod 3.3V로 연결 가능. 모터 전원은 분리하고 GND만 공통. 시험은 모터 모델 포함 테스트벤치를 새로 써야 한다.
