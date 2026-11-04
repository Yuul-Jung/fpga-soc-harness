---
name: alibukharai-esp-dl-gesture
url: https://developer.espressif.com/blog/hand-gesture-recognition-on-esp32-s3-with-esp-deep-learning/
source_type: article
vendor: neutral
board: [ESP32-S3]
fit_basys3: no
cpu: none(MCU 펌웨어)
language: C, Python
tools: [ESP-IDF v4.4, ESP-DL, TensorFlow/Keras, tf2onnx]
bus: none
peripherals: [카메라(OV2640 테스트 이미지)]
stage: T3
license: MIT
stats: {stars: 0, commits: 0, last_update: 2022-12}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://developer.espressif.com/blog/hand-gesture-recognition-on-esp32-s3-with-esp-deep-learning/, https://github.com/alibukharai/Blogs/tree/main/ESP-DL]
---

## 요약

ESP32-S3에서 ESP-DL(Espressif 딥러닝 프레임워크)으로 6종 손 제스처 분류기를 구현한 Espressif 공식 블로그 기사. 96×96 그레이스케일 입력 → 3단계 Conv2D/MaxPooling → Dense(128) → Softmax(6) 모델을 Google Colab에서 훈련하고 int16 양자화 후 배포한다. 추론 약 0.7초/장.

## 구조

- 모델: 6클래스(손 제스처), Keras 훈련 → tf2onnx → ESP-DL int16 per-tensor 양자화
- 입력: 96×96 그레이스케일, 테스트는 하드코딩된 정적 이미지(실시간 카메라 아님)
- 추론 속도: 약 0.7초/장 (약 1.4 FPS)
- 사용 도구: Google Colab(훈련), ESP-IDF release/v4.4, VS Code(펌웨어)
- 소스: https://github.com/alibukharai/Blogs/tree/main/ESP-DL, 프레임워크: https://github.com/espressif/esp-dl

## 검증·재현성

- Colab 훈련 정확도 약 99%(float 모델, 5 에포크). 양자화 후 정확도 미기재
- 실시간 카메라 피드 없음(정적 이미지 하드코딩). 미래 작업으로 남김
- 코드에 오타("pythonn"), 미완성 print 문, int8 주석-int16 불일치 존재
- 특정 ESP-IDF 버전/커밋에 종속 (재현성 주의)

## 한계·위험

- Kaggle 10클래스 데이터셋에서 6클래스만 사용, 이미지를 240×640→96×96으로 축소
- 실시간 추론 미구현, 0.7초 지연은 실용 불가 수준
- RAM/Flash 사용량 미기재

## 재사용 메모

Basys3로 직접 옮기기 어려움(`fit_basys3: no`). 개조 관점: 훈련-배포 파이프라인(Keras→ONNX→하드웨어) 구조는 FPGA 추론기 설계 흐름의 참고가 됨. 96×96 입력 크기는 Basys3 OV7670 프레임 크기(QVGA 320×240)에서 중앙 잘라내기로 얻을 수 있음.
개조: ESP-DL 프레임워크는 옮길 수 없음. Conv2D 커널 가중치와 양자화 테이블은 BRAM에 올릴 수 있음. T4 IP 아이디어(§17.2): int16 convolution IP를 AXI4-Lite 슬레이브로 구현해 MicroBlaze V에서 가중치 로드 후 추론.
