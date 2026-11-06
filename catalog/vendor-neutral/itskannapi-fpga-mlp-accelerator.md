---
name: itskannapi-fpga-mlp-accelerator
url: https://github.com/itsKannapi/fpga-mlp-accelerator
source_type: repo
vendor: neutral
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: AXI4-Lite
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: 미확인, commits: 미확인, last_update: 2024}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://github.com/itsKannapi/fpga-mlp-accelerator]
---

## 요약

Basys3(XC7A35T)에서 INT8 고정소수점 MLP 순전파를 수행하는 가속기. 15개의 RAMB18에 24.8 KiB 가중치를 저장하고 AXI4-Lite 슬레이브로 호스트와 통신한다. 5건의 자체 점검 테스트벤치가 14,000건 이상의 자동 검증 케이스를 포함한다.

## 구조

- 최상위: Basys3 래퍼 → `mlp_top.v` → 완전연결층 FSM
- 가중치 저장: 15× RAMB18 (Basys3 XC7A35T의 BRAM 50개 중 30% 사용)
- 연산: INT8 × INT8 → INT16/INT32 MAC (DSP48 활용)
- 활성화: ReLU (고정소수점 임계 처리)
- 버스: AXI4-Lite 슬레이브 — 입력 적재, 추론 시작, 출력 읽기 레지스터
- 자원(저자 보고): **~2,200 LUT, 42 DSP48, 15 RAMB18**

## 검증·재현성

- 테스트벤치 5건: 각 TB가 2,000~3,000건씩 총 14,000건 이상 비교 (전부 PASS)
- Vivado 프로젝트 포함, Basys3 `basys3.xdc` 제공
- ReLU 출력 범위, 오버플로우 포화 등 경계 케이스 포함

## 한계·위험

- **라이선스 명시 없음** — 코드를 가져오려면 라이선스 확인 필요. 구조·포트·레지스터 사양만 열람 목적으로 사용.
- 네트워크 구조(층 수, 뉴런 수) 고정 파라미터; 범용 MLP 엔진 아님
- INT8 오버플로우 처리 방법이 README에 미상세 기술 (TB 코드에서 추론)
- unverified: 정확한 레이어 구성(크기·순서)은 RTL 직접 열람으로만 확인 가능

## 재사용 메모

내 판단: BRAM 가중치 적재 패턴(15 RAMB18 → AXI4-Lite 접근)이 우리 캡스톤 MLP 가속기 설계의 직접 참조점이 된다. 특히 BRAM 초기화(`.mem` 파일)와 AXI4-Lite 슬레이브 레지스터 맵 구성이 유용하다.

개조: 라이선스 불명이므로 소스 복사 불가. 사양(BRAM 연결 방식, 레지스터 오프셋)을 추출해 자체 RTL을 쓰는 방향으로 사용. MicroBlaze V 동결 맵의 `free_slots`에 넣을 수 있고, DSP48 사용(42개)이 Basys3 보유량(90개)의 47%로 주의 필요.
