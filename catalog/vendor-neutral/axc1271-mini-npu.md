---
name: axc1271-mini-npu
url: https://github.com/AxC1271/mini-NPU
source_type: repo
vendor: neutral
board: [unknown]
fit_basys3: needs-port
cpu: none(NPU가속기)
language: Verilog
tools: [unknown]
bus: unknown
peripherals: [NPU-lite]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-07
source_rev:
sources: [https://github.com/AxC1271/mini-NPU]
unverified: 보드·버스·라이선스·통계·툴체인·source_rev — GitHub MCP 세션 외 저장소 접근 불가, 검색 결과 제목·설명만 확인
---

## 요약

FPGA 하드웨어 가속 탐구 목적의 소형 NPU RTL 설계. INT8 MAC 연산을 시스톨릭 어레이 아키텍처로 구현해 행렬 연산을 효율화한다. 보드·버스·AXI 인터페이스 여부는 본문 미열람으로 미확인.

## 구조
- 아키텍처: INT8 곱-누산기(MAC), 시스톨릭 어레이
- 용도: 신경망 처리 가속 (추론 위주 추정)
- CPU: 없음 (독립 NPU 코어 추정)
- 버스: 미확인 (AXI4-Lite 슬레이브 여부 본문 열람 필요)
- unverified: 가중치 메모리 구조, 입출력 인터페이스, 메모리맵 — 본문 미열람

## 검증·재현성
- 미확인: 테스트벤치, 합성 보고서, CI — 본문 미열람
- unverified: 자원 사용(LUT/FF/BRAM/DSP), WNS, 보드 미명시

## 한계·위험
- 라이선스 미확인: 반입 전 확인 필요
- 보드 미명시: Basys3 XDC 없을 가능성 높음
- AXI 인터페이스 여부 미확인: MicroBlaze V 연동 여부 열람 필요
- unverified: 외부 IP 의존, Vivado vs iVerilog/Verilator 지원

## 재사용 메모
- ansh07verma-fpga-mini-npu와 유사한 INT8 시스톨릭 NPU. 두 저장소 비교 후 AXI4-Lite 슬레이브 래퍼 추가 여지가 더 높은 쪽을 선택하면 됨.
- 개조: 본문 열람 후 MAC 모듈의 포트(A/B 행렬 입력, C 누산 출력, 클럭·제어 신호) 사양을 추출(§16.3 G3)하고, AXI4-Lite 슬레이브로 감싸 가중치 레지스터·추론 시작·결과 준비 플래그를 설계한다. 동결 맵 free_slots 1개 배정 제안.
- 내 판단: S1 인접 도메인 이식 — 범용 NPU 코어를 MicroBlaze V SoC IP로 적응하는 패턴 자료. ansh07verma-fpga-mini-npu와 함께 L3로 승격 후 비교 카드 작성 권장.
