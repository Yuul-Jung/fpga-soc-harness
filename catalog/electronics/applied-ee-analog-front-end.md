---
name: applied-ee-analog-front-end
url: https://applied-ee.github.io/embedded/docs/sensor-integration/analog-front-end/signal-conditioning-circuits/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(참조 자료)
language: []
tools: []
bus: analog
peripherals: [ADC, op-amp, instrumentation-amplifier, RC-filter, signal-conditioning]
stage: T2
license: unknown
stats: {stars: null, commits: null, last_update: null}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://applied-ee.github.io/embedded/docs/sensor-integration/analog-front-end/signal-conditioning-circuits/]
---

## 요약

Applied-EE의 임베디드 센서 통합 가이드 중 아날로그 프런트엔드(AFE) 신호 조건화 절을 열람. 분압기, op-amp 버퍼, 계장 증폭기, RC 안티앨리어싱 필터, 입력 보호 회로를 망라해 각각의 회로 형태·공식·실용 주의점을 정리한다. FPGA XADC 프런트엔드 설계 참조 목적에 적합한 회로 설계 기준 문서.

## 구조

**신호 조건화 회로 종류와 특성**

| 회로 형태 | 역할 | 주의점 |
|-----------|------|--------|
| 분압기 | 입력 범위 축소 | 정상 전류 소모, 출력 임피던스 주의 |
| op-amp 버퍼(전압 폴로어) | 저임피던스 ADC 구동 | Rail-to-rail I/O 선택, 전원 디커플링 100 nF (핀 5mm 이내) |
| 계장 증폭기(INA) | 소신호 차동 증폭 + 동상 모드 제거 | 대역폭 = GBW / 게인, 고게인 시 BW 급감 |
| RC 안티앨리어싱 필터 | Nyquist 위 주파수 감쇠 | 단극: −20 dB/dec, 2차 Sallen-Key: −40 dB/dec |
| 입력 보호 | 과전압 방지 | Schottky 클램프 + 직렬 저항 + TVS 다이오드 |

**핵심 공식 (직접 확인)**
- 분압기 출력: V_out = V_in × R2 / (R1 + R2)
- 분압기 출력 임피던스: R_out = R1 ∥ R2
- RC 차단 주파수: f_c = 1 / (2π × R_f × C_f)
- 계장 증폭기 게인: G = 1 + (100 kΩ / R_G) ← INA128 계열 기준
- 열잡음: V_n = √(4kTR × BW) [V/√Hz]

**안티앨리어싱 필터 설계 지침**
- 차단 주파수 ≈ Nyquist / (5~10) 로 설정 (충분한 감쇠 여유)
- RC 저항이 소스 임피던스에 더해지므로 ADC settling time 계산 시 반영
- 필터를 ADC 핀 가능한 가깝게 배치

**입력 보호 조합 (레이어드 체인)**
1. 직렬 저항 (전류 제한)
2. TVS 다이오드 (에너지 흡수)
3. RC 필터
4. Schottky 클램프 → VDD, GND 범위 초과 차단

**부품 선택 주의사항**
- 필터·기준 커패시터: film 또는 C0G/NP0 사용 (X7R/X5R는 DC 바이어스로 용량 감소)
- 브리지 센서: 기준 전압에서 여기(excitation)하는 비율계량 방식으로 기준 드리프트 소거
- Schottky 클램프: 고온에서 누설 전류 증가 → 정밀 설계 시 오프셋 오차 유발

## 검증·재현성

- 공식 및 회로 형태 직접 열람(L3). RTL 구현 없음 — 아날로그 설계 기준 문서
- 주의: 본문의 RC 필터 테이블 일부 값이 공식과 불일치 가능성 있음(100 kΩ, 100 nF 조합의 −20.5 dB 표기가 계산치 −10.8 dB와 다름 → 테이블 값은 직접 계산으로 검증 권장)

## 한계·위험

- 특정 MCU/FPGA 보드 미제공. 회로 원리만 설명
- 라이선스: GitHub Pages 기반 교육 자료, 라이선스 명시 없음 — 코드·회로도 복사 전 확인 필요
- 전압 분배기 사용 시 배터리 시스템에서 정상 전류 소모가 지배적

## 재사용 메모

**Basys3 XADC 프런트엔드 직접 참조:**
- XADC 입력 범위 0~1V 제약 → 분압기 (R1 + R2 최소화해 임피던스 낮게) + op-amp 버퍼(unity gain) 조합 권장
- 보호 회로: Basys3 Pmod 핀 3.3V 환경에서 XADC VAUXP/VAUXN은 1V 초과 금지 → Schottky 클램프(MMSD4148T1G 등) 필수
- RC 안티앨리어싱: XADC 1 MSPS 단일 채널 운영 시 Nyquist = 500 kHz → f_c = 50~100 kHz (R ≈ 150 Ω, C ≈ 10 nF) 권장. XAPP795 기준 R = 150 Ω with C = 1 nF (500 kHz 차단) 최소 구성
- 개조: 이 회로 원리는 CPU 종류와 무관하다. MicroBlaze V든 PicoRV32든 동일한 아날로그 프런트엔드를 쓸 수 있음. 차이는 XADC 제어 레지스터를 읽는 AXI4-Lite 드라이버 C 코드뿐 — 하드웨어(분압기·버퍼·RC 필터) 설계는 동일.
