---
name: khan-2024-bn-hls4ml-uw
url: https://people.ece.uw.edu/hauck/publications/BatchNorm.pdf
source_type: report
vendor: neutral
board: [VC709]
fit_basys3: needs-port
cpu: none(가속기)
language: Verilog
tools: [Vivado, HLS4ML]
bus: none
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: 4, commits: 15, last_update: 2024}
doc_language: en
verification: L2
checked_at: 2026-11-06
source_rev:
sources: [https://people.ece.uw.edu/hauck/publications/BatchNorm.pdf, https://github.com/uw-acme/HLS4ML_VS_MANUAL]
---

## 요약

워싱턴 대학교(UW) 2024년 석사 논문. BN 레이어를 FPGA에 구현하는 세 가지 방법을 비트 폭 4~22비트 범위에서 정량적으로 비교한다: ① 역제곱근 LUT 방식(수동 Verilog), ② 사전 계산 scale+shift 방식(수동 Verilog), ③ HLS4ML의 비트 시프트 근사. Xilinx Virtex VC709를 대상 보드로 사용하며, GitHub에 소스 코드를 공개한다.

## 구조

- **방법 1 — 역제곱근 LUT**: C 프로그램으로 생성된 역제곱근 LUT를 이동 분산(moving variance)으로 색인. 출력: `(h − μ) × table_value`. 이후 γ, β 추가 MAC 필요. 레이턴시 3 사이클, II=1
- **방법 2 — scale+shift 사전 계산(fold)**: `scale_m = γ/√(σ²+ε)`, `offset_b = β − γμ/√(σ²+ε)`를 초기화 시 한 번만 계산하고 파라미터로 주입. 추론 시 1 MAC만 수행. 레이턴시 1 사이클, II=1. DSP 수 방법 1 대비 ~40% 절감, LUT 최대 ~90% 절감(22비트 기준)
- **방법 3 — HLS4ML 시프트 근사**: DSP 없음. `((X << W/2) − X) >> W/2`로 입력을 0 방향으로 근사 스케일링. 레이턴시 1 사이클. 오차 최대 333%로 정밀도 열세
- **비트 폭 실험**: 4~22비트, 정수부/소수부 균등 분할(예: 8비트 → Q4.4). 비트 폭 증가 시 LUT/DSP 사용량 추세 측정

## 검증·재현성

- GitHub 소스 공개: https://github.com/uw-acme/HLS4ML_VS_MANUAL/tree/main/src (Verilog RTL + 테스트벤치, Python 비교)
- 방법 2는 bit-accurate로 floating-point 기준과 일치
- HLS4ML은 최대 333% 오차 — 정밀도가 중요한 추론에 부적합
- unverified: GitHub repo 직접 열람 미완료 (소스 구조, 라이선스 미확인)

## 한계·위험

- VC709는 Basys3(XC7A35T)보다 훨씬 큰 UltraScale 보드. 자원 수치를 Artix-7으로 외삽할 때 오차 가능
- 라이선스 미확인 (GitHub repo 직접 열람 필요)
- 코드가 단일 BN 레이어 단위 측정 — 전체 CNN 파이프라인과 결합 시 타이밍/자원 재검증 필요

## 재사용 메모

- 방법 2(scale+shift fold)가 Basys3 NPU에 가장 적합. BN 파라미터를 모델 적재 시 CPU(MicroBlaze V)가 미리 계산 후 BRAM에 쓰면, 추론 엔진은 1 MAC만 추가하면 됨
- Q4.4(8비트) 고정소수점에서의 비교 결과는 Basys3 MLP·CNN 가속기의 BN 블록 설계 근거 자료로 직접 사용 가능
- 개조: MicroBlaze V AXI4-Lite 슬레이브로 `bn_scale_bram`(채널 수 × 32비트) 슬롯 1개를 `free_slots` 에서 배정. 초기화 루틴은 `config/soc_address_map.json` 동결 맵 내 빈 슬롯에 맞춰 C 드라이버 작성. GitHub 코드 직접 열람 후 L3 승격 권장
