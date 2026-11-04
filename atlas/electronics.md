# 전자기술 도메인 종합 (전력전자·인버터·게이트 드라이버·XADC 아날로그 프런트엔드·PCB 설계)

갱신: 2026-11-05 (/verify 12차). 카드 17건 기준. 전력전자·SPWM 인버터·게이트 드라이버·전원 설계·XADC 아날로그 프런트엔드 신호 처리·PCB 설계·신호 무결성.

---

## 1. SPWM 인버터 (변조 이론 · VHDL/Verilog RTL)

| 항목 | 카드 | 비고 |
|---|---|---|
| Spartan-3E SPWM 단상 반파 인버터 | arxiv-1002340-spartan3e-spwm-inverter | VHDL, 삼각파 비교, 소신호 출력 — 내 판단: AXI4-Lite 래퍼 추가로 MicroBlaze V IP 개조 가능(S2 전략) |
| VHDL PWM + 데드타임 (PYNQ-Z2) | element14-cumps-deadtime-vhdl-pynqz2 | 보완 출력·데드타임 삽입 FSM 설계 근거 — Basys3 Pmod 출력 그대로 적용 가능 |

**패턴:** SPWM은 "삼각파 카운터 vs 기준파 레지스터" 비교 로직이 핵심. 보완 출력과 데드타임(최소 500 ns@100 MHz = 50 클럭)을 한 FSM에서 처리하면 슈트스루를 방지한다. 내 판단: T2 AXI4-Lite IP로 묶으면 소프트웨어에서 주기·데드타임·변조지수를 런타임 제어 가능.

---

## 2. 게이트 드라이버 · H-브리지 · 슈트스루 방지

| 항목 | 카드 | 비고 |
|---|---|---|
| IRS2110 하프 브리지 드라이버 | industrialmonitordirect-irs2110-half-bridge | 부트스트랩 방식 HV 하이사이드 구동; Pmod 3.3V → HIN/LIN 직접 가능 (버퍼 추가) |
| IGBT 슈트스루 방지 (PWM 타이밍) | industrialmonitordirect-igbt-shootthrough | 데드타임·드라이버 전파 지연 계산; 교육적 고장 재현 가능 |
| MOSFET 선택 (모터 제어) | lcsc-mosfet-selection-motor-control | Rds_on·Vgs(th)·Qg 선택 기준; 로직레벨 MOSFET(Vgs(th)<2.5V)면 Pmod 직접 구동 가능 |
| 플라이백 보호 (쇼트키 다이오드) | zbotic-backem-flyback-protection | 역기전력(back-EMF) 차단 — 모터 Pmod 직접 연결 시 필수 |

**패턴:** Basys3 Pmod 출력(3.3V, < 24 mA/핀)은 로직레벨 MOSFET(2N7002 등) 게이트를 직접 구동할 수 있다. 대전류 경로에는 IRS2110 등 별도 드라이버가 필요하며, 슈트스루 방지를 위한 데드타임 삽입은 FPGA RTL에서 처리하는 것이 가장 정확하다. 내 판단: I-077(SPWM AXI4-Lite IP)이 I-078(슈트스루 테스트베드)의 RTL 기반을 제공한다.

---

## 3. 전원 설계 (FPGA 보조 전원 · 모터 분리 전원)

| 항목 | 카드 | 비고 |
|---|---|---|
| FPGA 전원 순서화·디커플링 | vishay-fpga-power-supply-consideration | Vccint→Vccaux→Vcco 순서, 디커플링 capacitor 선택 기준 |
| 벅 컨버터 설계 가이드 | wevolver-buck-converter-design-guide | 인덕터·커패시터·스위칭 주파수·리플 계산 — 12V→5V 외부 전원 보드 설계 근거 |
| LDO vs 스위칭 비교 | altium-ldo-vs-switching-regulator | 효율·노이즈·비용 비교 — 센서용 3.3V 레일에 LDO, 모터 드라이버용 5V에 벅 권장 |

**패턴:** Basys3 USB 5V 한계로 모터·서보에는 별도 외부 전원 필수(§17.2). 추천 구성: 12V→벅→5V/3A, 5V→LDO(AMS1117-3.3)→3.3V/1A, GND 공통, 보드 USB와 절연. I-076(외부 전원 보드 가이드)이 이 패턴의 T0 캡스톤 후보.

---

## 4. XADC 아날로그 프런트엔드 · 신호 처리

