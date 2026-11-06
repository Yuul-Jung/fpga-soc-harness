---
name: ethanflorendo-fpga-systolic-array-matrix-multiplier
url: https://github.com/EthanFlorendo/FPGA-Systolic-Array-Matrix-Multiplier
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://github.com/EthanFlorendo/FPGA-Systolic-Array-Matrix-Multiplier]
---

## 요약

4×4 시스톨릭 어레이 행렬 곱셈기를 Verilog로 구현. 처리 요소(PE)마다 MAC 연산을 수행하고, 입출력 행렬을 BRAM에 저장한다. 타이밍 분석과 FPGA 자원 사용량 평가를 포함하며, 디버깅·시뮬레이션 과정을 문서화한 교육용 프로젝트다.

## 구조

- 검색 요약 기준: 4×4 시스톨릭 어레이, 각 PE(Processing Element)가 MAC 수행
- 행렬 저장: BRAM 사용(입력·출력 행렬)
- 포함 항목: 디버깅 절차, 시뮬레이션, 타이밍 분석, 자원 사용량 평가
- 언어: Verilog (검색 요약 기준)
- 목표 보드: 미명시(검색 요약). 보드 종류 미확인

## 검증·재현성

- 시뮬레이션 포함: 검색 요약에 "simulation" 명시
- 타이밍 분석·자원 사용량 평가: Vivado 환경 추정(LUT/FF/WNS 수치 미열람)
- S7(난이도 사다리) 관점: sequential MAC 단일 체인(T4 Level 2) → 4×4 시스톨릭 어레이(T4 Level 3)
- 상세 LUT/FF/클럭 주파수 미열람(L2)

## 한계·위험

- 목표 보드 미명시: `fit_basys3: needs-port` (xdc, 클럭, 핀 배정 교체 필요)
- 4×4 고정 크기: N×N 파라미터화 여부 미확인
- 라이선스 미확인(`unknown`)
- BRAM 주소 생성 방식(순서 적재 vs. 임의 접근) 미열람

## 재사용 메모

4×4 시스톨릭 어레이의 PE 계층(PE → 행 → 어레이 → 최상위)은 Basys3 MicroBlaze V NPU 가속기 블록 설계 시 구조 참조로 활용 가능. BRAM 가중치 적재 패턴과 출력 적산(accumulation) 흐름이 B3 테크트리 MAC 어레이 단계의 핵심 패턴.
개조: 내 판단: 4×4 고정 크기를 N 파라미터화로 확장하면 Basys3의 DSP48(90개)·BRAM(50개) 범위에서 최대 N=8~16 어레이가 가능할 것으로 추정(내 계산, 실측 없음). AXI4-Lite 슬레이브 래퍼를 추가해 MicroBlaze V가 행렬 주소·실행 명령을 쓰고 결과를 읽는 IP 구조로 전환 가능. 동결 맵 free_slots 1슬롯 사용 제안.
