---
name: arxiv-2508-16095-nvdla-riscv-soc
url: https://arxiv.org/html/2508.16095v1
source_type: paper
vendor: neutral
board: []
fit_basys3: no
cpu: RISC-V(bare-metal)
language: Verilog
tools: []
bus: AXI4
peripherals: [NVDLA, DMA, 메모리 컨트롤러]
stage: T5
license: unknown
stats: {year: 2025, arxiv: 2508.16095}
doc_language: en
verification: L2
checked_at: 2026-11-07
unverified: 보드 사양, 자원, 소스 공개 여부 — 검색 결과 제목 열람만
sources: [https://arxiv.org/html/2508.16095v1]
---

## 요약 (3줄 이내, 내 표현으로)
RISC-V 프로세서에 NVIDIA NVDLA 딥러닝 가속기를 연결한 SoC를 FPGA에 구현한 논문(arXiv 2508.16095). 추론 효율과 메모리 대역폭 최적화를 다루는 것으로 보인다. 검색 결과 제목만 확인했다(L2).

## 구조
- 베어메탈 RISC-V 코어 + NVDLA IP + AXI4 인터커넥트 + DRAM 컨트롤러(추정, unverified).
- Basys3는 외부 DRAM 없어 직접 재현 불가(T5 수준).

## 검증·재현성
- arXiv 논문. 실험 결과 존재 가능(unverified).

## 한계·위험
- L2 열람. DRAM 필수로 Basys3 재현 불가(`fit_basys3: no`).
- NVDLA는 Nvidia 소유 IP이므로 라이선스 별도 확인 필요.

## 재사용 메모
- 내 판단: NVDLA의 레지스터 맵 설계와 DMA 제어 흐름은 MicroBlaze V NPU 래퍼 설계에 참고 가능. 직접 재현보다 패턴 추출 목적.
- 개조: NVDLA 대신 소규모 MAC 어레이를 AXI4-Lite 슬레이브로 감싼 형태로 Basys3 이식. 가중치를 BRAM에, 입력을 AXI 쓰기로 받아 추론 결과를 AXI 읽기로 출력.
- 라이선스 확인 필요.
