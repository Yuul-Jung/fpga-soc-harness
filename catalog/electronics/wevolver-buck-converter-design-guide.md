---
name: wevolver-buck-converter-design-guide
url: https://www.wevolver.com/article/buck-converters-a-comprehensive-guide-for-hardware-design-engineers
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none
language: none
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-03-01}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.wevolver.com/article/buck-converters-a-comprehensive-guide-for-hardware-design-engineers]
---

## 요약

Wevolver의 벅 컨버터 종합 설계 가이드(Ramsha Jawaid, 2026-03). 동작 원리, 설계 공식, 부품 선정, 12V→3.3V@5A 실습 예제를 한 문서에서 다룬다.

## 구조

**동작 원리**
- 연속 전도 모드(CCM): MOSFET 스위칭 → L 충방전 → C로 평활.
- 듀티 비: D = Vout / Vin (이상적 경우).

**설계 공식**
- 인덕터 최소값: L = (Vin - Vout) × D / (ΔIL × fs)
  - ΔIL = 부하 전류의 20~40% 리플 허용 권장.
  - fs = 스위칭 주파수.
- 출력 커패시터: C_out = ΔIL / (8 × fs × ΔVout)

**12V→3.3V@5A 설계 예제**
- fs = 500kHz, ΔIL = 1.5A (30%), ΔVout = 50mV.
- D = 3.3/12 = 0.275.
- L = (12-3.3) × 0.275 / (1.5 × 500000) ≈ 3.3µH.
- I_PEAK = 5 + 0.75 = 5.75A → 인덕터 포화 전류 여유 필요.
- C_out = 1.5 / (8 × 500000 × 0.05) = 7.5µF.

**부품 선정 기준**
- 인덕터: 직류 저항(DCR) 낮을수록 효율 ↑. 포화 전류 ≥ I_PEAK.
- MOSFET: RDS(on) 낮을수록 도통 손실 ↓. Qg(게이트 전하) 낮을수록 스위칭 손실 ↓.
- 출력 커패시터: ESR·ESL 낮은 세라믹(MLCC) 우선, 큰 용량은 전해 병렬.

**효율 최적화**
- 동기 정류(MOSFET 2개): 쇼트키 다이오드 대비 효율 3~5% 향상.
- 경부하 효율: DCM(불연속 전도 모드) 또는 PFM(펄스 주파수 변조) 활용.

## 검증·재현성

- 웹 기고문, CI 없음. 공식과 예제값을 열람 본문에서 직접 확인(L3).
- 계산값은 이상적 모델 기준이며 실제 소자 비선형성 미반영.

## 한계·위험

- IC 추천이나 레이아웃 가이드는 없음. 설계 공식 수준.
- 열 설계, EMI 필터, 보드 레이아웃 고려사항 미포함.
- CCM 기준이므로 경부하 DCM 전환 조건은 별도 계산 필요.

## 재사용 메모

Basys3 외부 모터 전원 12V→5V(모터 드라이버 로직) 또는 5V→3.3V(센서 모듈) 변환 단의 인덕터·커패시터 사이징 직접 적용 가능. 500kHz 기준이면 3.3µH급 소형 인덕터로 Pmod 근처에 설치 가능한 크기.
개조: SoC 보드 전원 레일(예: 5V USB → 3.3V 주변장치 보조 레일) 추가 시, fs=1MHz로 올리면 L≈1.65µH, C≈3.75µF로 더 소형화 가능. FPGA 코어 전원(<1.0V)은 별도 IC 필요(이 가이드 범위 외).
