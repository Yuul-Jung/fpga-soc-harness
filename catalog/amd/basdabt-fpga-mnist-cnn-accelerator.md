---
name: basdabt-fpga-mnist-cnn-accelerator
url: https://github.com/BasdaBT/FPGA-MNIST-CNN-Accelerator
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [seven-segment]
stage: T2
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-08
source_rev:
sources: [https://github.com/BasdaBT/FPGA-MNIST-CNN-Accelerator]
---

## 요약 (3줄)
Basys3(xc7a35tcpg236-1) 대상 Verilog CNN 추론기. MNIST 28×28×1 입력에 대해 Conv3×3(4필터, 32비트 누산) → 2×2 MaxPool → FC×3(32,32,10) 파이프라인. 100 MHz 오실레이터를 DIV_TOGGLE=5로 분주해 ~10 MHz CNN 클럭 사용. BRAM에 가중치를 `$readmemh`로 로드하며 출력은 7세그먼트 표시.

## 구조
- 입력: 28×28×1 uint8 → Block ROM에 저장.
- Conv: 3×3, 4필터, stride 1, ReLU, 출력 26×26×4(32비트 누산기).
- Pool: 2×2 MaxPool/stride 2 + 재양자화 → 13×13×4 int8.
- Flatten: 676값.
- FC1: 676→32(ReLU, 재양자화), FC2: 32→32(ReLU, 재양자화), FC3: 32→10, Argmax.
- 가중치: 9개 hex 파일을 `$readmemh`로 BRAM에 로드.
- 출력: 7세그먼트(AN0) + led[0] 완료 신호. VGA 없음.
- 레이어 간 start/done 1클럭 펄스로 조정.
- 클럭 분주: 100 MHz → ~10 MHz(DIV_TOGGLE=5).

## 검증·재현성
- 타깃 파트 명시: `xc7a35tcpg236-1`(Basys3 정확히 일치).
- 자원: 미기재(Vivado 재실행 없음 명시).
- WNS: 미기재.
- 테스트벤치·CI: README 미언급.
- 보드 동작: README가 Basys3 대상임 선언; 실측 사진·로그는 미첨부.

## 한계·위험
- 라이선스: "No open-source license is currently provided"(원문). 교육적 참고 목적 외 재사용 전 저자 허락 필요.
- 자원·타이밍 데이터 없음.
- 10 MHz 저속 CNN 클럭: MNIST 추론에는 충분하나 실시간 카메라 피드에는 부족할 것(내 판단).
- VGA 없음. 출력이 7세그먼트에 한정.
- CIFAR-10·컬러 이미지 미지원: 단일 채널(흑백) 전용.
- 자원 미기재로 Basys3 LUT/BRAM 여유 불명.

## 재사용 메모
- BRAM-only(외부 메모리 불필요) 소형 CNN의 Basys3 Verilog 구현 패턴. `$readmemh` 가중치 로드와 start/done 핸드셰이킹은 AXI4-Lite 슬레이브로 교체하기 쉬운 구조.
- 개조: 가중치 로드를 AXI4-Lite 레지스터 뱅크(동결 맵 free_slots 배정)로 교체하면 MicroBlaze V에서 가중치 프로그래밍 + 추론 제어 가능. CIFAR-10(32×32×3) 적용 시 conv 입력 채널 3으로 늘리고 pooling 출력 크기 재계산 필요(내 판단). CPU·버스 없는 순수 FSM 구조라 MicroBlaze V 연결 시 AXI4-Lite 슬레이브 래퍼 추가 필요. 10 MHz → 25 MHz 이상으로 클럭 올리면 추론 속도 향상 가능.
