---
name: arxiv-2304.03974-bramac
url: https://arxiv.org/abs/2304.03974
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(전용 가속기)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: 2023-04}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://arxiv.org/abs/2304.03974, https://ar5iv.labs.arxiv.org/html/2304.03974, https://deepai.org/publication/bramac-compute-in-bram-architectures-for-multiply-accumulate-on-fpgas]
---

## 요약

FPGA의 BRAM 블록 자체를 계산 패브릭으로 활용하는 Compute-in-BRAM 아키텍처(BRAMAC). 기존 "BRAM = 가중치 저장소" 관점을 뒤집어, BRAM의 읽기·쓰기 포트를 MAC 연산의 부분곱 적산에 직접 사용한다(S4 제약 역전). DNN 추론의 MAC 연산에서 LUT 자원 절약이 주된 동기다.

## 구조

- 검색 요약 기준: BRAM 블록의 내부 포트를 활용한 계산-인-메모리 MAC 아키텍처
- 목표: DNN 추론에서 reduced integer precision(int8 등) MAC 연산 하드웨어
- BRAM 활용 방식: 기존 "저장소"에서 "계산 패브릭"으로 전환 — 부분곱을 BRAM 쓰기→읽기 사이클로 적산
- 발표: arXiv 2304.03974 (컴퓨터 과학 > 하드웨어 아키텍처, 2023-04)
- 근거 출처: NSF PAR, DeepAI, ar5iv(HTML 렌더), Bohrium(검색 요약만 확인, 본문 미열람)

## 검증·재현성

- arXiv 논문: Vivado 기반 합성 결과 포함 추정(LUT/BRAM 비교표 가능성)
- 본문 미열람(L2): 세부 LUT 절감 수치, BRAM 사용 패턴, 클럭 주파수 미확인
- 소스 코드 공개 여부 미확인(논문만 arXiv 등록 확인)

## 한계·위험

- 본문 직접 열람 불가(L2): 구체적 아키텍처 세부, 포트 인터페이스, 클럭 사양 미확인
- Basys3 타깃 명시 여부 미확인(`fit_basys3: needs-port`)
- 소스 코드 미공개 가능성: 논문에서 RTL 복제 시 별도 작성 필요
- BRAM 크기/포트 종류에 따라 아키텍처 제약이 다를 수 있음(XC7A35T: BRAM36 50블록)

## 재사용 메모

S4(제약 역전) 관점: Basys3의 50 BRAM 블록을 가중치 저장과 MAC 계산을 동시에 수행하는 단위로 활용하면 DSP48 절약이 가능. BRAMAC 패턴은 Basys3 고정소수점 MAC 어레이 IP 설계 시 "BRAM-bound 제약을 오히려 활용"하는 관점을 제공한다.
개조: 내 판단: 본 논문의 BRAM 활용 아이디어를 직접 RTL에 반영하려면 XC7A35T의 BRAM36 포트 사양(SDP 모드, 2×18kb 포트)을 먼저 확인해야 함. MicroBlaze V IP로 개조 시, BRAMAC 계산 블록을 AXI4-Lite 슬레이브로 감싸는 구조가 유력. 동결 맵 free_slots 1슬롯 적합. RTL은 논문 내용을 근거로 새로 작성 필요(소스 복사 불가).
