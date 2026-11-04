---
name: modestos-esp32-dht-mqtt-deepsleep
url: https://xylem.aegean.gr/~modestos/mo.blog/esp32-send-dht-to-mqtt-and-deepsleep/
source_type: article
vendor: neutral
board: [Lolin32 ESP32]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32 Xtensa)
language: C++ (Arduino 코어)
tools: [Arduino core for ESP32, PubSubClient, Adafruit DHT library]
bus: none
peripherals: [sensor, comm-uart]
stage: T1
license: unknown (글에 라이선스 표기 없음, 코드 반입 대상 아님)
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://xylem.aegean.gr/~modestos/mo.blog/esp32-send-dht-to-mqtt-and-deepsleep/]
---
unverified: source_rev — 블로그 글이라 해당 없음

## 요약
ESP32가 15분마다 깨어나 DHT 온습도를 MQTT로 한 번 보내고 곧바로 딥슬립에 드는 최소 센서 노드 글이다. 깨어남→Wi-Fi→브로커→읽기→발행→수면이라는 "한 번 쓰고 잔다" 흐름이 전부다. 전력 수치는 글에 없다.

## 구조
- 보드: Lolin32, 센서: DHT11(GPIO 14), DHT22도 코드에서 지원한다고 서술. 브로커는 Raspberry Pi 3 위 Mosquitto(openHAB 병행).
- 라이브러리: Adafruit DHT, PubSubClient, ESP32 Arduino 코어.
- 흐름: Wi-Fi 연결 → MQTT 연결 → 온습도 읽기 → 값이 비정상이면 디버그 토픽에 오류 발행 후 수면 → 정상이면 온도·습도를 retained 메시지로 발행(둘 사이 100 ms 지연) → 타이머 깨우기 설정 후 딥슬립. `loop()`는 비어 있다.
- 주기: 900 s(15분). 오류 시 3600 s 상수가 정의돼 있으나 오류 분기가 실제로는 900 s 상수를 쓴다(글이 이 불일치를 다루지 않음).

## 검증·재현성
- 테스트·CI 없음. 전력 측정값 없음(unverified: 수면 전류, 깨어 있는 시간).

## 한계·위험
- 댓글 서술: Wi-Fi 연결 루프에 시간 제한이 없어 연결 실패 시 멈추며, 한 독자는 재시도 횟수를 넣고 실패 시 수면 후 다음 주기에 재시도하도록 고쳤다. 해결책 없이 "점만 계속 찍힌다"는 보고도 있다.
- 댓글 제안(글 본문은 시험 안 함): 센서 전원을 GPIO로 제어해 수면 중 전류를 줄인다.
- 라이선스 확인 필요: 코드·글 모두 라이선스 미표기 → 코드는 가져오지 않는다.

## 재사용 메모
- 내 판단: 이 글의 가치는 코드가 아니라 "깨어남-발행-수면" 한 사이클 계약이다. Basys3 쪽에는 대응하는 수면이 없지만, 센서 허브 IP가 주기 표본을 FIFO에 쌓고 ESP32가 깨어나는 순간 UART로 한 번에 비우는 분업으로 옮기면 의미가 있다(제약 역전 S4: 전력이 아니라 "연결 시간이 짧다"는 제약을 장점으로).
- 개조: 옮길 부분은 "표본 + 상태(정상/오류) + retained 최신값"을 AXI4-Lite 레지스터(`VALUE`, `STATUS.valid`, `STATUS.err`)와 UART 프레임으로 노출하는 구조다. 못 옮길 부분은 딥슬립, Wi-Fi, PubSubClient. 연결 실패 시 포기하고 다음 주기로 넘기는 정책은 호스트 쪽 규칙으로만 둔다.
- 관련: [[controllerstech-esp32-freertos-multitasking]], [[espressif-faq-mqtt]].
