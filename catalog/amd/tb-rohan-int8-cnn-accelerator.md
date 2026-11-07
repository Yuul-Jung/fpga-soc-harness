---
name: tb-rohan-int8-cnn-accelerator
url: https://github.com/tb-rohan/int8-cnn-accelerator
source_type: repo
vendor: amd
board: [Artix-7 200T (xc7a200tfbg676-2)]
fit_basys3: no
cpu: none(가속기 IP, OOC)
language: SystemVerilog
tools: [Icarus Verilog 12.0, AMD Vivado 2026.1, Python NumPy/torch]
bus: AXI4-Lite
peripherals: [4×4 INT8 systolic array, 가중치 BRAM, 바이어스 RAM, ReLU, 2×2 max-pool]
stage: T4
license: MIT
stats: {stars: unknown, commits: unknown, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-07
source_rev:
sources: [https://github.com/tb-rohan/int8-cnn-accelerator]
---

## 요약

Artix-7 200T 대상 INT8 가중치-정적 4×4 시스톨릭 어레이 CNN 가속기. AXI4-Lite 슬레이브로 호스트 CPU와 연결하며, 10개의 테스트벤치로 Python int 황금 모델과 대조해 9812개 원소 불일치 0건을 달성했다. MNIST에서 96.44% 정확도. OOC(Out-Of-Context) 합성 전용이며 보드 테스트 없음.

## 구조

- **최상위**: `cnn_accelerator_top` — AXI4-Lite 슬레이브 + 디스패처 + 시스톨릭 코어
- **PE 배열**: 4×4, 각 PE는 INT8 MAC(signed 8-bit × signed 8-bit → 32-bit 누산)
- **피처 버퍼**: A/B 핑퐁 각 16 KB, 각각 4× RAMB36E1
- **가중치 RAM**: 160× RAMB18E1 (4-포트 병렬 로드)
- **바이어스 RAM**: 7× 128-bit 엔트리
- **컨트롤 디스크립터 RAM**: 64× 128-bit
- **AXI4-Lite 메모리맵** (SoC 범위: 0x8000\_1000–0x8000\_10FF, 256 바이트):
  - 0x00: CTRL, 0x04: STATUS, 0x08: VERSION
  - 0x10: DMA\_ADDR, 0x14: DMA\_DATA
  - 0x18: RES\_ADDR, 0x1C: RES\_DATA
  - 0x20–0x2C: INSTR\_W0–W3, 0x30: INSTR\_ADDR
- **클럭**: 100 MHz 제약, WNS +0.621 ns → Fmax 약 106.62 MHz
- **합성 자원** (Artix-7 200T 기준, Vivado):
  - LUT 6199 (4.63%), FF 10316 (3.86%), BRAM 타일 88 (24.11%), DSP48E1 16 (2.16%)

## 검증·재현성

- 테스트벤치 10개; iverilog/Vivado 시뮬레이션으로 Python int 황금 모델과 대조
- 9812 원소 대조, 불일치 0건
- 빌드: `run_a200t.bat`으로 Vivado OOC 합성; 핀 배정 없어 비트스트림 없음
- 보드 실물 테스트 없음 (OOC IP 전용)

## 한계·위험

- **Basys3 불가**: BRAM 88타일 필요 → Basys3 총 BRAM18 100개 (BRAM36 50개)로 부족
- 채널 수는 반드시 4의 배수로 패딩 필요
- 고정 4×4 배열, 동적 재구성 없음
- OOC 전용: 최상위 래퍼·핀 XDC·비트스트림 없음
- 양자화는 추론 전용(PTQ 가정); QAT 지원 없음

## 재사용 메모

가져올 부분: AXI4-Lite 슬레이브 등록 맵 설계(CTRL/STATUS/DMA 패턴), INT8 MAC PE 아키텍처, 피처 버퍼 핑퐁 패턴.

**개조**: MicroBlaze V AXI4-Lite 환경으로의 이식 가능성.
- 옮길 수 있는 것: AXI4-Lite 슬레이브 FSM, CTRL/STATUS/VERSION 레지스터 패턴, 피처 버퍼 핑퐁(BRAM 수 감소), PE 배열 INT8 MAC 로직.
- 옮길 수 없는 것: 88-타일 BRAM 구성(Basys3 한계 초과); 4×4 고정 배열은 Basys3의 50 BRAM36을 초과하므로 2×2 축소 버전으로만 가능.
- 동결 맵 적용: `free_slots`의 64KB 슬롯(0x8000\_0000 대역) 중 하나에 배정하되, 현 메모리맵(0x8000\_1000)은 충돌 여부 별도 확인 필요.
- 근거 카드: tb-rohan-int8-cnn-accelerator (본 카드).
