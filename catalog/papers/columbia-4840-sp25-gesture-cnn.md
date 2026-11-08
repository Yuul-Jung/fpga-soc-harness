---
name: columbia-4840-sp25-gesture-cnn
url: https://www1.cs.columbia.edu/~sedwards/classes/2025/4840-spring/reports/Gesture-report.pdf
source_type: paper
vendor: intel
board: [Cyclone-V-DE1-SoC-class]
fit_basys3: needs-port
cpu: none(CNN-accelerator)
language: SystemVerilog
tools: [Quartus, Python-Keras]
bus: Avalon
peripherals: [sensor]
stage: T4
license: unknown
stats: {stars: unknown, commits: unknown, last_update: 2025}
doc_language: en
verification: L3
checked_at: 2026-11-08
source_rev:
sources: [https://www1.cs.columbia.edu/~sedwards/classes/2025/4840-spring/reports/Gesture-report.pdf, https://www1.cs.columbia.edu/~sedwards/classes/2025/4840-spring/designs/Gesture.pdf]
---

## 요약

Columbia CSEE4840 Embedded System Design 과목(2025년 봄) 프로젝트. Cyclone V FPGA+ARM Cortex-A9 HPS(Linux)에서 Q8.8 고정소수점 4합성곱+2완전연결 계층 CNN 가속기를 SystemVerilog로 구현해 수어 손짓(0~9 숫자) 10클래스를 93% 정확도로 분류한다. 카메라 없이 32×32 JPEG 파일을 소프트웨어로 파싱해 하드웨어 가속기에 전달한다.

## 구조

- **입력**: 32×32 컬러 이미지(소프트웨어에서 다운샘플), 3채널, Q8.8 고정소수점
- **CNN 아키텍처**: 합성곱 4개(3×3 커널, ReLU, 일부 max-pooling) + 완전연결 2개, 총 파라미터 미기재(훈련은 PyTorch)
- **레이어별 BRAM 사용**: Layer1 72KB, L2 154KB, L3 88KB, L4 333KB, L5 33KB, L6 1.4KB → 총 681.4KB (Cyclone V 기준 69% BRAM)
- **MAC 유닛**: Q8.8 병렬 9-입력 MAC(DSP 블록 맵핑), 슬라이딩 윈도 레지스터로 행당 3값만 새로 읽음
- **소프트웨어(HPS)**: Linux C 드라이버, Avalon 메모리맵 인터페이스, ioctl로 레이어 파라미터 적재 및 제어
- **자원(Cyclone V)**: ALM 1,498/32,070(5%), BRAM 2,785,424 bits(69%), DSP 21/87(24%), 핀 362/457(79%)
- **클럭**: Fmax 44 MHz 추정(실제 설정 25ns=40 MHz, 보고서 불일치)
- **정확도**: Python float 92→94.84%(스케일 보정), C 고정소수점 90.86%

## 검증·재현성

- Columbia PDF 보고서와 설계 문서 직접 열람(L3)
- GitHub 링크 없음: 소스 코드 접근 불가
- 훈련 데이터: Sign Language Digits Dataset (GitHub: ardamavi/Sign-Language-Digits-Dataset)
- 도구: Quartus(합성), Python/PyTorch(훈련), C(드라이버)

## 한계·위험

- 카메라 없음: 오프라인 JPEG 파일 입력만 지원
- Q8.8 정밀도 손실: 가중치가 [-1,1] 범위로 소수 비트 낭비
- 레이어별 가중치 재적재 필요(전체 BRAM에 동시 적재 불가)
- Cyclone V HPS(ARM+FPGA SoC) 의존: Basys3(순수 FPGA)로 직접 이식 불가
- Avalon 버스 → AXI4-Lite 변환 필요
- Fmax 44 MHz vs 설정 40 MHz 불일치(보고서 오류 가능)
- 흰 배경 훈련 데이터에 과적합

## 재사용 메모

Cyclone V HPS 기반이지만 Q8.8 고정소수점 MAC 유닛 설계와 레이어별 가중치 로딩 패턴, 슬라이딩 윈도 레지스터 접근법은 Basys3로 이식 가능한 아이디어를 제공한다. BRAM 681KB 요구는 Basys3의 225 Kbits를 초과하므로 그대로 이식 불가.
개조(MicroBlaze V 기준): ① 모델 축소(레이어 수 줄이기, 채널 축소)로 BRAM 사용량을 ≤180 KB로 낮춤 ② Avalon 인터페이스 → AXI4-Lite 슬레이브로 교체 ③ 가중치를 MicroBlaze V에서 UARTで 적재하거나 Flash(SPI) 부팅으로 처리 ④ 카메라 입력(OV7670 32×32 ROI) 추가는 kurokishi592-ee2026 블롭 ROI 접근법과 결합 가능(내 판단). 최소 모델(conv1 4채널, conv2 4채널, FC 10)은 Basys3 BRAM에 들어갈 가능성이 있다(내 판단: 개조 필요).
