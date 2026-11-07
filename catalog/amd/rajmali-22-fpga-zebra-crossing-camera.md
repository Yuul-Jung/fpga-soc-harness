---
name: rajmali-22-fpga-zebra-crossing-camera
url: https://github.com/Rajmali-22/fpga-zebra-crossing-camera
source_type: repo
vendor: amd
board: [EDGE-Artix-7]
fit_basys3: needs-port
cpu: none(1-bit BNN 전용 엔진)
language: Verilog
tools: [Vivado 2024.2]
bus: none
peripherals: [camera, video-vga, comm-uart, debug]
stage: T4
license: MIT
stats: {stars: 0, commits: 2, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-07
rechecked_at: 2026-11-07
sources: [https://github.com/Rajmali-22/fpga-zebra-crossing-camera]
---

## 요약

EDGE Artix-7(XC7A35T) 보드에서 OV7670 카메라로 실시간 횡단보도 감지를 수행하는 완결형 엣지 AI 추론 파이프라인. 프로세서·OS·GPU·승산기 없이 순수 Verilog RTL 1-bit BNN(BCNN)으로 26.7 fps 카메라 스트림을 34 ms 안에 처리하고 결과를 VGA에 오버레이해 출력한다.

## 구조

- 보드: EDGE Artix-7 (XC7A35T — Basys3와 동일 칩)
- 클럭: MMCM 1개 → 133.33 MHz(카메라·SDRAM·UART), 66.7 MHz(BCNN 코어), 25 MHz(VGA), 21.33 MHz(카메라 XCLK)
- **카메라 → 전처리**: OV7670 RGB565 640×480, 26.7fps. SCCB로 초기화. 8×8 블록 평균 → 80×60 그레이스케일 입력
- **BCNN 추론 파이프라인**:
  - 1-bit 이진 합성곱층 4개: 3×3 커널, 채널 수 32→64→64→64, 각 층 뒤 2×2 MaxPool
  - 완전연결층(FC): 960→1 (스코어 출력)
  - 연산 방식: XNOR + popcount (승산기 없음), BatchNorm+부호를 뉴런당 정수 임계값 1개로 접기
  - 가중치: 93,408개 × 1-bit = 11.4 KB (전량 온칩 BRAM에 적재)
  - 처리량: 2,269,477 클럭 × 1/66.7MHz = 34.0 ms/프레임 (카메라 37.5 ms보다 짧아 실시간 성립)
- **출력**: VGA 640×480, 25MHz. 색상 보더(초록·노랑·빨강·회색), 80×60 네트워크 뷰 인서트, 판별 배너, 스코어 바, FPS 표시. 추가로 16×2 LCD, LED, 버저, UART(5.33 Mbaud)
- **자원 사용 (XC7A35T)**:
  - LUT: 3,370 / 20,800 (16%)
  - FF: 2,730
  - BRAM: 19 / 50 (38%)
  - DSP: 1
  - MMCM: 1
- **소비전력**: 전체 약 0.29 W (Vivado 추정). BCNN 코어 단독 22 mW
- 훈련: PyTorch STE(Straight-Through Estimator) + ResNet-18 디스틸레이션. 골든 모델(Python)과 비트 단위 일치 확인

## 검증·재현성

- Vivado 2024.2 Tcl 스크립트(`vivado/create_project.tcl`, `build.tcl`)로 완전 재현 가능
- SPI 플래시 프로그래밍 지원(전원 차단 후 복원)
- 보드에서 실제 동작 확인: "bit-exact on the board" 명시
- 커밋 수 2개. SHA 미확인(GitHub MCP 범위 외)

## 한계·위험

- 보드가 EDGE Artix-7 커스텀 보드. OV7670 전용 카메라 헤더·LCD·버저가 Basys3에 없음 → XDC 재작성 필요
- 단일 클래스 판별(횡단보도 있음/없음). 10클래스 등 다중 분류로 확장 시 FC 출력을 늘려야 함
- 커밋 수가 2개로 매우 초기 상태. 문서 외 주석 미흡 가능
- SDRAM은 없고 BNN 가중치를 BRAM에만 보관(데이터 집약 모델 저장 불가)

## 재사용 메모

- Basys3 이식(needs-port): XC7A35T 동일 칩. LUT 16%·BRAM 38%로 Basys3 한도(LUT/BRAM) 여유 있음. OV7670은 Pmod 핀으로 연결, VGA는 온보드 사용 가능. LCD·버저는 Pmod 대체 또는 제거. XDC 파일 전면 교체가 핵심 작업.
- 개조: MicroBlaze V SoC로 통합 시 — BCNN 코어를 AXI4-Lite 슬레이브 IP로 래핑하고, 가중치 로드(BRAM 초기화) 및 추론 트리거·결과 읽기를 MicroBlaze V C 드라이버에서 담당. BCNN 자체는 CPU 비종속(순수 FSM). 동결 맵 슬롯에서 IP 주소 배정 필요.
- 카메라 전처리 블록(SCCB 초기화, 8×8 평균, RGB→Gray)은 독립 모듈로 분리 재사용 가능.
- 엣지 AI 추론 파이프라인 단계(카메라 → 전처리 → 추론 → 출력) 전체를 한 저장소에서 볼 수 있는 드문 사례.
- T4 완성형으로, 엣지 AI 추론 파이프라인 주제의 직접 근거 카드로 사용.
