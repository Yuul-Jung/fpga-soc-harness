---
name: mari-upc-2022-fpga-foc-ipmsm-field-weakening
url: https://upcommons.upc.edu/bitstreams/3e26da9d-9dd9-44c4-b8a5-51eeb59dc867/download
source_type: paper
vendor: amd
board: [MYIR Z-Turn (Zynq-7020), Cora Z7-10 시도]
fit_basys3: no
cpu: ARM(Zynq PS, 선택적)
language: Simulink/Vitis Model Composer
tools: [Vivado, Vitis Model Composer, PetaLinux]
bus: unknown
peripherals: [actuator-servo, sensor, comm-can]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://upcommons.upc.edu/bitstreams/3e26da9d-9dd9-44c4-b8a5-51eeb59dc867/download]
---

## 요약
UPC ETSETB 2022년 학사 졸업논문. 4륜 구동 차량용 IPMSM에 필드 위킹(약계자)을 포함한 FOC를 Zynq에서 구현하는 계획과 시뮬레이션 결과를 다룬다. 본문 언어는 카탈로니아어(doc_language 허용값 제한으로 en 표기, 제목만 영어 병기 없음).

## 구조
- 블록: Clarke/Park/역Park(사인·코사인 LUT), 전류 PI 2개(안티윈드업, 디커플링), 전압 제한기, 속도 PI, MTPA(LUT), 9,000rpm 초과 시 약계자 PI. 각도·속도는 AD2S1210 레졸버-디지털 변환기에서 받음.
- 고정소수점, 파이프라인, 10ns 클럭. SVPWM은 삼각 반송파 비교, 16kHz, 데드타임 1µs, SiC MOSFET 인버터.
- 전류 센서 ADC 종류: unverified: 본문에 특정되지 않음. 자원 사용은 부록 B 참조라고 하나 수치는 열람 못함.

## 검증·재현성
- 단위 시험(사인/코사인, 반송파, SVPWM, 전압 제한기)과 Simulink 전체 시뮬레이션, Vivado 시뮬레이션. 전력 보드와 시험대 검증은 0%(미실시), CAN 검증 미완.

## 한계·위험
- 실측 근거가 없고 시뮬레이션뿐. 게인은 수동 조정. Zynq 필수라 Basys3에 그대로 못 옮김. 제어기 코드는 Model Composer 생성물이라 원문 소스 공개 여부 unverified.

## 재사용 메모
- 내 판단: 고급 FOC의 확장 요소(MTPA, 약계자, 안티윈드업, 디커플링)를 한 곳에서 보는 참고용이다. 입문용으로는 과하다.
- 개조: PI 안티윈드업·전압 제한 구조는 PID IP 표준 레지스터(적분 클램프)로 옮길 수 있다. 레졸버 변환기·SiC 인버터·Zynq PS·CAN은 못 옮긴다. 데드타임 1µs 같은 수치는 설계 참고값으로만 쓴다.
