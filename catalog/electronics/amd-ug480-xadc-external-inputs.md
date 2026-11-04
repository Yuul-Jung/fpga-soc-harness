---
name: amd-ug480-xadc-external-inputs
url: https://docs.amd.com/r/en-US/ug480_7Series_XADC/External-Analog-Inputs
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
sources: [https://docs.amd.com/r/en-US/ug480_7Series_XADC/External-Analog-Inputs, https://docs.amd.com/r/en-US/ug480_7Series_XADC/Analog-Inputs]
---

## 요약
AMD UG480 7시리즈 XADC 사용 설명서의 외부 아날로그 입력 절. 입력 범위, 차동 쌍 배선, 안티앨리어싱 필터 설계, 과전압 보호를 규정한다. Basys3 JXADC(XA1~XA4) 설계 근거 1차 출처.

## 구조
- 외부 채널: VP/VN(전용 입력), 최대 16쌍의 보조 차동 채널(VAUXP/VAUXN).
- 입력 범위: 0 V~1 V(1 V full-scale). 초과 시 최대 코드 클리핑, 음수 시 0 코드 클리핑.
- 차동 T/H 앰프: 공통 모드 잡음 제거. 단극성·양극성·완전 차동 지원.
- 안티앨리어싱 RC 필터: 패키지 핀 가까이 배치 권장. 100 Ω 직렬 저항(ICCADC 1 mA 제한)이 필터 저항 역할 겸용.
- 정착 시간: 12비트 기준 ≈4.9 μs(≈200 kS/s).
- 과전압 보호: VCCADC(1.8 V) 초과~GNDADC −100 mV까지 손상 없음(직렬 100 Ω 조건).

## 검증·재현성
- AMD 공식 문서. 예시 저항 분배기 회로(10 V → 1 V 변환)와 임피던스 매칭 공식 포함.
- 소스 코드 없음. 회로 설계 지침만 제공.

## 한계·위험
- 1 V 입력 범위가 좁아 모터 전류 측정 시 외부 신호 조건화 필수.
- Basys3 JXADC는 직접 PCB 보호 회로 없음(외부 100 Ω + RC 필터 사용자 추가).
- 샘플링 주파수를 올리면 멀티채널에서 채널 간 타이밍 왜곡 가능.

## 재사용 메모
- Basys3 JXADC XA1(ch6)/XA2(ch14)/XA3(ch7)/XA4(ch15) 각각에 션트 저항 전압을 연결해 모터 전류 감지 채널을 최대 4개 구성 가능.
- 개조: DRP 인터페이스(16비트, MSB 정렬)를 AXI4-Lite 슬레이브로 감싸 mmio_rd(ADDR_ADC_CHx) 형태로 읽으면 MicroBlaze V에서 전류 모니터링 가능. 100 Ω+RC 필터는 외부 부품 BOM에 명시 필요.
unverified: Basys3 XC7A35T의 VAUXP/VAUXN 핀 최대 활성 채널 수, DRP 액세스 사이클 타이밍.
