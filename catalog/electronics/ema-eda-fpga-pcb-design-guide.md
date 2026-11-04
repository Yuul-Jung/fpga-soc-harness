---
name: ema-eda-fpga-pcb-design-guide
url: https://www.ema-eda.com/ema-resources/blog/essential-fpga-pcb-design-guide-emd/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none
language: none
tools: []
bus: none
peripherals: [pcb-layout, signal-integrity, termination, crosstalk, EMI, power-integrity, differential-pair]
stage: T2
license: unknown
stats: {stars: 0, commits: 0, last_update: 2025-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://www.ema-eda.com/ema-resources/blog/essential-fpga-pcb-design-guide-emd/]
---

## 요약 (3줄)
EMA EDA 블로그의 FPGA PCB 설계 종합 가이드. 디커플링부터 신호 종단, 트레이스 레이아웃, 차동 쌍 규칙까지 FPGA 보드에 특화된 체크리스트를 항목별로 정리. via-in-pad, 3W 규칙, 45도 코너, GND via 배치 등 실무 규칙을 다수 포함.

## 구조

**전원·GND**
- 전원 플레인과 GND 플레인을 인접하게 배치 → 플레인 간 정전용량 → 고주파 디커플링 보조
- 분할 플레인 가급적 회피. 불가피하면 간극을 넘는 트레이스 절대 금지
- 전원·접지 net은 IC 가까이 배치해 인덕턴스 최소화

**디커플링**
- 값이 가장 작은 커패시터를 IC 전원/GND 핀에 최근접 배치 (via-in-pad 가능하면 적용)
- via-in-pad: IC 패드 아래에 직접 비아 → 커패시터까지 트레이스 없이 직결 → 인덕턴스 최소

**신호 무결성 (SI)**
- 임피던스 불연속(플레인 간격, 기판 재질 변화) 최소화
- via와 직각 코너는 용량성 불연속 → 불필요한 via 감소, 45도 코너 사용
- BGA breakout에는 마이크로비아 적합. 비아 스텁 제거용 백드릴링은 선택
- 차동 쌍 via 전환부 근처에 GND via 배치 → 리턴 루프 감소, EMI 억제

**종단(Termination)**
- 직렬 종단: 클럭 신호에만 적합, 드라이버 쪽에 배치
- 병렬 종단: 수신단 쪽(또는 양단), 저항은 드라이버·수신기에 최근접
- 값이 가장 작은 저항을 종단 끝단에 가장 가깝게 배치

**트레이스 레이아웃**
- 3W 규칙: 트레이스 중심 간격 ≥ 트레이스 폭 × 3 → 크로스토크 감소
- 차동 쌍: 스큐 최소(이상적으로 0), 쌍을 밀접하게 결합
- 인접 신호층에서 트레이스를 직각 교차 → 층간 결합(crosstalk) 감소

**SSN(스위칭 신호 노이즈)**
- 전원·GND 플레인을 최대한 가깝게 → 정전용량 증가 → 인덕턴스 감소
- 최대 속도 불필요 시 드라이버 속도를 낮춤 → SSN 감소

## 검증·재현성
- EMA EDA(Cadence 파트너, EDA 도구·교육 전문) 기술 블로그. 본문 직접 열람
- 항목 대부분 JEDEC·IPC 표준의 실무 적용 사례와 일치

## 한계·위험
- 실제 수치(예: Artix-7 PDN 임피던스 목표값, 특정 보드 스택업 권장안)는 미포함
- BGA 패키지 중심. Basys3의 XC7A35T(TQG144 패키지)는 BGA 아니므로 BGA 규칙은 직접 적용 불필요

## 재사용 메모
- Basys3 주변장치 확장 보드(Pmod, 모터 드라이버, 센서 허브) PCB 설계 시 고급 체크리스트로 사용. 특히 SPI/UART Pmod 연결선에 3W 규칙 적용, 클럭 트레이스 직렬 종단, Pmod 전원 핀 디커플링에 직접 적용 가능
- 개조: RTL과 직접 연관 없음. SoC IP(AXI4-Lite, AXI4-Stream)가 외부 고속 ADC·DAC와 연결되는 PCB에서 종단 저항 계산 및 임피던스 매칭에 활용. MicroBlaze V에서 실시간으로 처리하는 센서 데이터 품질이 PCB 레이아웃 품질에 직결됨 — RTL 필터(IIR·이동 평균)로 보완 가능하나 하드웨어 단에서 SI를 먼저 확보하는 것이 원칙
