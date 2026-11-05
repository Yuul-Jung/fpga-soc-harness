---
name: mdpi-parallel-crc-fpga-electronics-2021
url: https://mdpi.com/2079-9292/10/7/866
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(전용 하드웨어)
language: Verilog
tools: []
bus: none
peripherals: []
stage: T2
license: CC-BY 4.0 (MDPI 오픈 액세스, 추정 — 미열람 확인 필요)
stats: {stars: 0, commits: 0, last_update: 2021-04-02}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://mdpi.com/2079-9292/10/7/866, https://www.bohrium.com/paper-details/parallel-computation-of-crc-code-on-an-fpga-platform-for-high-data-throughput/812479786814275585-4412, https://openaccess.library.uitm.edu.my/Record/doaj-43233d97412249d0bcbe51220e20fb9a]
---

## 요약

FPGA 플랫폼에서 고속 데이터 처리를 위한 병렬 CRC 계산 방법을 제시한 MDPI Electronics 논문 (Vol.10, No.7, Art.866, 2021). 병렬 XOR 행렬 전개(galois field 행렬 연산)를 FPGA에 직접 구현해 처리량을 직렬 방식 대비 대폭 향상시키는 아키텍처를 다룬다. DOI: 10.3390/electronics10070866.

## 구조

- 접근법: 병렬 CRC — 입력 데이터 w비트를 한 클럭에 처리하는 조합 논리 XOR 트리
- unverified: 구체적 대상 FPGA 모델 (검색 결과에서 "FPGA Platform"만 확인, Artix-7 여부 미열람)
- unverified: 사용 도구(Vivado/Quartus), 자원 사용량(LUT/FF), 최대 클럭 주파수 (논문 미열람)
- unverified: 저자명 (검색 결과에서 미확인, 논문 직접 열람 필요)
- unverified: 소스 코드 공개 여부 (논문 내 Verilog 코드 스니펫 가능성 있으나 미확인)

## 검증·재현성

- MDPI Electronics는 오픈 액세스 저널 — 논문 PDF 열람 가능(PROVENANCE_REQUIRED로 현재 차단)
- Bohrium.com 미러와 UiTM 도서관 레코드에서 메타데이터 확인 (L2)
- unverified: 처리량 수치, 비교 대상 직렬 구현, FPGA 보드 모델, 합성 결과

## 한계·위험

- 논문에서 제시하는 구현이 특정 FPGA 에 종속될 경우 Basys3로 포팅 필요
- 소스 코드 공개 여부 불명 — 논문 내 코드만 존재할 경우 직접 활용 어려움

## 재사용 메모

가져올 수 있는 부분: 병렬 CRC XOR 행렬 전개 방법론 — 논문에서 제시하는 계수 행렬(T 행렬) 계산법을 Basys3의 Verilog CRC IP 설계 기준으로 활용. CRC 너비(8/16/32)와 데이터 버스 너비(8/32/64비트)에 따른 LUT 추정 방법도 활용 가능.

개조: 논문의 행렬 전개식을 `crc32_core.v`의 조합 논리 XOR 트리로 직접 구현 → 단독 모듈로 만든 뒤 AXI4-Lite 래퍼(`crc32_axil.v`)로 감싸 MicroBlaze V SoC에 연결. 못 옮기는 부분: 논문 Verilog 코드(오픈 액세스이나 라이선스 별도 명기 필요) — 복사 대신 사양 기반 자체 RTL 작성.
