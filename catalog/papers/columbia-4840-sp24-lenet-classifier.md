---
name: columbia-4840-sp24-lenet-classifier
url: https://www1.cs.columbia.edu/~sedwards/classes/2024/4840-spring/reports/LeNet-Classifier-report.pdf
source_type: report
vendor: intel
board: [DE1-SoC]
fit_basys3: needs-port
cpu: HPS(ARM-Cortex-A9) + 커스텀 LeNet 가속기 FSM
language: SystemVerilog
tools: [Quartus, ModelSim, Verilator]
bus: Avalon-MM
peripherals: [camera, accelerator, debug]
stage: T3
license: unknown
stats: {stars: unverified, commits: unverified, last_update: 2024}
doc_language: en
verification: L3
checked_at: 2026-11-07
rechecked_at: 2026-11-07
sources: [https://www1.cs.columbia.edu/~sedwards/classes/2024/4840-spring/reports/LeNet-Classifier-report.pdf]
---

## 요약

Columbia CS4840(임베디드 시스템) 2024년 봄 학기 과제. DE1-SoC에서 OV7670 카메라로 입력을 받아 커스텀 LeNet을 FPGA에서 실행하고 결과를 7세그먼트에 출력한다. HPS(ARM)와 FPGA가 Avalon-MM으로 협력하며, 90.86% 분류 정확도와 각종 실패 사례가 보고서에 상세히 기록되어 있다.

## 구조

- 보드: DE1-SoC (Cyclone V). HPS(ARM Cortex-A9 1GHz) + FPGA 25k LE
- 버스: Avalon-MM (HPS→FPGA 슬레이브 레지스터)
- **카메라 파이프라인**: OV7670 RGB565 640×480 → 80×60 그레이스케일 다운샘플(HPS 소프트웨어) → 42×42 센터 크롭 → FPGA 로컬 메모리 적재
- **커스텀 LeNet 아키텍처** (Q4.4 고정소수점):
  - 입력: 42×42 그레이스케일 1채널
  - Conv 층 1: 5×5 커널 × 6채널, ReLU, 2×2 MaxPool → 19×19×6
  - Conv 층 2: 5×5 커널 × 16채널, ReLU, 2×2 MaxPool → 7×7×16
  - 완전연결(Dense): 784→324→10, ReLU + 소프트맥스
  - 가중치: HPS DRAM에 저장, 추론 전 Avalon을 통해 FPGA 로컬 메모리에 로드
- **FSM**: 21상태 메인 FSM이 추론 단계(가중치 로드, 합성곱 계산, 풀링, FC, 출력)를 순차 제어
- **출력**: DE1-SoC 온보드 7세그먼트 (숫자 0~9 표시)
- **정확도**: 90.86% (MNIST 10,000개 테스트 기준)

## 검증·재현성

- ModelSim 기능 시뮬레이션 + Verilator 테스트벤치로 각 층 단위 검증
- Quartus 합성 후 DE1-SoC 보드에서 실제 동작 확인 (카메라 → 7세그 출력)
- 가중치는 Python(PyTorch/Keras) 학습 → C 헤더로 변환 → HPS에서 로드
- 자원 사용: 보고서에 Quartus 보고 없음 (unverified)
- 보고서에 실패 사례 상세 기록 (§S6 교훈):
  - 클럭 도메인 불일치로 첫 버전 FSM 오동작 → 동기화 로직 추가
  - Avalon 레지스터 주소를 하드코딩해 유지보수성 저하
  - Q4.4 고정소수점 오버플로우: 내적 계산 중 중간값 비트폭 초과 → 32비트 임시 누산기로 해결
  - Conv 2층의 패딩 오류로 경계 픽셀 오분류 → 보고서에 미해결로 기록

## 한계·위험

- Intel/Altera 전용: Cyclone V HPS, Avalon-MM 버스. FPGA 단독 추론이 아니라 HPS+FPGA 협력 구조
- 7세그먼트 단독 출력 — VGA 없음
- 가중치 적재가 HPS DRAM 의존. Basys3(no-dram)에선 BRAM 용량 초과 위험
- 라이선스 불명: 대학 과제 보고서, 소스코드 별도 공개 여부 unverified
- 보고서 외 소스코드 저장소 URL 미확인 (GitHub 별도 공개 여부 불명)
- 경계 픽셀 오분류 미해결 (보고서 §6 한계)

## 재사용 메모

- Basys3 이식(needs-port): Cyclone V HPS·Avalon-MM 없음. CPU 없는 순수 FSM 구조로 재설계 필요. 42×42 LeNet 가중치는 Q4.4 기준 약 400KB(DRAM 의존) → 경량화 없이는 Basys3 BRAM에 적재 불가. 단, Conv 층 가중치를 BNN화(1-bit)하면 BRAM 내 적재 가능성 증가.
- S6 실패 교훈 직접 활용: ① Q4.4 비트폭 → 중간 누산기를 항상 2배 폭(8비트) 이상 확보 ② 고정소수점 오버플로우는 클리핑 또는 Sat 연산으로 방어 ③ 하드코딩 주소 대신 `config/soc_address_map.json` 동결 맵 슬롯 사용 ④ 클럭 도메인은 처음부터 단일 도메인으로 설계
- 개조: MicroBlaze V SoC로 통합 시 — ① HPS 역할을 MicroBlaze V C 드라이버로 대체 ② Avalon-MM 대신 AXI4-Lite 슬레이브 IP로 래핑 ③ 카메라 전처리(80×60 다운샘플·42×42 크롭)를 AXI Stream 모듈로 분리 ④ 가중치를 `free_slots`의 한 64KB 영역 BRAM에 로드하는 초기화 드라이버 필요. Conv 층 FSM(21상태)은 CPU 비종속이므로 AXI 슬레이브 래핑 가능. 옮길 수 없는 것: Avalon 버스 계층, Cyclone V HPS 전용 메모리 접근.
- 단계 T3이므로 T4 BNN 카드(`rajmali-22-fpga-zebra-crossing-camera`)와 조합 탐색(S2): HPS 없이 순수 FSM LeNet을 BNN화 → 완전 하드웨어 추론 파이프라인 아이디어로 연결 가능.
