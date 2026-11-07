---
name: ziad-abaid-fpga-cnn-inference-accelerator
url: https://github.com/ZiadAbaid/FPGA-CNN-Inference-Accelerator
source_type: repo
vendor: amd
board: [Nexys4]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Vivado]
bus: AXI-Stream
peripherals: [SPI]
stage: T4
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-08
rechecked_at: 2026-11-08
source_rev:
sources: [https://github.com/ZiadAbaid/FPGA-CNN-Inference-Accelerator]
---

## 요약 (3줄)
Nexys 4(XC7A100T) 대상 "100% Pure VHDL" CNN 추론 가속기. RPi 5에서 8 MHz SPI로 16비트 Q8.8 입력 데이터를 스트리밍하면 FPGA 내부 AXI-Stream 파이프라인으로 추론. 100개 테스트 이미지로 소프트웨어 모델과 비트 단위 일치 검증, 100 MHz Zero WNS 달성.

## 구조
- 입력: 34×34×1(제로패딩 포함), 16비트 Q8.8 고정소수점.
- 아키텍처: Conv1(ReLU) → MaxPool1 → ZeroPad1 → Conv2(ReLU) → MaxPool2 → ZeroPad2 → Conv3(ReLU) → MaxPool3 → Flatten → Dense1 → Dense2(3-class 출력). 5레이어(conv+dense 계층 기준).
- 호스트 인터페이스: RPi 5 → 8 MHz SPI(16비트) → `spi_controller.vhd`, `spi_receiver.vhd`, `spi_transmitter.vhd`.
- 내부 버스: AXI-Stream(in_valid/in_ready 백프레셔).
- 클럭: 100 MHz.
- 자원(Nexys 4 XC7A100T 기준): LUT ~35%(≈35,504/101,440), DSP48E1 23%(≈55/240), BRAM 8%(≈11/135), Zero WNS Violations.

## 검증·재현성
- 100개 무작위 테스트 이미지로 소프트웨어 모델 대비 비트 단위 일치.
- 100 MHz Zero WNS 달성.
- 자원: LUT 35%, DSP 23%, BRAM 8%.
- 테스트벤치: 소프트웨어 대조 방식; VHDL 자체 TB 별도 확인 미진행(unverified).
- 데이터셋: 3-class 분류; 클래스 종류 미확인(unverified: 열람 범위 부족).

## 한계·위험
- 라이선스 없음(unknown). 재사용 전 저자 허락 필요.
- Basys3(XC7A35T, 20,800 LUT) 이식 시 LUT 초과: 현 설계 ~35,504 LUT → XC7A35T 한도 20,800 대비 170%. 레이어·채널 수 대폭 축소 후 포팅 필요(내 판단).
- 3-class 한정; CIFAR-10·MNIST 미명시.
- VGA 없음. SPI+RPi 호스트 필수.
- VHDL 전용: Verilog 혼용 환경에서 포팅 시 재작성 필요.

## 재사용 메모
- Pure VHDL AXI-Stream CNN 파이프라인의 완성된 구조적 참고. SPI→AXI-Stream 브리지, 다단 MaxPool+ZeroPad 조합, 고정소수점 Q8.8, Zero WNS 100 MHz 달성 경험이 실용적.
- 개조: Basys3 포팅 시 (1) conv 채널·레이어 수를 절반 이하로 축소해 LUT 20K 이하로 맞춤, (2) SPI → AXI4-Lite 교체(동결 맵 free_slots 배정), (3) VHDL → Verilog 재작성 또는 혼용. MicroBlaze V에서는 AXI4-Lite 제어 레지스터를 통해 추론 개시·결과 판독 가능. 채널 축소 후 LUT 추산: 35,504 × (1/3 채널) ≈ 12K LUT → Basys3 여유 확보(내 판단).
