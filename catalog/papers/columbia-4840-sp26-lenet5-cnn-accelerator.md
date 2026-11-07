---
name: columbia-4840-sp26-lenet5-cnn-accelerator
url: https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/LeNet-5-CNN-Accelerator.pdf
source_type: report
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(가속기)
language: SystemVerilog
tools: []
bus: AXI4-Stream
peripherals: [CNN-conv, pooling, FC-layer]
stage: T4
license: 교육용(Columbia CSEE 4840)
stats: {year: 2026}
doc_language: en
verification: L2
checked_at: 2026-11-07
unverified: 보드, 자원, 합성 결과, 소스 코드 위치 — 검색 결과 제목 열람만
sources: [https://www.cs.columbia.edu/~sedwards/classes/2026/4840-spring/designs/LeNet-5-CNN-Accelerator.pdf]
---

## 요약 (3줄 이내, 내 표현으로)
Columbia CSEE 4840 2026 Spring 수업 프로젝트. LeNet-5 아키텍처(Conv→Pool→Conv→Pool→FC) 가속기를 하드웨어로 구현한 보고서. 검색 결과 제목만 확인했다(L2).

## 구조
- LeNet-5: 컨볼루션 2단 + 풀링 2단 + 완전연결층 구조(추정, unverified).
- AXI4-Stream 인터페이스로 픽셀 스트림 처리 가능성(추정, unverified).

## 검증·재현성
- 대학 과목 최종 보고서 형식(이전 Columbia CSEE 4840 프로젝트 패턴 기반 추정).
- 실제 합성 여부, Vivado 검증 unverified.

## 한계·위험
- L2 열람. PDF 직접 미열람. 보드 대상 미확인.
- 교육용 보고서이므로 라이선스 별도 확인 필요.

## 재사용 메모
- 내 판단: LeNet-5의 컨볼루션 커널 레지스터 패턴과 AXI 인터페이스 설계가 MicroBlaze V 슬롯 연결 참고에 적합하다. BRAM 사용량 추정은 L3 열람 후 가능.
- 개조: 컨볼루션 커널 계수를 AXI4-Lite 쓰기 레지스터로 노출하고, 처리 완료 인터럽트를 intc_free 슬롯에 배정.
- 라이선스 확인 필요.
