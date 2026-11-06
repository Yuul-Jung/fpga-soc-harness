---
name: xie-2020-tvlsi-twofold-lut-tanh
url: https://doi.org/10.1109/TVLSI.2020.3015391
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(DSP)
language: VHDL
tools: [Vivado]
bus: none
peripherals: [activation-function]
stage: T4
license: unknown
stats: {stars: 해당없음, commits: 해당없음, last_update: 2020}
doc_language: en
verification: L2
checked_at: 2026-11-06
sources: [https://doi.org/10.1109/TVLSI.2020.3015391, https://www.bib.irb.hr/1075526]
---

## 요약

IEEE Transactions on VLSI Systems 2020 게재 논문. 단일 대형 LUT 대신 d-LUT(근사값 저장)와 e-LUT(오차 보정값 저장)를 조합하는 Twofold LUT 기법으로 FPGA/ASIC 활성화 함수(tanh, sigmoid) 면적을 94.44% 절감한다. (검색 결과 요약 기준 L2 — IEEE 전문 미열람)

## 구조

- 방법: Twofold LUT (이중 룩업 테이블)
  - d-LUT: 활성화 함수 근사값 저장 (주 추정기)
  - e-LUT: 오차 보정값 저장 (잔류 오차 보상기)
  - 최종 출력 = d-LUT[x] + e-LUT[x]
- 추가 변형: RALUT(Random Access LUT) 조합 → 추가 10.21% 면적 절감
- 지연: 39.721 ns @ 50 MHz (tanh 기준, 논문 보고 수치)
- 함수: tanh, sigmoid (다른 단조 함수로 확장 가능)
- 입출력 비트폭: unverified (IEEE 전문 미열람)
- 목표 플랫폼: FPGA(Xilinx 계열 추정) 및 ASIC

## 검증·재현성

- 단일 LUT 대비 94.44% 면적 절감 (논문 보고 수치, 출처: bib.irb.hr 메타데이터)
- RALUT 추가 적용 시 추가 10.21% 절감
- 지연 39.721 ns (@ 50 MHz, tanh 기준)
- 정확도 손실 허용 범위: unverified (IEEE 전문 미열람)
- 오픈소스 구현: 미확인

## 한계·위험

- IEEE 전문 접근 불가 (DOI만 확인, 크로아티아 참고문헌 메타데이터 bib.irb.hr 경유)
- Basys3 명시 없음; Artix-7 BRAM/LUT 매핑은 직접 포팅 필요
- 2020년 논문, 오픈소스 구현 미확인
- 언어·정확한 비트폭·목표 FPGA 모델: unverified (IEEE 전문 미열람)

## 재사용 메모

- Basys3 포팅 가능성(needs-port): d-LUT + e-LUT 각 소용량 BRAM으로 구성 → Basys3 225 KB BRAM 범위 내 (내 판단)
- 내 판단: 8비트 입력 기준 d-LUT 256×8b + e-LUT 256×4b ≈ 3 KB 추정, XC7A35T에서 1 BRAM 블록 이내
- Basys3 제약 역전(S4): 단일 큰 BRAM ROM 대신 2개의 작은 BRAM으로 tanh/sigmoid 구현 → BRAM-bound 제약을 오히려 고압축 설계로 역이용
- S1 인접 도메인: MCU 소프트웨어 sigmoid/tanh LUT 구현 아이디어를 하드웨어 Twofold LUT로 이식하는 패턴
- 개조: MicroBlaze V SoC 추론 파이프라인에 AXI4-Lite 래퍼로 연결. d-LUT/e-LUT는 초기화 시 AXI로 쓰고, 추론 시에는 조합 읽기. 옮길 수 없는 것: 논문의 ASIC 면적 수치(28nm CMOS) → Artix-7 LUT 등가 추정 별도 필요.
