---
name: pmc4628004-microblaze-gps-ins-virtex6
url: https://pmc.ncbi.nlm.nih.gov/articles/PMC4628004
source_type: paper
vendor: amd
board: [Xilinx ML605 (Virtex-6 XC6VLX240T-1FFG1156)]
fit_basys3: needs-port
cpu: MicroBlaze (32비트, FPU 추가)
language: C (필터), HDL 언어는 unverified
tools: [Xilinx Platform Studio]
bus: PLB
peripherals: [sensor, accelerator]
stage: T3
license: unknown
stats: {published: 2015-10-20}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 표 2(자원 수치)는 추출이 깨져 개수를 읽지 못함
sources: [https://pmc.ncbi.nlm.nih.gov/articles/PMC4628004]
unverified: 표 2의 슬라이스·DSP·BRAM 원본 개수, 저널명, 라이선스
---

## 요약
MicroBlaze 소프트코어에서 GPS/INS 느슨 결합 칼만 필터를 돌린 2015년 논문. 센서 입력은 실제 장치가 아니라 비행 궤적 데이터와 데이터시트 사양으로 만든 모의 값이다.

## 구조
- MicroBlaze: 3단 파이프라인, 레지스터 32개, 단정밀도 FPU를 주변장치로 연결. 최대 130 MHz, 시험은 88 MHz(논문 서술).
- INS·GPS "데이터 서버"가 하드웨어 IP로 샘플을 공급하고, 칼만 필터(9상태 오차 모델)는 C로 MicroBlaze에서 실행. INS 적분은 4차 룽게-쿠타(논문 서술).
- 부동소수점(단정밀도)을 쓰고 배정밀도는 자원 때문에 택하지 않았다고 밝힘.

## 검증·재현성
- 칼만 필터 1회 0.9 ms(필터 주기 10 ms), INS 해 갱신 100 Hz, 900 s 데이터로 프로파일. 자원은 결론 기준 슬라이스 약 5%, DSP48 약 1%, BRAM 약 16%(표 기반, 원표 미판독).
- 위치 정확도는 250 s 구간에서 GPS 수신기와 비슷하다고 서술.

## 한계·위험
- 센서가 모의 값이라 실센서 잡음·I2C 읽기 문제는 다루지 않음. PLB는 구세대 버스. 라이선스 정보 없음.

## 재사용 메모
- 내 판단: "MicroBlaze + FPU에서 C로 필터를 돌려도 0.9 ms"라는 수치는 Basys3의 MicroBlaze V(FPU 포함 여부는 프로젝트 설정 확인 필요)로 100~1000 Hz 자세 루프가 가능하다는 방향의 근거이나, 코어 종류가 달라 같은 시간을 보장하지 않는다.
- 개조: 데이터 서버 IP는 AXI4-Lite IMU 허브(원시 샘플 FIFO + 타임스탬프 레지스터)로, PLB는 AXI4-Lite로 바꾼다. 필터는 C 소프트웨어이므로 CPU 비종속 드라이버 구조에 그대로 놓는다. PLB·ML605 전용 부분은 옮길 수 없다.
