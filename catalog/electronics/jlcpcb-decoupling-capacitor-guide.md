---
name: jlcpcb-decoupling-capacitor-guide
url: https://jlcpcb.com/blog/decoupling-capacitors-guide
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none
language: none
tools: []
bus: none
peripherals: [decoupling, bypass-cap, pcb-layout, power-integrity]
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: 2026-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://jlcpcb.com/blog/decoupling-capacitors-guide]
---

## 요약 (3줄)
PCB 디커플링 커패시터의 값 선택, 배치 위치, via 설계까지를 입문 수준으로 체계적으로 정리한 JLCPCB 블로그 가이드. 100 nF/1 µF/10 µF 계층 디커플링 구조와 패키지별 SRF 차이, 4층 기판 vs 2층 기판 대응법을 다룬다.

## 구조

**값 선택 계층**
- 100 nF X7R MLCC: 대부분의 디지털 IC 기본 디커플링. SRF(자기 공진 주파수)가 높아 고주파 성분에 효과적
- 1 µF: 100 nF와 병렬 사용, 중간 주파수 보완
- 10 µF 이상 벌크: 레귤레이터 출력이나 보드 전원 입구 근처. 느린 대전류 과도 흡수
- 유전체: X7R(넓은 온도 범위), X5R(협소), C0G/NP0(아날로그·RF용)
- DC 바이어스로 실제 용량이 명시치보다 크게 감소할 수 있으므로 전압 정격 여유 필수

**배치 규칙**
- 커패시터는 IC 전원 핀에서 수 mm 이내에 배치. 거리가 늘수록 기생 인덕턴스 증가 → 고주파 필터링 효과 감소
- VDD 핀, 커패시터, GND 연결로 이루어진 전류 루프 면적을 최소화 → EMI 감소
- 하나의 커패시터를 여러 IC가 공유하지 않는다. 각 IC마다 로컬 커패시터

**Via 위치**
- GND 패드에서 최단 경로로 GND 플레인에 직결. 여러 레이어를 돌아가는 경로 금지
- 패드 가까이 전용 via, 공간 허용 시 병렬 via로 인덕턴스 저감
- 반대면(bottom) 배치 시 via 1개당 약 1~2 nH 추가 → 불가피한 경우 via 병렬

**레이어 구성**
- 2층: GND 플레인 없으므로 커패시터를 핀에 최대한 근접 배치
- 4층: 커패시터·IC 아래 솔리드 GND 플레인 → 짧은 귀환 경로 확보
- FPGA/MCU 고밀도 패키지: via-in-pad로 인덕턴스 최소화 고려

## 검증·재현성
- 출판사: JLCPCB 블로그(PCB 제조사 기술 문서). 정량 수치는 원문에서 직접 열람 확인
- FPGA 전용 정량 규칙(전원 핀당 커패시터 수 등)은 미포함 → 데이터시트 병행 필수

## 한계·위험
- FPGA별(Artix-7, Zynq 등) 전원 핀 세부 요구 사항은 없음. Basys3/XC7A35T 적용 시 UG949 §3의 PDN 권장안과 함께 사용
- 임피던스 제어 트레이스, 고속 차동 쌍 등 SI 전문 주제는 다루지 않음

## 재사용 메모
- MicroBlaze V SoC 주변장치 PCB 보조 자료로 직접 활용 가능. Basys3의 Pmod 헤더나 JXADC 헤더 주변에 디커플링을 추가할 때 계층별 값 선택 기준이 된다
- 개조: RTL과 직접 연관 없음. PCB 하드웨어 단계에서 AXI4-Lite 슬레이브 IP를 외부 보드와 연결할 때 전원 디커플링 체크리스트로 사용. 소프트코어(MicroBlaze V) 전원 레일 XC7A35T의 VCCINT(1.0V)·VCCO(3.3V)·VCCAUX(1.8V) 각 핀에 100 nF·1 µF 쌍 배치 원칙으로 적용 가능
