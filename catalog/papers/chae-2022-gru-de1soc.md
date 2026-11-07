---
name: chae-2022-gru-de1soc
url: https://koreascience.kr/article/JAKO202218754064075.pub
source_type: paper
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: none(가속기)
language: unknown
tools: [Quartus]
bus: none
peripherals: [GRU-cell, sparse-MAC]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2022-06-01}
doc_language: ko
verification: L2
checked_at: 2026-11-07
rechecked_at: 2026-11-07
sources: [https://koreascience.kr/article/JAKO202218754064075.pub]
---

## 요약 (3줄 이내, 내 표현으로)

채병철(고려대학교 전자정보공학부, 2022)이 DE1-SoC(Cyclone V)에서 구조적 압축(Top-k 가지치기 + 하이브리드 양자화)을 적용한 GRU 추론 가속기 설계. CPU 대비 57배, GPU 대비 30배 지연시간 감소. 에너지 효율: CPU 대비 300배, GPU 대비 23.44배 향상. 45.01 GOPs 달성.

## 구조

- 보드: Intel DE1-SoC (Cyclone V SoC, Altera)
- 압축 기법:
  - 구조적 Top-k 가지치기: GRU 가중치에서 절댓값 하위 k% 연결을 블록 단위로 제거
  - 하이브리드 양자화: 가지치기 후 고정소수점으로 양자화 (구체적 비트폭 미확인)
- 성능: 45.01 GOPs (희소 GRU 모델, 배치 없음)
- 비교: CPU 대비 57x 지연시간 감소, GPU 대비 30x; 에너지 효율 CPU 300x, GPU 23.44x
- unverified: 아키텍처 세부(레이어 크기, 클럭, LUT/FF/BRAM 수치), 고정소수점 비트폭 — 검색 요약 기준

## 검증·재현성

- unverified: 테스트벤치, CI, 자원 사용(LUT/FF/BRAM/DSP), WNS — 논문 본문 미열람
- 성능 수치(GOPs, 지연시간 비율)는 koreascience.kr 초록에서 확인
- 소스 코드 공개 여부 미확인 (학술 논문 특성상 미공개 가능성 높음)

## 한계·위험

- 타깃: Intel DE1-SoC(Cyclone V) → AMD Artix-7/Basys3 환경으로 직접 사용 불가, Quartus 도구
- 압축 기법(Top-k + 하이브리드 양자화) 세부 구현이 본문 미열람으로 불명확
- 한국어 논문: JKIICE vol. 26 no. 6 (2022), 소스 미공개 가능성
- 2022년 논문, Cyclone V 타깃: Basys3 이식성 unknown (구조 참고 가능)

## 재사용 메모

핵심 아이디어: 구조적 가지치기로 GRU 가중치의 비규칙 희소성을 없애고, 블록 단위 0-패딩으로 MAC 스킵 가능 → Basys3의 제한된 DSP48를 더 효율적으로 활용하는 패턴.

개조: (내 판단)
① Cyclone V SoC 구현 → AMD Artix-7/Basys3 이식 시: Quartus IP 대신 Vivado IP(DSP48E1 MAC 직접 인스턴스화 또는 XPM MACC 사용)
② Top-k 가지치기는 추론 전 훈련 단계에서 처리: MicroBlaze V 소프트웨어에서 가중치 적재 시 0-패딩된 희소 행렬로 압축 → AXI4-Lite write 포트
③ GRU 셀 자체(2게이트: update/reset)는 LSTM보다 25% 적은 MAC → 가지치기 추가 시 Basys3 BRAM에 가중치 올릴 수 있는 모델 크기 확대
④ 옮길 수 없는 것: Cyclone V의 HPS(ARM Cortex-A9) 연동 흐름, Quartus 고유 IP, 한국어 논문이므로 세부 구현은 직접 재현 필요
