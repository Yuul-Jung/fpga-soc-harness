---
name: controllerstech-esp32-freertos-multitasking
url: https://controllerstech.com/esp32-freertos-multitasking-project/
source_type: article
vendor: neutral
board: [ESP32 DevKitC급 (정확한 모듈명 unverified)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa)
language: C (ESP-IDF 추정, 글이 프레임워크명을 직접 쓰는지 unverified)
tools: [unverified: 글에서 IDF 버전 확인 못 함]
bus: none
peripherals: [sensor, comm-uart]
stage: T1
license: unknown (글에 라이선스 표기 없음, 코드 반입 대상 아님)
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://controllerstech.com/esp32-freertos-multitasking-project/]
---
unverified: source_rev — 블로그 글이라 해당 없음

## 요약
ESP32에서 FreeRTOS 태스크 3개(ADC 읽기, 통신 출력, LED 펄스)를 큐와 태스크 알림으로 엮는 입문 글이다. 센서 값 하나가 "타이머 → 읽기 → 큐 → 출력 → 알림"으로 흐르는 최소 센서 허브 골격이다.

## 구조
- 센서: 0~3.3V 아날로그 출력, GPIO 34(ADC1_CH6), 12비트 원시값, 12 dB 감쇠. 보정·필터 없음(글 서술).
- 태스크: ADC_Task(스택 2048 B, 우선순위 5), Comm_Task(4096 B, 우선순위 4 또는 6), LED_Task(1024 또는 2048 B, 우선순위 3). 글의 표와 전체 코드가 LED 스택과 Comm 우선순위에서 서로 다르다.
- 큐 `xQueueCreate(10, sizeof(int))`(10칸×4바이트). ADC 태스크는 10 ms 제한시간으로 보내고 가득 차면 경고만 남긴다.
- 소프트웨어 타이머가 `xTaskNotifyGive`로 ADC 태스크를 깨운다. 전체 코드는 1000 ms 자동 반복, 본문 예시는 100 ms로 어긋난다(코드가 기준이라고 글에 암시, 내 판단).
- 코어 고정 없음(`xTaskCreate` 사용). 통신은 UART 콘솔 `printf`만 구현, Wi-Fi(MQTT·HTTP)·BLE·ESP-NOW는 언급 또는 주석 예시뿐.

## 검증·재현성
- 테스트·CI 없음. 내려받기 버튼만 있고 열람한 것은 글 본문. unverified: 내려받은 프로젝트 파일 내용.

## 한계·위험
- 큐 가득 참 시 표본을 버린다. 필터는 FAQ에서 이동 평균 제안만 있다(글 서술).
- ADC2 핀은 Wi-Fi와 충돌하므로 ADC1을 쓰라는 주의가 있다(글 서술).
- 라이선스 미표기 → 코드 반입 금지. 스택 크기·우선순위가 글 안에서 불일치하므로 수치를 그대로 믿지 않는다.

## 재사용 메모
- 내 판단: "타이머 주기 → 표본 → FIFO → 소비자" 구조는 센서 허브 IP(I-036)의 표본 FIFO·타임스탬프 구조와 같은 모양이라 시험 시나리오(큐 가득 참, 표본 손실 카운트)를 테스트벤치 항목으로 가져올 수 있다.
- 개조: 옮길 부분은 "표본 주기 레지스터 + 깊이 10 FIFO + 오버런 카운터"를 AXI4-Lite 레지스터(`PERIOD`, `FIFO_DATA`, `STATUS.overrun`)로 노출하는 설계다. 못 옮길 부분은 FreeRTOS 태스크·알림 API 자체와 ESP32 ADC. ESP32 쪽은 Basys3와 UART로 잇는 호스트(`devices/` 허브 후보)로만 쓴다.
- 같은 사이클 ESP32 카드: [[hideakitai-esp32spislave]].
