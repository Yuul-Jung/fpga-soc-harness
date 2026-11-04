---
name: jakkra-gesture-detecting-macro-keyboard
url: https://github.com/jakkra/gesture-detecting-macro-keyboard
source_type: repo
vendor: neutral
board: [ESP32 (보드 미지정)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C, Python, AutoHotkey
tools: [ESP-IDF 4.2, TensorFlow Lite Micro]
bus: none
peripherals: [capacitive-touch-pad, BLE-HID, OLED, button]
stage: T4
license: MIT
stats: {stars: 96, forks: 9, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-04
source_rev:
sources: [https://github.com/jakkra/gesture-detecting-macro-keyboard, https://hackaday.com/2021/06/13/gesture-detecting-macro-keyboard-knows-what-you-want]
---

## 요약 (3줄 이내, 내 표현으로)

ESP32와 Bela Trill 정전식 터치패드, TFLite Micro를 결합해 7가지 손 제스처를 BLE HID 단축키로 변환하는 매크로 키보드. 터치패드 좌표를 28×28 픽셀 행렬로 변환 후 TFLite Micro가 추론한다. OLED 디스플레이, 볼륨 슬라이더, 11개 물리 버튼과 AutoHotkey PC 스크립트를 함께 사용한다.

## 구조

- 최상위: ESP32 펌웨어(C/ESP-IDF), Python 훈련 스크립트, AutoHotkey PC 스크립트
- 입력: Bela Trill 정전식 패드 2개(square: 제스처, bar: 볼륨). 패드 좌표 범위 [0, 1792] → 28×28 행렬 정규화
- 모델: TFLite Micro 추론. 클래스 7종(ARROW_RIGHT/UP/DOWN, C_GESTURE, LINE_DOWN/HORIZONTAL/S_GESTURE)
- 출력: ESP32 BLE HID 키보드로 PC에 단축키 전송
- OLED: 현재 상태 및 제스처 디버그 표시
- 훈련: 제스처당 약 150건 훈련+45건 테스트 필요, 훈련 후 재플래시

## 검증·재현성

- ESP-IDF 4.2 기준으로 작성. `idf.py build flash` 절차.
- 별도 훈련 스크립트 포함(Python). 새 제스처 추가 가능.
- Hackaday 기사에서 동작 확인 보고 있음(독립 검증).
- CI 없음.

## 한계·위험

- Bela Trill 터치패드가 필요하며 Basys3 Pmod로 직접 대체 불가. SPI/I2C 인터페이스이나 드라이버는 Bela 전용.
- ESP-IDF 4.2 기준; 최신 5.x와 호환성 확인 필요.
- `--center_gesture` 옵션 사용 시 좌우 대칭 제스처 혼동 가능성.
- AutoHotkey는 Windows 전용.
- 커밋 날짜 미기재.

## 재사용 메모

- TFLite Micro가 MCU에서 2D 제스처(28×28 행렬 입력)를 추론하는 완전한 흐름을 보여준다. 모델 훈련 → tflite 변환 → 플래시 적재 → 실시간 추론 파이프라인을 직접 참고 가능.
- BLE HID 키보드 출력 패턴은 ESP32-BLE 카드(rcaelers-esp32-beacon-scanner)와 연결해 볼 수 있다.
- 개조: ESP32 측은 MCU 전용이며 Basys3 직접 포팅은 불가. 그러나 ① 제스처 판정 후 UART로 명령 번호를 Basys3 SoC에 전송하는 구조(ESP32 보조 프로세서 + FPGA 본 처리), ② 28×28 입력 행렬 생성 + TFLite 추론 로직을 AXI4-Stream 인터페이스로 구현하는 FPGA가속기 설계의 참조로 사용 가능. MicroBlaze V에서는 UART/SPI 수신 → 명령 디코더 FSM 쪽이 현실적. `개조:` 제스처 판정 후 UART 명령 전송(ESP32) + MicroBlaze V UART 수신 FSM(Basys3) 조합이 직접적인 적용 경로.
---
내 판단: fit_basys3=needs-port. Basys3에서 TFLite Micro를 돌리는 것은 아니지만, ESP32 보조 보드 + UART 명령 전달 패턴으로 협력 구조를 만들 수 있다. stage=T4(사용자 정의 ML 추론 + BLE HID 파이프라인).
