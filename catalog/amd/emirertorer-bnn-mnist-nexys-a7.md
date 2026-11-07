---
name: emirertorer-bnn-mnist-nexys-a7
url: https://arxiv.org/abs/2512.19304
source_type: paper
vendor: amd
board: [Nexys-A7-100T]
fit_basys3: no
cpu: none(BNN 완전연결 추론 엔진)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [accelerator, debug]
stage: T4
license: unknown
stats: {stars: unverified, commits: unverified, last_update: 2025}
doc_language: en
verification: L3
checked_at: 2026-11-07
rechecked_at: 2026-11-07
sources: [https://arxiv.org/abs/2512.19304, https://github.com/EmirErtorer/Binary_Neural_Network_Implementation_For_Handwritten_Digit_Recognition_On_FPGA]
---

## 요약

Nexys A7-100T(XC7A100T)에서 순수 Verilog 1-bit BNN(이진 완전연결 신경망) 추론 가속기로 MNIST 필기 숫자를 인식. 아키텍처: 784→128→64→10 FC(모두 1-bit 이진화), XNOR+팝카운트. 97.78% BRAM(132/135)이 핵심 병목이며, 이는 Basys3(50 BRAM)에 직접 이식이 불가능한 이유다(S6 실패 교훈).

## 구조

- 보드: Nexys A7-100T (XC7A100T, BRAM 135개). 클럭: 80 MHz
- **BNN FC 아키텍처** (모든 가중치·활성화 1-bit):
  - 층 1: 784 입력 → 128 뉴런 (XNOR+팝카운트 → 임계값 비교 → 1-bit 출력)
  - 층 2: 128 → 64
  - 층 3: 64 → 10 (다중 클래스 출력, 최대값 선택)
  - 가중치 총 수: (784×128 + 128×64 + 64×10) × 1-bit = ~110,208 비트 ≈ 13.5 KB (BRAM 적재)
  - 연산: 승산기 없음(DSP 미사용). XNOR + 팝카운트만으로 추론
- **자원 사용 (Nexys A7-100T)**:
  - LUT: 26.02%
  - FF: 8.41%
  - **BRAM: 97.78% (132/135)** ← 극한 BRAM 사용, Basys3 이식 불가 근거
  - DSP: 0 (승산기 미사용 증거)
- **추론 지연**: 17,845 ns @ 80 MHz = 약 1,428 클럭 사이클
- **정확도**:
  - 소규모 테스트(100장): 84%
  - 전체 MNIST 테스트셋(10,000장): 87.97%
- **출력**: 7세그먼트 디스플레이 (숫자 0~9). VGA·카메라 없음
- **입력**: MNIST 픽셀 데이터를 직접 하드웨어에 주입(카메라 없음)

## 검증·재현성

- arXiv 논문(2512.19304)에 자원 사용 수치·정확도·추론 지연 기재
- Vivado 합성 후 보드 동작 확인 (논문에 "implemented and tested on Nexys A7-100T" 명시)
- GitHub 저장소 공개(EmirErtorer/Binary_Neural_Network_Implementation_For_Handwritten_Digit_Recognition_On_FPGA)
- BRAM 97.78% 사용: 소형 FPGA로 이식 시 반드시 가중치 압축 또는 BRAM-외 저장 방식 필요
- 커밋 수 미확인(GitHub MCP 범위 외)
- 라이선스 미확인(LICENSE 파일 존재 여부 unverified)

## 한계·위험

- **Basys3 이식 불가(no)**: BRAM 132/135 필요 → Basys3 50 BRAM의 2.6배 초과. 직접 포팅 없음
- 카메라·VGA 없음: 완전한 에지 AI 파이프라인이 아니라 추론 엔진 단독
- 정확도 87.97%: 고정소수점 대비 낮음(BNN 본질적 정확도 한계)
- FC 전용: 합성곱 없어 공간 특징 추출 없음(MNIST 한정, 범용 비전 불가)
- 라이선스 unknown: 코드 반입 전 확인 필요
- 가중치 수 최소화(극한 압축)에도 BRAM 초과 → Basys3에서 BNN FC를 돌리려면 층·뉴런 수 대폭 축소 필요(내 판단: 784→32→16→10 수준)

## 재사용 메모

- Basys3 이식 불가(fit_basys3: no): XC7A100T의 BRAM 135개 대 Basys3 50개. 단순 포팅은 불가능. 단, **BNN 아키텍처 자체**는 XC7A35T에서도 층·폭을 줄이면 작동 가능. 내 판단: 784→32→16→10 (가중치 ≈ 25,600 + 512 + 160 = 26,272 비트 ≈ 3.3 KB → 7 BRAM 이하)으로 축소 시 Basys3에서 동작 가능성 있음(단, 정확도 저하 예상).
- S6 실패 교훈 직접 활용: BRAM 97.78% = "BRAM이 병목인 BNN FC 설계의 한계선". 가중치 비트 수 × 층 × 채널을 미리 계산해 타깃 보드 BRAM 용량 이내로 설계해야 함. 카드 `rajmali-22-fpga-zebra-crossing-camera`의 BCNN(BRAM 38%)과 비교: 합성곱 계층화(BNN) + 작은 FC 출력(1개)이 FC 전용보다 BRAM 효율이 높음.
- S2 조합 탐색: BNN FC 추론 엔진 + OV7670 카메라 전처리(rajmali-22 카드에서 분리 가능한 8×8 평균·SCCB 모듈)를 결합하면 Basys3 한도 내 완전 파이프라인이 될 수 있음. → 아이디어 I-140으로 등록.
- 개조: MicroBlaze V SoC로 통합 시 — ① BNN FC 엔진을 AXI4-Lite 슬레이브로 래핑(레지스터: 입력 784비트, 트리거, 출력 4비트 클래스 결과, 상태) ② 가중치를 AXI를 통해 초기화하거나 BRAM 초기값(.mem 파일)으로 고정 ③ MicroBlaze V C 드라이버가 추론 트리거·결과 읽기 담당. 옮길 수 없는 것: Nexys A7 XDC 핀맵, BRAM 용량 의존 아키텍처(층 축소 없이는 Basys3 적재 불가).
- T4 완성형으로, BNN FC 추론 엔진의 BRAM 한계를 보여 주는 대표 사례(S6). rajmali-22(BNN BCNN)와 본 카드(BNN FC)의 BRAM 효율 비교는 atlas/edge-ai-inference-pipeline.md에 추가 예정.
