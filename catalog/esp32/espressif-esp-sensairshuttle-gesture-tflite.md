---
name: espressif-esp-sensairshuttle-gesture-tflite
url: https://developer.espressif.com/blog/2026/04/gesture-recognition-based-on-tflite/
source_type: article
vendor: neutral
board: [ESP-SensAirShuttle (ESP32-C5 기반)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C, Python
tools: [ESP-IDF 5.5+, ESP-TFLite-Micro 1.3.4~1.3.5, TensorFlow 2.20.0 Keras]
bus: none
peripherals: [BMI270-IMU-gyroscope, button]
stage: T4
license: CC0-1.0 (예제 소스 파일 기준)
stats: {stars: unknown, forks: unknown, last_update: 2026-04}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
status: 재검증 차단 (WebFetch PROVENANCE_REQUIRED, 2026-11-04 /verify)
sources: [https://developer.espressif.com/blog/2026/04/gesture-recognition-based-on-tflite/]
---

## 요약 (3줄 이내, 내 표현으로)

Espressif 공식 개발자 블로그(2026-04)에 게재된 ESP32-C5 + BMI270 IMU(자이로스코프 전용)를 이용한 TFLite Micro 제스처 인식 가이드. 1D CNN(Conv1D×2 + GAP + Dense)으로 반시계원·V자·미등록 3클래스를 약 97% 정확도로 분류. 훈련(Python/Keras)부터 C 펌웨어 배포까지 전 과정을 다룬다.

## 구조

- 하드웨어: ESP-SensAirShuttle 개발 키트(Espressif+Bosch Sensortec 공동 개발), ESP32-C5, BMI270 IMU
- 입력: BMI270 자이로스코프 3축 각속도만 사용. 200 타임스텝 × 3축 = 600값 → (200,3) 텐서
- 모델: 1D CNN. Conv1D(8필터, k=5) → ReLU → MaxPool → Conv1D(16필터, k=5) → ReLU → MaxPool → GAP → Dense(32) → Dropout(0.2) → Softmax(3)
- 훈련: TF 2.20.0 Keras, 300 에폭, 배치 64, Adam(lr=0.001), 70/30 분할. float32 유지(양자화 미적용)
- 펌웨어: ESP-TFLite-Micro 컴포넌트, tensor arena 50,000바이트, 8개 연산자 등록
- 추론 트리거: 절대 각속도 합이 임계값 초과 시 200 타임스텝 창 캡처 후 추론
- GitHub: `espressif/esp-dev-kits`, `examples/esp-sensairshuttle/gesture_recognition`

## 검증·재현성

- Espressif 공식 블로그 기사. 약 97% 테스트 정확도 보고(내부 실험).
- 훈련 데이터셋은 `dl.espressif.com`에 호스팅.
- 빌드: `idf.py build flash monitor` 절차 명시.
- 추론 지연시간·메모리 사용량·전력 수치는 기재 없음.

## 한계·위험

- ESP-SensAirShuttle 개발 키트 전용. 일반 ESP32 보드로 적용 시 BMI270 I2C 배선과 드라이버 조정 필요.
- float32 모델 사용; 양자화(int8) 미적용으로 메모리/속도 최적화 가능성 남음.
- 단일 연구자 데이터로 훈련; 다인 일반화 성능 미검증.
- arena 크기(50,000바이트) 모델 변경 시 직접 튜닝 필요.
- ESP-IDF 5.5+ 필수; 구버전 환경과 호환성 미확인.

## 재사용 메모

- 1D CNN으로 IMU(자이로) 시계열 데이터를 처리하는 패턴을 명확히 보여줌. 같은 구조를 STM32나 아두이노+MPU-6050 조합에도 적용 가능.
- 훈련 파이프라인(데이터 수집 → Keras 1D CNN → tflite 변환 → C 배열 → 펌웨어 배포) 전 단계가 공개됨.
- 개조: BMI270 자이로 대신 MPU-6050 또는 ADXL345를 Pmod로 Basys3에 연결하면 같은 1D CNN 구조를 AXI4-Lite 가속기 IP로 구현하는 참조 설계로 삼을 수 있다. 단, Basys3에서 TFLite Micro를 직접 실행하는 것은 XC7A35T 자원 초과 가능성이 높으므로, ESP32 보조 보드가 추론을 담당하고 FPGA는 모터·LED 등 액추에이터 제어를 맡는 분산 구조가 현실적. `개조:` 1D CNN 추론을 ESP32가, 판정 결과를 UART로 MicroBlaze V가 수신해 AXI GPIO/PWM으로 출력하는 역할 분담.
