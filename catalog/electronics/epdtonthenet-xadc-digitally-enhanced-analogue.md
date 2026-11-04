---
name: epdtonthenet-xadc-digitally-enhanced-analogue
url: https://www.epdtonthenet.net/article/55685/Digitally-Enhanced-Analogue-with-Xilinx-7-series-FPGAs.aspx
source_type: article
vendor: amd
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [sensor, XADC]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://www.epdtonthenet.net/article/55685/Digitally-Enhanced-Analogue-with-Xilinx-7-series-FPGAs.aspx, https://docs.amd.com/r/en-US/ug480_7Series_XADC/External-Analog-Inputs]
---

## 요약
Xilinx 7시리즈 XADC를 이용해 아날로그 신호를 디지털로 처리하는 방법을 설명하는 기술 기사. 차동 샘플링, 오버샘플링·데시메이션, 선형화·교정을 FPGA에서 소프트웨어 없이 구현하는 접근법을 다룬다.

## 구조
- XADC: 2개의 1 MS/s 12비트 ADC(16비트 변환 수행). 온칩 1.25 V 기준전압, 오프셋·게인 자동 보정.
- 차동 T/H 앰프: 단극성·양극성·완전 차동 신호 모두 수용. PCB 귀환 잡음 억제.
- 오버샘플링+데시메이션 필터: SAR ADC 뒤에 FIR/CIC 필터를 붙여 다이내믹 레인지 향상(10 MS/s 미만 대역에서 FPGA 구현 가능).
- RTD 예시: XADC로 센서 출력 디지털화 → FPGA에서 선형화·교정 계수 적용 → 여러 센서에 동일 IP 재사용.
- 외부 입력 범위: 0 V~1 V(JXADC 헤더 기준). 100 Ω 직렬 저항(전류 제한)과 안티앨리어싱 RC 필터 권장(패키지 핀 근처 배치).

## 검증·재현성
- 기사 수준 설명으로 소스 코드·테스트벤치·자원 수치는 없음.
- 개념 설명: 차동 쌍 배선, 직렬 100 Ω 보호, 안티앨리어싱 RC 필터 설계 지침.

## 한계·위험
- 소스 코드·Vivado 프로젝트 없음. 라이선스 없음(기사).
- Basys3 JXADC: 0–1 V 차동 입력. 모터 전류(0–수 A)는 션트 저항+저항 분배기나 ACS712 등 외부 신호 조건화 회로 필요.
- 고속 ADC(1 MS/s) 대역에서 CIC 필터를 FPGA로 구현하는 세부 코드는 없음.

## 재사용 메모
- XADC JXADC 채널(XA1~XA4)에 션트 저항 전압을 연결하면 모터 전류 측정 가능. 범위는 0–1 V이므로 R_shunt × I_max ≤ 1 V 조건으로 선택.
- 개조: XADC DRP 인터페이스(16비트 출력)에 N-탭 이동평균(CIC 구조) 필터를 덧붙여 AXI4-Lite 레지스터에 필터 결과를 노출하면 MicroBlaze V에서 직접 읽기 가능. 주소맵 free_slots 중 하나에 배정 제안.
unverified: 필터 소스 코드 없음, Basys3 JXADC 보호 회로 설계 미확인.
