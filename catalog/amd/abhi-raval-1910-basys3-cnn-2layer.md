---
name: abhi-raval-1910-basys3-cnn-2layer
url: https://github.com/abhi-raval-1910/Basys3_CNN_2layer
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [UART, 7seg, LED]
stage: T4
license: MIT
stats: {stars: 2, commits: 9, last_update: 2024-01-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev:
sources: [https://github.com/abhi-raval-1910/Basys3_CNN_2layer]
---

## 요약

Basys3(XC7A35T-1CPG236C) 위에서 동작하는 2층 CNN 추론 가속기. 28×28 MNIST 이미지를 UART로 받아 Conv-Pool-Conv-Pool-FC 파이프라인으로 처리하고 결과를 7-세그먼트와 LED로 출력한다.

## 구조

모듈 목록: `dp_ram.v`(이중 포트 RAM), `weight_rom.v`(가중치 ROM), `uart_rx.v`(115200 baud), `conv_engine.v`(3×3 컨볼루션), `pool_engine.v`(2×2 MaxPool), `fc_engine.v`(완전 연결), `argmax10.v`(출력 레이블), `display_7seg.v`, `top.v`(최상위).

네트워크 구성:
- Conv1: 1→8 채널, 3×3 커널, ReLU
- MaxPool1: 2×2
- Conv2: 8→16 채널, 3×3 커널, ReLU
- MaxPool2: 2×2
- FC: 400→10, Softmax/Argmax

입력: UART 115200 baud, 28×28×1 MNIST (784 바이트). 출력: 7-세그먼트(예측 숫자) + LED.

가중치를 `weight_rom.v`(BRAM)에 저장. 추론 FSM이 순서대로 conv→pool→conv→pool→fc를 구동.

## 검증·재현성

README에 Basys3 대상임을 명시. Vivado 프로젝트 파일과 xdc 미확인(README에 빌드 절차 간략 기재). 테스트벤치 존재 여부 확인 불가. MNIST 추론 사례 사진이 README에 포함.

unverified: Vivado .xpr / xdc 파일 직접 확인 안 함. 자원(LUT/BRAM) 수치 미기재. 타이밍(WNS) 미기재.

## 한계·위험

- XC7A35T의 BRAM에 모든 가중치를 저장해야 하므로 네트워크 크기 제한
- FC 레이어 400→10 고정, 다른 태스크로 교체 시 재설계 필요
- 양자화 비트 폭 미기재 (고정소수점 폭 확인 필요)
- 절대경로·누락 파일 여부 미확인

## 재사용 메모

Basys3 직접 동작 사례. UART→추론→7세그 흐름 전체가 BRAM 기반으로 완결된다는 점에서 "DRAM 없는 CNN 추론"의 가장 직접적인 참고 카드.

개조: MicroBlaze V SoC에 연결 시 — `uart_rx.v`를 AXI4-Lite UART 슬레이브(`free_slots` 0xC000_0000)로 교체하고, `weight_rom.v`를 AXI4-Lite 슬레이브 레지스터 블록으로 감싸 프로세서가 가중치를 직접 write할 수 있게 한다. `conv_engine.v`·`pool_engine.v`·`fc_engine.v`는 버스 종속 없이 FSM 그대로 재사용 가능. 옮기지 못하는 부분: 현재 최상위 FSM이 하드와이어드 UART 타이밍에 종속 — AXI로 교체 시 FSM 타이밍 로직 재작성 필요.
