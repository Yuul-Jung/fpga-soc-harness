---
name: antoinelecalvez05-ml-dot-product-accelerator
url: https://github.com/Antoinelecalvez05/ml-dot-product-accelerator
source_type: repo
vendor: neutral
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado, cocotb]
bus: none
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://github.com/Antoinelecalvez05/ml-dot-product-accelerator]
---

## 요약

부호 있는 8비트 정수 내적(dot product) 가속기. sequential(1-MAC) 아키텍처와 four-lane(4-MAC 병렬) 아키텍처 두 가지를 제공하며, cocotb 테스트벤치로 검증하고 Basys3 보드 데모를 포함한다. ML 추론에서 완전연결층 출력 계산에 직접 대응하는 T4급 가속기다.

## 구조

- 검색 요약 기준: sequential 아키텍처는 클럭 1사이클마다 1 MAC 연산, four-lane은 4개 MAC를 병렬 수행
- 목표 보드: Basys3(Artix-7 XC7A35T)
- 도구: Vivado(합성), cocotb(Python 기반 검증)
- 합성 벤치마크 기재 여부: 검색 요약상 "synthesis benchmarks" 포함. LUT/FF 수치는 미열람
- 언어: Verilog

## 검증·재현성

- cocotb(Python co-simulation)로 sequential/four-lane 양쪽을 검증
- Basys3 데모가 존재: `fit_basys3: yes` 근거
- S7(난이도 사다리) 관점: sequential = 1단계(단일 MAC 순차), four-lane = 2단계(4-MAC 병렬)
- 상세 LUT/FF/WNS는 미열람(L2)

## 한계·위험

- 라이선스 미확인(`unknown`). 코드 복사 전 확인 필요
- 세부 소스 구조(최상위 모듈명, 포트, 클럭 주파수, 파이프라인 단계 수)는 미열람
- 비트폭 고정(signed 8-bit int8): Q포맷 고정소수점 연장 시 비트폭 파라미터 추가 필요

## 재사용 메모

sequential 버전은 1×N 내적의 최소 구현으로 MicroBlaze V AXI4-Lite 슬레이브 IP 뼈대 연습에 활용 가능. four-lane은 4-way 병렬 MAC 패턴을 Basys3 DSP48로 매핑하는 사례로 T4 캡스톤의 가속기 블록 참조로 쓸 수 있음.
개조: 내 판단: sequential 버전을 AXI4-Lite 슬레이브로 감싸 MicroBlaze V가 명령 1개 쓰면 내적 결과를 읽는 IP로 개조 가능. 주소맵은 동결 맵 free_slots 1슬롯. 비트폭을 Q8.8(16비트) 고정소수점으로 확장하면 wangxuan95-fpga-fixedpoint 카드의 포화 연산 패턴과 연결됨.
