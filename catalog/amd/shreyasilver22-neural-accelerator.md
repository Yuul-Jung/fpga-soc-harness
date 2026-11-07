---
name: shreyasilver22-neural-accelerator
url: https://github.com/Shreyasilver22/Neural-Accelerator
source_type: repo
vendor: amd
board: [Nexys4-DDR]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: []
stage: T2
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-08
sources: [https://gh.r-mj.com/Shreyasilver22/Neural-Accelerator]
---

## 요약

Nexys 4 DDR(Artix-7 XC7A100T) 대상 완전 연결 MLP 추론 가속기. 아키텍처는 784→16→10으로, 은닉층이 16뉴런으로 매우 작다. INT8 서명 가중치를 BRAM에 저장하고 32비트 누산기로 순차 MAC 연산을 수행한다. 교육·연구용.

## 구조

- 아키텍처: 784(입력) → 16(은닉, ReLU 추정) → 10(출력)
- 대상 보드: Nexys 4 DDR — Artix-7 XC7A100T (Basys3의 XC7A35T보다 2.5× 더 큰 칩)
- 가중치 저장: BRAM 기반; 가중치는 INT8 서명 정수, 누산기는 32비트
- 버스: 없음 (독립형 추론 모듈)
- 테스트벤치: HDL TB 없음; 비트 정확 Python 시뮬레이터(`verify_mnist.py`)를 황금 참조로 사용
- 자원 사용: 리포지터리 페이지에 LUT/FF/BRAM 수치 미기재
- 출처: GitHub 미러(gh.r-mj.com) 페이지 열람 — README 내용 직접 확인

## 검증·재현성

- 하드웨어 정확도 미기재; 직선, S형, E형, 정사각형 4개 기하학 도형에서 올바르게 분류됨을 보고
- MNIST 테스트셋 전체 정확도 없음 (16뉴런 은닉층은 ≥90% 달성에 충분하지 않을 가능성 큼)
- Python `verify_mnist.py`로 비트 수준 일치를 확인하는 구조; HDL 시뮬레이션 TB 미포함
- CI 없음

## 한계·위험

- 은닉층 16뉴런: MNIST ≥90% 정확도 목표(784→128→10) 대비 과소 설계. 10개 도형 테스트만으로 실제 MNIST 성능을 가늠할 수 없다.
- 라이선스 불명확: "educational or research use"라고 적혀 있으나 SPDX 식별자 없음 — 코드 재사용 전 라이선스 확인 필요.
- 자원 사용량 미기재 → Basys3 적합성 직접 확인 불가.
- Nexys 4 DDR(XC7A100T)는 BRAM 135개, Basys3(XC7A35T)는 50개. 100K 이상 가중치를 BRAM에 올리는 구조를 그대로 이식하면 BRAM 부족.

## 재사용 메모

Artix-7 계열에서 직렬 MAC + BRAM 가중치 저장 패턴을 Verilog로 구현하는 가장 단순한 사례. 은닉층 크기를 128로 늘리고 XC7A35T 한계(BRAM 50개)에 맞춰 BRAM 배치를 재설계하면 Basys3로 이식 가능.

개조: MicroBlaze V AXI4-Lite 슬레이브로 래핑 시 — ① 가중치 로드: AXI4-Lite 쓰기로 BRAM 초기화; ② 추론 트리거: STATUS/CTRL 레지스터; ③ 결과 읽기: 10개 로짓 또는 argmax 반환. CPU 비종속 MAC FSM 자체는 XC7A35T에서 재사용 가능. 단, 은닉층 128→10 가중치(1,280 × INT8 = 1.25KB) + 784→128(100KB) = 약 101KB → BRAM18 ≈ 6개 → Basys3 50개 한도 내.
