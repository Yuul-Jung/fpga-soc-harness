---
name: richielee-2025-tiled-matmul-attention-kv260
url: https://arxiv.org/abs/2503.16731
source_type: paper
vendor: amd
board: [KV260]
fit_basys3: needs-port
cpu: none(가속기 전용, PYNQ 호스트 연동)
language: HLS(C/C++)
tools: [Vivado HLS, PYNQ]
bus: AXI
peripherals: []
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2025-03-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://arxiv.org/abs/2503.16731, https://github.com/Richielee630/MatMul_SA, https://github.com/Richielee630/TMMA]
---

## 요약

Li & Chen (UC Irvine, 2025) "Design and Implementation of an FPGA-Based Tiled Matrix Multiplication Accelerator for Transformer Self-Attention on the Xilinx KV260 SoM."
KV260 SoM(XCK26, Zynq UltraScale+)에서 DistilBERT의 Q/K/V 선형 투영 행렬 곱을 INT8 타일 방식으로 가속.
Softmax는 FPGA에 구현되지 않았고 향후 작업으로 남겨짐. 소스 코드 GitHub 공개.

## 구조

- FPGA: Xilinx Kria KV260 SoM (XCK26, Zynq UltraScale+)
- 양자화: INT8 대칭 양자화 (고정 스케일, PyTorch 정적 양자화로 가중치 사전 양자화)
- 출력: INT32; 호스트에서 fp32로 역양자화
- 타일 행렬 곱(TMMA): 타일 단위로 BRAM에 가중치 적재 후 PE 배열 계산
- Q/K/V 선형 투영 가속: FPGA 담당
- Softmax, V에 대한 주의 가중치 곱셈: 미구현 (future work)
- 자원 사용 (100 MHz):
  - BRAM: 126/144 (88%)
  - DSP48E: 1,040/1,248 (83%)
  - FF: 102,741 (43%)
  - LUT: 71,050 (60%)
- 클럭: 100 MHz PL

## 검증·재현성

- 소규모 테스트 행렬에서 CPU 계산과 정확히 일치 확인
- DistilBERT 어텐션 출력이 양자화 참조값 대비 0.5% 미만 오차
- CPU 예측 신뢰도 99.95% → FPGA 99.80% (DistilBERT MNLI)
- GitHub 소스(HLS 설계): https://github.com/Richielee630/MatMul_SA
- PYNQ 벤치마크 및 DistilBERT 순전파: https://github.com/Richielee630/TMMA

## 한계·위험

- KV260(XCK26)는 Basys3(XC7A35T)에 비해 BRAM 약 10×, DSP 약 14×, LUT 약 6× 큰 디바이스
- Softmax 미구현 — 완전한 어텐션 가속기가 아님; 선형 투영(MatMul) 단계만 가속
- HLS 설계이므로 Verilog/VHDL RTL 직접 이식 불가; HLS 툴 흐름 필요
- KV260은 하드 ARM CPU(PS 측)가 있어 Basys3(PL 전용)와 아키텍처가 다름

## 재사용 메모

- 타일 MatMul 접근법(타일 크기 ≤ BRAM 용량)은 XC7A35T에서도 적용 가능:
  작은 헤드 크기(d_k=16~32)와 타일 크기(8×8)로 BRAM 부담 절감
- INT8 DSP 묶음 패킹(2개 INT8 → 한 DSP18)은 Artix-7 DSP48E1에서도 사용 가능
- 개조: MicroBlaze V에서 AXI4-Lite로 MatMul 가속 IP를 제어하는 구조로 이식 가능.
  HLS 코드에서 포트·인터페이스 추출 후 RTL 자체 구현 필요(§16.3 G2: 소스 직접 복사 금지).
  free_slots에서 64KB 슬롯 제안.