| 항목 | 카드 | 비고 |
|---|---|---|
| XADC 외부 입력 설계 (UG480) | amd-ug480-xadc-external-inputs | 차동 입력(VAUXP/N) 0–1V, RC 필터(50 Ω, 100 nF), Simulataneous Sampling 모드 |
| XADC 드라이빙 가이드 (XAPP795) | xilinx-xapp795-driving-xadc | 소스 임피던스·앤티앨리어싱 필터 R=50 Ω, C≥90 nF; 싱글엔드→차동 변환 |
| 아날로그 프런트엔드 신호 처리 | applied-ee-analog-front-end | 분압기·OPA 버퍼·RC 안티앨리어싱 설계 공식; 임피던스 정합 50 Ω 이하 |
| XADC 디지털 보정 기법 | epdtonthenet-xadc-digitally-enhanced-analogue | 오프셋·게인 보정 RTL, 이동 평균 필터 Verilog 예시 — library/rtl/ 기반 I-080 근거 |
| ACS712 홀 전류 센서 | sparkfun-acs712-current-sensor | 감도 185 mV/A(05B), V_OUT = 2.5+S×I; 단방향(0–5A) → 2.5–3.425 V → 분압 후 0–0.5V |

**패턴:** XADC는 Artix-7 하드 블록(12비트 1 MSPS). 외부 신호는 반드시 0–1V 범위로 스케일하고 R≤50 Ω, C≥90 nF RC 필터를 붙여야 한다. ACS712 출력(2.5V 중심)은 R1/R2 분압기(예: 4 kΩ/1 kΩ)로 단방향 0–0.5V 범위로 맞추고, 오프셋 보정은 소프트웨어에서 처리한다.

---

## 5. PCB 설계 · 신호 무결성

| 항목 | 카드 | 비고 |
|---|---|---|
| FPGA PCB 설계 종합 가이드 | ema-eda-fpga-pcb-design-guide | 3W 규칙·차동 쌍·via-in-pad·종단 체크리스트; Pmod/SPI 트레이스에 직접 적용 가능 |
| PCB 분할 GND 플레인·EMI | rfessentials-split-ground-plane-emi | 단일 통합 GND 권장, 모터 드라이버-FPGA 경계 스타 접지; 스티칭 커패시터 10 nF |
| 디커플링 커패시터 가이드 | jlcpcb-decoupling-capacitor-guide | 100 nF/1 µF/10 µF 계층 구조; 각 IC 로컬 배치; GND via 최단 경로 |

**패턴:** Basys3 Pmod 주변장치 보드 설계 체크리스트 (내 판단):
1. 각 IC 전원 핀에 100 nF + 1 µF 계층 디커플링 (jlcpcb-decoupling-capacitor-guide).
2. Pmod SPI/UART 트레이스 중심 간격 ≥ 트레이스 폭 × 3 (3W 규칙, ema-eda-fpga-pcb-design-guide).
3. 모터 H-브리지 GND와 FPGA 신호 GND를 스타 접지 한 점으로 연결, 연결 브리지 ≥ 2 mm 폭 (rfessentials-split-ground-plane-emi).
4. 클럭 신호에만 직렬 종단, 가급적 불필요한 via 최소화.

---

## 6. 비교표

| 카드 | 도메인 | 종류 | Basys3 적합성 | 개조 대상 |
|---|---|---|---|---|
| arxiv-1002340-spartan3e-spwm-inverter | electronics | SPWM RTL | needs-port | AXI4-Lite 래퍼·데드타임 FSM 추가 |
| element14-cumps-deadtime-vhdl-pynqz2 | electronics | PWM+데드타임 RTL | needs-port | VHDL→Verilog 변환, Basys3 Pmod 핀 |
| industrialmonitordirect-irs2110-half-bridge | electronics | 게이트 드라이버 | needs-port | Pmod→버퍼→IRS2110 HIN/LIN |
| industrialmonitordirect-igbt-shootthrough | electronics | 슈트스루 가이드 | needs-port | 데드타임 FSM 검증 근거 |
| lcsc-mosfet-selection-motor-control | electronics | 부품 선택 가이드 | yes(가이드) | 2N7002 직접 Pmod 구동 가능성 |
| zbotic-backem-flyback-protection | electronics | 역기전력 보호 | yes(가이드) | 모터 Pmod 직접 연결 시 필수 |
| vishay-fpga-power-supply-consideration | electronics | 전원 가이드 | yes(가이드) | FPGA 디커플링, 전원 순서 |
| wevolver-buck-converter-design-guide | electronics | 전원 설계 가이드 | yes(가이드) | 외부 전원 보드 벅 컨버터 설계 |
| altium-ldo-vs-switching-regulator | electronics | 전원 비교 가이드 | yes(가이드) | 센서 3.3V LDO, 모터 5V 벅 |
| amd-ug480-xadc-external-inputs | electronics | XADC 공식 문서 | yes | 차동 입력 범위·RC 필터 값 |
| xilinx-xapp795-driving-xadc | electronics | XADC 드라이빙 가이드 | yes | 소스 임피던스·앤티앨리어싱 필터 |
| applied-ee-analog-front-end | electronics | 신호 처리 가이드 | yes | 분압기·버퍼·RC 설계 공식 |
| epdtonthenet-xadc-digitally-enhanced-analogue | electronics | XADC 보정 RTL | yes | 오프셋·게인 보정, 이동 평균 필터 |
| sparkfun-acs712-current-sensor | electronics | 전류 센서 | needs-port | 분압·RC 조건화 후 XADC 연결 |
| ema-eda-fpga-pcb-design-guide | electronics | PCB 설계 종합 가이드 | needs-port | 3W 규칙·종단·via-in-pad·차동 쌍; Pmod 확장 보드 체크리스트 |
| rfessentials-split-ground-plane-emi | electronics | GND 플레인 EMI 가이드 | needs-port | 단일 통합 GND 권장, 모터 경계 스타 접지 |
| jlcpcb-decoupling-capacitor-guide | electronics | 디커플링 가이드 | needs-port | 100 nF/1 µF/10 µF 계층, 각 IC 로컬 via 최단 경로 |

