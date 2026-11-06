---
name: sivakumarchakarapalli-systolic-array-accelerator
url: https://github.com/sivakumarchakarapalli/systolic-array-accelerator
source_type: repo
vendor: neutral
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado, iverilog]
bus: AXI4-Lite
peripherals: [accelerator]
stage: T2
license: MIT
stats: {stars: 4, commits: 미확인, last_update: 2024-10}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://github.com/sivakumarchakarapalli/systolic-array-accelerator]
---

## 요약

Basys3(XC7A35T)에 구현된 INT8 부호 있는 4×4 시스톨릭 어레이 MAC 가속기. UART→AXI4-Lite 브리지를 통해 호스트가 행렬 데이터를 전송하고 가속기가 내적을 계산한다. iverilog로 NumPy 황금 모델과 대조한 1,000건 자동 테스트를 통과했다.

## 구조

- 최상위: `basys3_top.v` → AXI4-Lite 슬레이브 + 4×4 MAC 어레이 (`systolic_array.v`)
- 버스: UART→AXI4-Lite 브리지 (외부 PC가 AXI 레지스터 맵에 쓰기)
- 클럭: 100 MHz (Basys3 XC7A35T)
- 연산 비트폭: INT8 → INT16 (부분합) → INT32 (최종 누산)
- 주변장치: AXI4-Lite 슬레이브 레지스터로 입력 적재 및 결과 읽기

## 검증·재현성

- Vivado 합성 결과: **511 LUT, 0 BRAM, 0 DSP, Fmax 163 MHz** (저자 보고)
- 테스트: iverilog + Python 테스트 드라이버, NumPy 황금 모델과 1,000건 비교 (전부 PASS)
- Basys3 `.xdc` 제공, Vivado 프로젝트 포함
- MIT 라이선스 명시

## 한계·위험

- 행렬 크기 4×4 고정 (파라미터화되지 않음); 대형 행렬은 타일링 필요
- BRAM 활용 없음 — 가중치를 레지스터에 올려야 하므로 계층이 많은 MLP에는 적합하지 않음
- 출처를 직접 열람해 README와 소스 헤더를 확인함

## 재사용 메모

내 판단: 4×4 시스톨릭 MAC 코어(INT8→INT32)는 Basys3 여유 LUT 대비 소면적이므로, 2층 MLP 추론 가속기의 핵심 연산 단위로 가져오기 좋은 구조다. AXI4-Lite 슬레이브 패턴은 MicroBlaze V 동결 맵의 `free_slots`에 직접 붙일 수 있다.

개조: 버스는 AXI4-Lite로 호환. 가중치 저장은 BRAM이 아닌 레지스터이므로 MLP 가중치 볼륨이 커지면 `bram_dp.v` 추가 필요. INT8 비트폭은 동결 맵 IP 표준과 별도 확인 필요.
