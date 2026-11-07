---
name: ansh07verma-fpga-mini-npu
url: https://github.com/ansh07verma/fpga-mini-npu
status: superseded
duplicate_of: ansh07verma-fpga-mini-npu
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
sources: [https://github.com/ansh07verma/fpga-mini-npu]
unverified: 보드·버스·라이선스·통계·툴체인·source_rev — GitHub MCP 세션 외 저장소 접근 불가, 검색 결과 제목·설명만 확인
---

## 요약

소형 FPGA 기반 뉴럴 프로세싱 유닛(CNN 가속기). INT8 행렬 곱을 Verilog 시스톨릭 어레이로 구현한다. 보드와 AXI 인터페이스 여부는 본문 미열람으로 미확인.

## 구조
- 아키텍처: INT8 시스톨릭 어레이 행렬 곱
- 용도: CNN 추론 가속기
- CPU: 없음 (독립 NPU IP 추정)
- 버스: 미확인 (AXI4-Lite 슬레이브 여부 본문 열람 필요)
- unverified: 메모리맵, 가중치 로드 방식, 추론 트리거·결과 레지스터 존재 여부 — 본문 미열람

## 검증·재현성
- 미확인: 테스트벤치, CI, 시뮬레이션 방법 — 본문 미열람
- unverified: LUT/FF 자원 사용, WNS — 보드 미명시

## 한계·위험
- 라이선스 미확인: 반입 전 반드시 확인 필요
- 보드 미명시: Basys3 XDC 없을 가능성 높음
- AXI 인터페이스 여부 미확인: MicroBlaze V 연동 가능성 열람 전 모름
- unverified: 의존 외부 IP, Vivado 지원 여부

## 재사용 메모
- INT8 시스톨릭 어레이 행렬 곱 모듈이 있으면 AXI4-Lite 슬레이브 래퍼를 씌워 MicroBlaze V NPU IP로 활용 가능
- 개조: 본문 열람 후 (a) 행렬 곱 모듈 포트(데이터·결과·제어 신호)를 확인하고, (b) AXI4-Lite 슬레이브로 감싸 가중치 로드 레지스터·추론 트리거·결과 읽기 레지스터를 추가한다. 직접 AXI 없으면 IP 표준 래퍼를 새로 작성한다. 동결 맵 free_slots 1개 배정 제안.
- 내 판단: S1 인접 도메인 이식 — FPGA 범용 NPU를 MicroBlaze V + AXI4-Lite 슬레이브로 옮길 수 있는 적합성은 본문 열람 후 판단 가능.
