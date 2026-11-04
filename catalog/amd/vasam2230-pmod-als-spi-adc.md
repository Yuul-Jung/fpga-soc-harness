---
name: vasam2230-pmod-als-spi-adc
url: https://www.hackster.io/vasam2230/spi-interface-rtl-for-pmod-als-8-bit-adc-in-verilog-c1d5cb
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [sensor, comm-spi]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://www.hackster.io/vasam2230/spi-interface-rtl-for-pmod-als-8-bit-adc-in-verilog-c1d5cb, https://z.jpralves.net/post/2021/06/24/spi-interface-code-for-pmod-als-8-bit-adc-in-verilog.html]
---

## 요약
Basys3에서 Pmod ALS(TI ADC081S021 8비트 광센서 ADC)를 SPI로 읽어 7세그먼트에 표시하는 Verilog 프로젝트. SPI 클럭 분주, CS 타이밍, 8비트 수신, BCD 변환, 세그먼트 표시 네 모듈로 구성된다.

## 구조
- `spi_interface`: 클럭 분주로 ≈1.92 MHz SPI 클럭 생성. CS·SCLK·SDO 타이밍으로 8비트 MSB-first 수신. 프레임: 선두 3비트 더미 + 8비트 데이터 + 1비트 tri-state + 후미 4비트.
- `double_dabble`: 8비트 이진수 → BCD 변환. nandland 오픈소스 코드 사용(출처 명시, 라이선스 미상).
- `seven_segment_display`: BCD → 4자리 애노드/캐소드 신호.
- 클럭: Basys3 100 MHz. SPI 클럭은 카운터 2단계로 ≈1.92 MHz.
- 메모리맵: 없음(MMIO 없이 직결 FSM).

## 검증·재현성
- 테스트벤치로 SDO에 직렬 데이터를 주입해 double dabble 변환과 7세그먼트 제어를 시뮬레이션(방법 언급, 결과 수치 없음).
- 실제 하드웨어에서 Digilent Analog Discovery 로직 분석기로 CS·SCLK·SDO 파형 확인.

## 한계·위험
- 라이선스 없음(nandland double_dabble 코드 의존 포함). 코드 복사 전 라이선스 확인 필요.
- SPI 모드 0(CPOL=0, CPHA=0). 타이밍이 고정이라 다른 ADC로 이식 시 수정 필요.
- 데이터 전송 속도 조정, 7세그먼트 밝기 균일성 개선은 미해결 과제로 남음.

## 재사용 메모
- SPI 수신 FSM(CS+SCLK 카운터 패턴)은 다른 Pmod SPI 디바이스에 직접 이식 가능.
- 개조: AXI4-Lite 슬레이브 래퍼를 붙이면 MicroBlaze V에서 `mmio_rd(ADDR_ADC)` 한 줄로 ADC 값 읽기 가능. 분주비 파라미터화해 MCP3202(SPI 12비트) 등 다른 ADC로 확장 가능. nandland 코드 의존은 자체 BCD 로직으로 교체 권장(라이선스 불명확).