---

## 7. 교훈

- **데드타임은 RTL에서**: 소프트웨어 타이밍 보정만으로는 슈트스루 방지 불충분. FPGA RTL에서 클럭 단위로 삽입 필요 (내 판단).
- **XADC 입력 범위 엄수**: 0–1V 초과 시 소자 손상. 분압기 설계 전 ACS712 최대 출력 전압을 반드시 계산 (sparkfun-acs712-current-sensor, amd-ug480-xadc-external-inputs).
- **전원 분리 필수**: 모터 전류 귀로가 Basys3 GND로 흘러들면 MCU 오동작. GND 공통선 한 가닥만 연결, 고주파 귀로는 커패시터 (§17.2).
- **이동 평균 필터**: 아날로그 RC만으로 부족한 경우 Verilog 이동 평균(N = 2의 거듭제곱, 나눗셈 → 비트 선택)으로 추가 노이즈 제거 (epdtonthenet-xadc-digitally-enhanced-analogue, I-080).
- **PCB 하드웨어 단에서 SI 먼저**: RTL 디지털 필터(이동 평균·IIR)는 PCB 레이아웃이 보장한 신호 품질을 보완하는 2차 수단이다. 3W 규칙·디커플링·GND 분리를 먼저 확보하고 RTL 필터를 더한다 (내 판단, ema-eda-fpga-pcb-design-guide·rfessentials-split-ground-plane-emi).

---

## 8. 아이디어 연결

| 아이디어 | 상태 | 근거 카드 |
|---|---|---|
| I-075 XADC 전원 모니터 AXI-Lite IP | ready | vishay-fpga-power-supply-consideration, altium-ldo-vs-switching-regulator |
| I-076 외부 보조 전원 보드 가이드 | ready | vishay-fpga-power-supply-consideration, wevolver-buck-converter-design-guide, altium-ldo-vs-switching-regulator |
| I-077 단상 풀브리지 SPWM AXI4-Lite IP | vetted(7점) | element14-cumps-deadtime-vhdl-pynqz2, industrialmonitordirect-irs2110-half-bridge, industrialmonitordirect-igbt-shootthrough |
| I-078 슈트스루 감지 테스트베드 | vetted(5점) | industrialmonitordirect-irs2110-half-bridge, industrialmonitordirect-igbt-shootthrough, element14-cumps-deadtime-vhdl-pynqz2 |
| I-079 SPWM+XADC 폐루프 변조지수 제어 | ready | arxiv-1002340-spartan3e-spwm-inverter, element14-cumps-deadtime-vhdl-pynqz2, industrialmonitordirect-igbt-shootthrough |
| I-080 범용 디지털 LPF 라이브러리 블록 | ready | amd-ug480-xadc-external-inputs, applied-ee-analog-front-end |
| I-081 XADC + ACS712 전류 측정 AXI IP | ready | sparkfun-acs712-current-sensor, xilinx-xapp795-driving-xadc, applied-ee-analog-front-end |
| I-082 MicroBlaze V AXI4-Lite SPI Pmod PCB 확장 보드 | vetted(차단조건재심사 8점, 다음 사이클 1순위) | jlcpcb-decoupling-capacitor-guide, rfessentials-split-ground-plane-emi, ema-eda-fpga-pcb-design-guide |
| I-083 모터 드라이버 보드 GND 분리 + 스타 접지 실습 | vetted(차단조건재심사 8점, 다음 사이클 2순위) | rfessentials-split-ground-plane-emi, jlcpcb-decoupling-capacitor-guide, industrialmonitordirect-irs2110-half-bridge |
| I-084 FPGA SoC PCB 전원 무결성 검증 가이드 | vetted(차단조건재심사 8점, 다음 사이클 3순위) | jlcpcb-decoupling-capacitor-guide, ema-eda-fpga-pcb-design-guide, vishay-fpga-power-supply-consideration |
