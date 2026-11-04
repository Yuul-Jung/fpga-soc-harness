---
name: zediot-esp32-s3-tflite-wake-word
url: https://dev.to/zediot/esp32-s3-tensorflow-lite-micro-a-practical-guide-to-local-wake-word-edge-ai-inference-5540
source_type: article
vendor: neutral
board: [ESP32-S3]
fit_basys3: no
cpu: none(MCU 펌웨어)
language: C
tools: [ESP-IDF, TensorFlow Lite Micro, ESP-DSP]
bus: none
peripherals: [I2S 마이크, LED(결과표시)]
stage: T3
license: unknown
stats: {stars: 0, commits: 0, last_update: 2025-11-25}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://dev.to/zediot/esp32-s3-tensorflow-lite-micro-a-practical-guide-to-local-wake-word-edge-ai-inference-5540]
---

## 요약

ESP32-S3 (Xtensa LX7 240 MHz, 512 KB SRAM)에서 TFLite Micro로 오프라인 키워드 감지를 구현하는 DEV.to 튜토리얼 기사. MFCC 특징 추출(ESP-DSP 활용, 2~3 ms/프레임) → int8 양자화 CNN(Conv2D + DepthwiseConv2D + Dense + Softmax) → 추론 50~60 ms 흐름을 설명한다. 소스 코드 링크는 없고 개념 설명 중심이다.

## 구조

- 모델: 2클래스 출력(키워드 yes/no), int8 양자화, 모델 크기 약 240 KB
- 특징 추출: ESP-DSP FFT/DCT로 MFCC 계산, 2~3 ms/프레임
- 추론: 50~60 ms/추론, 환경음 분류 8~12 FPS, 키워드 15~20 FPS 가능
- RAM 사용: 약 350 KB (ESP32-S3 PSRAM 없는 경우 거의 전부 사용)

## 검증·재현성

- 소스 코드 없음(개념 기사). 재현 불가 — 수치는 저자 측정값
- ESP-IDF 버전 불기재

## 한계·위험

- 소스 코드·GitHub 링크 없음. 수치는 검증할 방법 없음(자가 보고)
- PSRAM 없이 350 KB RAM이면 FreeRTOS 오버헤드 포함 시 여유 없음
- 모델 훈련 절차, 데이터셋, 실제 WER(Word Error Rate) 미기재

## 재사용 메모

FPGA/Basys3로 직접 옮기기 어려움(`fit_basys3: no`). 그러나 개조 관점: MFCC 특징 추출 파이프라인(FFT 버터플라이, DCT)은 AXI4-Lite DSP IP로 구현 가능. int8 추론 가속기 구조(PE 어레이)는 T4 캡스톤 아이디어가 될 수 있음.
개조: CPU 코어(Xtensa)·ESP-DSP 라이브러리는 옮길 수 없음. MFCC 연산 흐름(FFT → Mel 필터 → log → DCT)은 FPGA 파이프라인으로 설계 가능하고, 가중치 테이블은 BRAM에 저장 가능.
