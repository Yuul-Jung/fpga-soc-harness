---
name: columbia-4840-spring-2026-ahrs
url: https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/AHRS.pdf
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: ARM HPS (코어 종류는 문서에 없음)
language: unverified: 문서가 HDL 언어를 밝히지 않음
tools: [Platform Designer]
bus: AXI (HPS-to-FPGA 브리지 + 온칩 SRAM 공유)
peripherals: [sensor, comm-i2c, video-vga, accelerator]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 설계 단계 문서(제어 ASM 미완성이라고 문서가 밝힘). 최종 결과 수치 없음
sources: [https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/AHRS.pdf]
unverified: 최신 커밋 개념 없음(PDF), 소스 공개 여부, 정확도 결과
---

## 요약
DE1-SoC에서 MPU-9250 IMU를 읽어 롤·피치를 칼만 필터로 추정하고 VGA에 수평선 같은 자세 표시를 그리는 컬럼비아대 4840 강의 설계 문서(2026 봄).

## 구조
- 센서: MPU-9250(MPU-6500 + AK8963 자력계), I2C 400 kHz를 HPS가 구동(문서 서술).
- 분업: HPS가 1 kHz로 센서를 읽어 고정소수점으로 바꾸고 온칩 SRAM에 쓴 뒤 준비 플래그를 세운다. FPGA가 플래그를 보고 칼만 행렬 연산을 하여 결과를 SRAM에 돌려놓는다.
- 연산 자원(문서 값): 롤·피치를 병렬로 계산, 경로당 16비트 곱셈기 88개·덧셈기 56개, 합계 곱셈기 176개·덧셈기 112개.
- 공유 SRAM 데이터: roll_fx, pitch_fx, gx_fx, gy_fx, gz_fx 각 16비트. VGA 테이블은 480 스캔라인의 xstart/xstop 각 10비트.

## 검증·재현성
- 정확도·타이밍 결과는 문서에 없음. unverified: 시뮬레이션·테스트벤치 여부.

## 한계·위험
- 문서가 밝힌 단순화: 제어 행렬 B는 0, 프로세스 잡음 W는 0, 공분산 P는 대각. 요(yaw)는 초록에 있으나 데이터패스는 롤·피치만 설명.
- 라이선스 정보 없음. 코드 반입 대상 아님, 구조 참고용.

## 재사용 메모
- 내 판단: "소프트웨어가 센서를 읽고 고정소수점 값을 공유 메모리에 넣으면 하드웨어가 필터 연산"이라는 분업은 MicroBlaze V + AXI4-Lite 레지스터 구조와 거의 같은 모양이다. 곱셈기 176개는 Basys3(XC7A35T의 DSP 수는 이 문서로 확인 불가)에 그대로 들어간다고 단정할 수 없고, 시분할 공유가 필요할 수 있다(내 판단).
- 개조: 공유 SRAM 플래그 대신 AXI4-Lite 레지스터(IN_GX/GY/GZ/AX/AY/AZ, CTRL.start, STATUS.done, OUT_ROLL/PITCH)를 가진 자세 추정 IP로 옮기고, HPS 전용 mmap 접근과 VGA 표시부는 옮기지 않는다. 필터는 칼만보다 상보 필터를 먼저 구현하는 사다리를 제안(내 판단).
