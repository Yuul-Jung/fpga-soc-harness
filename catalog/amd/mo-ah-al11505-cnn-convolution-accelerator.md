---
name: mo-ah-al11505-cnn-convolution-accelerator
url: https://github.com/mo-ah-al11505/CNN_Convolution_Accelerator
source_type: repo
vendor: amd
board: [PYNQ-Z2]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado, ModelSim]
bus: none
peripherals: []
stage: T2
license: MIT
stats: {stars: 1, commits: 5, last_update: 2023-12-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev:
sources: [https://github.com/mo-ah-al11505/CNN_Convolution_Accelerator]
---

## 요약

3×3 슬라이딩 윈도우 컨볼루션 가속기 RTL 생성기. 1-D 픽셀 스트림에서 직렬 라인 버퍼로 2×(W+2) 화소를 버퍼링한 뒤 한 사이클에 3×3=9 창을 추출하고 8-bit 커널과 곱-누산해 출력한다. PYNQ-Z2 대상이나 순수 Verilog라 Artix-7로 이식 가능.

## 구조

핵심 블록:
- **라인 버퍼**: 2개의 FIFO로 K-1=2 라인 지연 구현 (W+2 픽셀 각각)
- **윈도우 레지스터**: 각 라인 끝에서 3-탭 슬라이드 (3×3=9 출력 동시)
- **MAC 어레이**: 9개 곱셈기 + 덧셈 트리

입력: 8-bit unsigned 픽셀 직렬 스트림, 8-bit signed 커널 계수. Stride 1, valid padding (에지 픽셀 제외). 출력: 한 사이클 1 출력 픽셀 (MAC 합산 후 출력).

ModelSim 테스트벤치에서 Python golden model과 픽셀 단위 비교 검증 수록.

## 검증·재현성

ModelSim 시뮬레이션 통과 증거가 README에 있음(파형 캡처). Python `generate_coe.py`로 커널 ROE 파일 자동 생성. PYNQ-Z2 보드에서 실제 실행 증거 없음.

unverified: 자원(LUT/BRAM) 수치, 타이밍 WNS, 클럭 주파수 미기재.

## 한계·위험

- PYNQ-Z2(Zynq XC7Z020)용 — Basys3 이식 시 xdc·제약 재작성 필요
- Stride=1, valid padding만 지원 (same padding, stride>1 미구현)
- 단일 채널 — 다채널(멀티필터)은 외부에서 반복 호출하거나 병렬 인스턴스 필요
- 출력 비트 폭 성장(bit-growth) 처리 미명시 — 포화 처리 추가 필요

## 재사용 메모

3×3 슬라이딩 윈도우 + 라인 버퍼 RTL 프리미티브로서 가치가 높다. CNN 가속기의 핵심 연산 단위를 독립 모듈로 분리했으며, 순수 Verilog-2001 스타일로 작성된 것으로 보여 iverilog·verilator 호환 가능성이 높다.

개조: MicroBlaze V SoC 연동 — 이 모듈을 `conv_core.v`로 그대로 가져와 AXI4-Lite 슬레이브 래퍼(`axil_conv_ctrl.v`)를 외부에서 씌운다. 슬레이브가 커널 계수를 레지스터로 받고 DMA(또는 소프트웨어 루프)로 픽셀 스트림을 공급하면 MicroBlaze V에서 임의 커널을 로드해 추론 가능. 옮기지 못하는 부분: 현재 커널이 하드와이어드 COE ROM — 동적 커널 교체 시 외부 BRAM 인터페이스로 교체 필요.
