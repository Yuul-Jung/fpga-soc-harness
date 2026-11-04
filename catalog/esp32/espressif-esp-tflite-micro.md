---
name: espressif-esp-tflite-micro
url: https://components.espressif.com/components/espressif/esp-tflite-micro/versions/1.3.3~1/readme?language=en
source_type: article
vendor: neutral
board: [ESP32-S3, ESP32, ESP32-C3, ESP32-P4]
fit_basys3: no
cpu: none(MCU 펌웨어)
language: C, C++
tools: [ESP-IDF v4.4+, idf.py, ESP-NN]
bus: none
peripherals: [마이크(I2S), 카메라(CSI)]
stage: T3
license: Apache-2.0
stats: {stars: 0, commits: 0, last_update: 2026}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://components.espressif.com/components/espressif/esp-tflite-micro/versions/1.3.3~1/readme?language=en]
---

## 요약

Espressif 공식 TensorFlow Lite Micro 컴포넌트(v1.3.3~1, 최신 안정판 v1.4.2). 모든 ESP32 타겟 지원, ESP-NN 최적화 커널로 추론 속도를 크게 올린다. 세 가지 예제(hello_world, micro_speech, person_detection)를 `idf.py create-project-from-example`로 생성 가능. 아카이브 크기 약 1.63 MB.

## 구조

- 설치: `idf.py add-dependency "esp-tflite-micro"`, ESP-IDF release/v4.4 이상
- 빌드: ESP-NN 활성화는 CMakeLists.txt에 `-DESP_NN` 플래그 추가
- 예제:
  - `hello_world`: 기본 추론 흐름
  - `micro_speech`: 키워드 감지(wake word)
  - `person_detection`: 사람 감지
- Person Detection 추론 시간(ESP-NN 활성 기준):
  - ESP32-P4: 73 ms
  - ESP32-S3: unverified(페이지에서 확인 못 함)
  - ESP32-NN 없을 때: 1395 ms (약 19배 차이)
- 내부 메모리 우선: ESP-NN은 내부 SRAM에서 최적화. PSRAM 사용 시 성능 저하

## 검증·재현성

- Espressif 공식 컴포넌트 레지스트리. 버전별 소스 열람 가능
- 내 판단: ESP32-P4(73 ms)와 ESP32-S3 추론 차이가 얼마인지는 페이지에서 직접 확인 못 했음(unverified)

## 한계·위험

- RAM/Flash 사용량 수치 없음. PSRAM 없는 ESP32에서 모델 크기 제약 큼
- micro_speech·person_detection은 예제 이름만 나오고 세부 모델 구조 미기재

## 재사용 메모

Basys3로 직접 옮기기 어려움(`fit_basys3: no`). 개조 관점: Espressif 컴포넌트 구조(모델 플래시 저장, int8 추론, 메모리 관리자)는 FPGA 추론기 설계 시 참고. ESP-NN의 최적화 방식(내부 메모리 우선, 가중치 DMA)은 BRAM 가중치 로딩 패턴으로 차용 가능.
개조: ESP-IDF·ESP-NN은 옮길 수 없음. 모델 양자화 흐름(float → int8)과 테스트벤치 구조(hello_world 패턴)는 FPGA 가속기 IP 시험 환경에 응용 가능.
