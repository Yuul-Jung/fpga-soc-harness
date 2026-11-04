---
name: xilinx-xapp795-driving-xadc
url: https://www.physics.umd.edu/hep/drew/495/xapp795-driving-xadc.pdf
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(XADC IP)
language: Verilog
tools: [Vivado 2024.2]
bus: AXI4-Lite
peripherals: [XADC, analog-input, differential-input, anti-aliasing-filter, signal-conditioning]
stage: T2
license: unknown
stats: {stars: null, commits: null, last_update: null}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://www.physics.umd.edu/hep/drew/495/xapp795-driving-xadc.pdf, https://dev.to/carolineee/the-principle-configuration-and-simulation-of-xadc-ip-in-xilinx-fpga-27ca, https://digilent.com/reference/programmable-logic/basys-3/demos/xadc]
---

## 요약

Xilinx XAPP795 "Driving the Xilinx Analog-to-Digital Converter" 애플리케이션 노트. XADC 외부 아날로그 입력을 올바르게 구동하기 위한 안티앨리어싱 필터 설계 값, 버퍼·분압기 유형별 필터 상수, 임피던스 균형 방법을 제공한다. DEV.to 기사(XADC IP 설정·시뮬레이션)와 Digilent Basys3 XADC 데모(JXADC 핀 매핑)를 함께 열람해 Basys3에서 외부 센서 신호를 XADC로 연결하는 완전한 프런트엔드 설계 기준을 얻었다.

## 구조

**Basys3 JXADC 헤더 채널 매핑 (Digilent 공식 데모)**
| 헤더 | XADC 채널 | 비고 |
|------|-----------|------|
| XA1 | CH6 (VAUXP6/VAUXN6) | SW0=down, SW1=down |
| XA2 | CH14 (VAUXP14/VAUXN14) | SW0=up, SW1=down |
| XA3 | CH7 (VAUXP7/VAUXN7) | SW0=down, SW1=up |
| XA4 | CH15 (VAUXP15/VAUXN15) | SW0=up, SW1=up |
- 입력 범위: 0~1V (1V 초과 금지)
- 차동 입력: P·N 측 임피던스를 대칭으로 맞추면 간섭 면역성 향상

**XADC 주요 사양 (Artix-7 XC7A35T, DEV.to 기사)**
- 듀얼 12비트 SAR ADC, 최대 1 MSPS
- 출력 형식: 16비트 상위 정렬 (bit[15:4] = 12비트 ADC 결과)
- 외부 채널: VP/VN 1쌍 + VAUXP/VAUXN 최대 16쌍 (패키지 제한)
- 모드: 단일 채널, 채널 시퀀서, 이벤트 구동(CONVST)
- 인터페이스: DRP(Dynamic Reconfiguration Port), AXI4-Lite, AXI4-Stream
- VAUX 핀: 디지털 I/O와 공유 — 아날로그 모드 사용 시 디지털 불가
- 시뮬레이션: UNISIM/SIMPRIM 모델이 SIM_MONITOR_FILE로 아날로그 자극 입력

**안티앨리어싱 필터 설계 값 (XAPP795 직접 열람)**

| 구동 소스 | R_AAF | C_AAF | 차단 주파수 |
|-----------|-------|-------|------------|
| 계장 증폭기(in-amp) 출력 | ≈ 150 Ω | 1 nF | ≈ 1.06 MHz |
| 분압기 (R1∥R2 ≈ 900 Ω) | — | ≈ 1.1 nF | ≈ 161 kHz |
| N측 균형 저항 추가 시 | — | ≈ 0.55 nF | — |
| 외부 MUX 출력 | ≈ 25 Ω | 1 nF | ≈ 6.4 MHz |

- 1 MSPS 단일 채널 → Nyquist 500 kHz. AAF는 의도적으로 더 높게 설정 가능 (충분한 settling time 확보)
- 버퍼 증폭기 필요 여부: "XADC는 일반적으로 버퍼 없이도 동작". 멀티플렉스·고성능 설계에서는 MUX 출력에 버퍼 1개 추가

**XADC IP 설정 (Vivado XADC Wizard)**
- 설정 레지스터: INIT_40 ~ INIT_5F (IP 속성으로 쓰거나 DRP로 나중에 변경 가능)
- 채널 시퀀서 모드 사용 시 채널당 샘플 레이트 감소 (채널 수에 반비례)

## 검증·재현성

- XAPP795: Xilinx 공식 애플리케이션 노트, 필터 값은 직접 수식 확인 가능 → L3
- DEV.to: Artix-7 보드에서 XADC IP 동작 검증한 튜토리얼 → L3 (열람)
- Digilent XADC 데모: Basys3에서 동작 확인된 공식 데모 (Vivado 프로젝트 GitHub 공개) → L3 (페이지 열람; 소스 모듈 내부는 미열람)
- 직접 RTL 시뮬레이션 없음

## 한계·위험

- 입력 전압 0~1V 초과 금지. ACS712(2.5V 중심), 열전대 증폭기 출력(5V) 직접 연결 불가 — 반드시 분압·레벨 변환 필요
- VAUXP/VAUXN 핀을 아날로그로 쓰면 해당 핀은 디지털 불가
- in-amp(INA128 등)의 대역폭: 대역폭 ≈ GBW / 게인 — 고게인 시 BW 급감
- 라이선스: XAPP795는 Xilinx/AMD 애플리케이션 노트 (배포·수정 제한 가능). Digilent 데모는 MIT 추정

## 재사용 메모

**Basys3에서 외부 센서 신호 연결 체인 (직접 적용 가능):**
1. 센서 → 분압기·op-amp 버퍼 → 0~1V 신호
2. RC 안티앨리어싱 필터 (R ≈ 150 Ω, C ≈ 1 nF) → JXADC 헤더 (XA1~XA4)
3. XADC Wizard IP (AXI4-Lite DRP 인터페이스)
4. MicroBlaze V AXI4-Lite → 소프트웨어 보정·디지털 필터

**JXADC 핀 제약(xdc):** Digilent 데모에서 직접 가져다 쓸 수 있음 — IOSTANDARD 포함

**개조:** 이 카드의 하드웨어 블록(분압기, RC 필터, XADC IP)은 CPU 종류에 완전 무관하다. MicroBlaze V든 PicoRV32든 같은 xdc·XADC IP를 사용. 차이는 DRP 접근 코드뿐 — Vitis의 XSysMon HAL 대신 AXI4-Lite write 함수로 대체 가능. 동결 주소맵 free_slots에서 XADC IP 주소 슬롯 1개 배정 필요 (현재 미동결, 사용자 확인 필요).
