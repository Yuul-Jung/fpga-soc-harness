---
name: shanker-teo-integer-intelligence-2026
url: https://www.mdpi.com/2079-9292/15/5/1117
source_type: paper
vendor: amd
board: [Cmod A7 (XC7A35T)]
fit_basys3: needs-port
cpu: none(추론 전용 가속 로직)
language: Verilog
tools: [PyTorch, Python, Caffe/AccDNN, Verilog 시뮬레이터(co-sim)]
bus: AXI4-Lite
peripherals: [INT8 MAC 유닛, 스케일 팩터 레지스터, 양자화 추론 파이프라인]
stage: T4
license: CC BY 3.0
stats: {stars: N/A, commits: N/A, last_update: 2026-03-08}
doc_language: en
verification: L3
checked_at: 2026-11-07
rechecked_at: 2026-11-07
source_rev:
sources: [https://www.mdpi.com/2079-9292/15/5/1117]
---

## 요약

싱가포르 기술설계대학(SUTD) Manjusha Shanker·Tee Hui Teo의 2026년 논문. XC7A35T(Cmod A7) 대상 INT8 PTQ 추론 흐름을 XOR 완구 네트워크부터 LeNet-5까지 교육적으로 단계별 제시. Python 비트 정확 참조 모델 → INT8 Verilog MAC → 하드웨어 co-시뮬레이션 경로를 보여 준다. 100 MHz 타당성 확인, 밀리초 단위 지연, Python 대비 최대 오차 ≤1 LSB.

## 구조

- **접근법**: PTQ(후훈련 양자화), 대칭 per-tensor INT8; QAT는 미래 연구로 언급만 됨
- **교육 단계**:
  1. XOR 소규모 MLP — INT8 활성화·가중치 정수화 원리
  2. LeNet-5 — Python 양자화기 → INT8 참조 모델 → Verilog MAC 구현 → co-시뮬레이션
- **스케일 팩터**: 텐서 단위 대칭 양자화; 스케일 계수는 AXI4-Lite 레지스터에 저장(논문에서 제시)
- **보드**: Cmod A7(XC7A35T) — Basys3와 동일 칩, 다른 폼 팩터·핀 배열
- **클럭**: 100 MHz 타당성 확인(구체적 WNS 미기재)
- **정밀도**: Python int 황금 모델 대비 ≤1 LSB 오차; 미스매치 0건
- **출판**: Electronics (MDPI), Vol. 15, No. 5, Art. 1117, 2026-03-08

## 검증·재현성

- Python 비트 정확 참조 모델과 Verilog RTL co-시뮬레이션으로 불일치 0 확인
- LeNet-5 MNIST 정확도 측정 포함(구체 수치는 논문 본문에 있으나 발췌 미확인)
- 보드 실물 동작: 논문이 Cmod A7 타당성을 주장하나 S3 증거표 미확인
- 소스 코드 공개 여부: 논문 CC BY 3.0, 코드 저장소 링크는 발췌에서 미확인

## 한계·위험

- PTQ만 다룸; QAT는 미래 연구 방향으로만 언급
- Cmod A7용 XDC — Basys3 Pmod/UART 핀 배열과 달라 포팅 필요
- 논문 발췌에서 구체 LUT/FF/BRAM 수치 미확인(`unverified: 논문 전문 접근 필요`)
- 교육 목적 논문: 새 알고리즘이 아닌 기존 INT8 양자화 흐름의 단계적 설명

## 재사용 메모

가져올 부분: Python 양자화기 → Verilog MAC co-시뮬 검증 방법론; 스케일 팩터 AXI 레지스터 패턴; INT8 교육 단계(XOR → LeNet-5)를 Basys3 튜토리얼로 재구성.

**개조**: MicroBlaze V AXI4-Lite 환경으로의 이식 — Basys3와 동일 칩(XC7A35T)이므로 로직 이식 가능.
- 옮길 수 있는 것: AXI4-Lite 스케일 팩터 레지스터 설계, INT8 MAC 파이프라인, Python co-시뮬 테스트 방법론, 교육 단계 구조.
- 옮길 수 없는 것: Cmod A7 전용 XDC(Basys3 Pmod 핀 재배선 필요); 보드 전원·핀 수 차이.
- 포팅 작업: Basys3 XDC(4개 Pmod 커넥터, USB UART) 로 XDC 교체; 클럭 소스 확인(Cmod A7: 12 MHz vs Basys3: 100 MHz).
- 동결 맵 적용: 스케일 팩터·CTRL 레지스터를 `free_slots` 중 하나에 64KB 단위로 배정.
- 근거 카드: shanker-teo-integer-intelligence-2026 (본 카드).
