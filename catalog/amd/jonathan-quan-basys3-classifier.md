---
name: jonathan-quan-basys3-classifier
url: https://github.com/jonathan-quan/basys3-classifier
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: unknown
tools: [Vivado]
bus: none
peripherals: [UART]
stage: T4
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-08
rechecked_at: 2026-11-08
source_rev:
sources: [https://github.com/jonathan-quan/basys3-classifier]
---

변경: language: unverified → language: unknown (2026-11-08). 소스 파일을 직접 열람하지 않아 Verilog/VHDL 불명; 카드 본문에도 "소스 파일 직접 미열람" 명시. `unverified`는 비표준 값이므로 `unknown`으로 수정.

## 요약 (3줄)
Basys3 Artix-7 XC7A35T에서 동작하는 4-class 물체 분류기. 노트북 웹캠 → USB-UART → FPGA 추론 → UART 결과 반환 파이프라인. MNIST·CIFAR-10 대신 Google Open Images 기반 Rubik's cube·펜·책·마우스 4개 클래스. 소형 MobileNet 스타일 DW/PW CNN(6,084 파라미터)을 Basys3에서 2,636 LUT·7 DSP만으로 구현.

## 구조
- 분류기(`fpga/`): 9레이어 CNN. conv3×3/s2(8ch) → DW3×3/s2+PW1×1(16ch) → DW+PW(32ch) → DW+PW(48ch) → 전역 평균 풀링 → FC4. 입력 96×96 RGB. 6,084 파라미터.
- 박스 검출기(`fpga_det/`): 11레이어, 128×128 RGB, 31,977 파라미터, 4.78M MACs, soft-argmax 박스 헤드.
- 호스트 인터페이스: 노트북 웹캠 → USB-UART → FPGA 추론 → UART 결과 반환. VGA 없음.
- HDL 언어: README가 "RTL"·Vivado만 언급; Verilog·VHDL·SystemVerilog 중 하나인지 unverified(소스 파일 직접 미열람).
- 클럭: Basys3 100 MHz 입력.
- 보드: Digilent Basys 3 (Artix-7 XC7A35T, 100 MHz) 명시.

## 검증·재현성
- Basys3 XC7A35T에서 직접 동작 확인됨(README 명시).
- 자원(분류기): 2,636 LUT, 7 DSP48E1. BRAM·FF 수 미기재.
- 박스 검출기 자원: 미기재.
- 테스트벤치·CI: 명시 없음.
- 훈련: Python 소프트웨어 모델 → 고정소수점 양자화 → Vivado 합성 흐름.

## 한계·위험
- 라이선스 파일 없음(unknown). 재사용 전 저자 허락 필요.
- HDL 언어 미확인: 소스 파일을 직접 열람하지 않아 Verilog/VHDL 불명(unverified: 소스 파일 열람 미진행).
- MNIST·CIFAR-10 아님: 전용 4-class 데이터셋. CIFAR-10 가중치로 교체 시 클래스 수·FC 출력만 변경하면 될 것으로 추정되나 미확인(내 판단).
- VGA 출력 없음. UART 기반 호스트 연동 필수.
- BRAM 사용량·WNS·타이밍 여유 미기재.

## 재사용 메모
- S4 제약 역전 사례: Basys3 25,250 LUT 중 2,636(≈10%)만 쓰는 초소형 DW/PW CNN 추론기. BRAM 없이도 MobileNet 스타일 추론이 가능함을 보여 준다.
- 개조: MicroBlaze V AXI4-Lite 슬레이브 래퍼를 추가해 가중치 ROM 베이스 주소를 동결 맵 free_slots에 배정하면 MicroBlaze V가 추론을 제어하는 IP로 전환 가능. UART 호스트 링크는 AXI4-Lite 직접 접근으로 교체. CIFAR-10(32×32×3) 입력으로 바꾸면 conv 채널 조정 필요(내 판단). CPU·버스 없는 순수 FSM 구조라 MicroBlaze V 연결 시 AXI4-Lite 슬레이브 래퍼 추가 필요.
