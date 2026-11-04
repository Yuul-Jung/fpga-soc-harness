---
name: sl45sms-esp32c6-keyword-spotting
url: https://github.com/sl45sms/esp32c6-Keyword-Spotting
source_type: repo
vendor: neutral
board: [ESP32-C6-DevKitC-1-N8]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++
tools: [ESP-IDF 5.1, ESP-ADF, Edge Impulse C++ SDK]
bus: none
peripherals: [I2S-mic-MSM261S4030H0R, LED]
stage: T3
license: Apache-2.0
stats: {stars: 3, forks: 0, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://github.com/sl45sms/esp32c6-Keyword-Spotting]
---

## 요약 (3줄 이내, 내 표현으로)

ESP32-C6에 Edge Impulse 훈련 모델(TFLite 기반)을 올려 사용자 정의 키워드("vrasida")를 검출하면 LED를 켜는 키워드 스팟팅 데모. ESP-IDF 5.1 + ESP-ADF + I2S 마이크(MSM261S4030H0R, 핀: BCLK=GPIO22/WS=GPIO21/DOUT=GPIO15) 조합. Edge Impulse SDK를 직접 추출해 CMake에 통합하는 방식.

## 구조

- 최상위: ESP-IDF 5.1 CMake 프로젝트
- 오디오 입력: I2S MEMS 마이크(DFRobot SEN0526 또는 MSM261S4030H0R)
- ML 프레임워크: Edge Impulse C++ 라이브러리(TFLite 모델 포함), `tflite-model/` 폴더
- 추론 클래스: 단일 키워드 "vrasida" (인식 시 LED 점등)
- 의존: `CONFIG_FREERTOS_ENABLE_BACKWARD_COMPATIBILITY=y` 필수
- `ei_classifier_porting.h`에 ESP32-C6 지원 패치 필요

## 검증·재현성

- 저자 환경(ESP32-C6-DevKitC-1-N8)에서 동작 확인 보고됨.
- CI 없음. 커밋 7건.
- Edge Impulse SDK는 직접 다운로드 후 압축 해제해야 함.

## 한계·위험

- 단일 사용자 키워드 "vrasida"만 인식. 범용 wake word 아님.
- ESP-ADF의 `ei_classifier_porting.h`에 ESP32-C6 미지원 항목 수동 패치 필요.
- Edge Impulse SDK를 별도 획득해야 하며 자동 빌드 어려움.
- 커밋 날짜 미기재, 소규모 프로젝트(3 stars).
- `sdkconfig`에 FreeRTOS 하위 호환 설정 필수.

## 재사용 메모

- I2S 마이크 → ESP32 → Edge Impulse 추론 → 출력 트리거 전체 파이프라인이 명확하게 구현되어 있다. Edge Impulse SDK를 MCU에 통합하는 최소 패턴을 직접 참고할 수 있다.
- 핀 번호(BCLK=GPIO22/WS=GPIO21/DOUT=GPIO15)는 다른 ESP32 변형 보드에 적용 시 재확인 필요.
- 개조: ESP32-C6 측 추론 결과를 UART로 Basys3에 전달하는 패턴(ESP32=오디오 처리+ML, FPGA=명령 처리)이 직접 적용 경로. MicroBlaze V에서는 UART 수신 인터럽트 → 명령 디코딩 → AXI GPIO로 액추에이터 제어 흐름이 맞다. I2S 마이크 직접 연결을 Basys3 Pmod에 구현하는 것은 randomnerdtutorials-esp32-inmp441-i2s 카드(INMP441)와 조합해 참고 가능. `개조:` 오디오 캡처+ML을 ESP32가 담당, 판정 결과만 UART로 MicroBlaze V에 전달.
