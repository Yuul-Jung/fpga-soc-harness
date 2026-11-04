---
name: espressif-faq-mqtt
url: https://docs.espressif.com/projects/espressif-esp-faq/zh_CN/latest/software-framework/protocols/mqtt.html
source_type: article
vendor: neutral
board: [ESP32 계열 (보드 특정 안 함)]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32)
language: C (ESP-IDF esp-mqtt)
tools: [ESP-IDF esp-mqtt]
bus: none
peripherals: [comm-eth]
stage: T2
license: unknown (페이지에 라이선스 표기 없음, 코드 반입 대상 아님)
stats: {last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://docs.espressif.com/projects/espressif-esp-faq/zh_CN/latest/software-framework/protocols/mqtt.html]
---
unverified: source_rev — 공식 FAQ 문서라 해당 없음. URL 경로가 zh_CN이나 열람 요약은 영어로 나왔다(원문 언어는 unverified, doc_language는 허용값 en으로 기록).

## 요약
Espressif의 ESP-IDF MQTT 클라이언트 FAQ다. 연결 유지(keepalive), 자동 재연결, 연결 끊김 사건의 원인, QoS 1/2의 메모리 해제 시점을 문답으로 정리한다. 실제 서비스에서 "왜 끊기나"를 추적하는 데 쓸 수 있는 목록이다.

## 구조
- keepalive 기본 120 s(`mqtt_config.h`의 `MQTT_KEEPALIVE_TICK`), 설정으로 `session.keepalive` 덮어쓰기. PING 기본 켜짐(`session.disable_keepalive`=false)이며 끊김 감지 수단이다. Wi-Fi·BLE 공존 환경에는 30 s 또는 60 s를 제안하지만, 너무 길면 오프라인 감지가 늦다고 경고.
- 자동 재연결 기본 켜짐(`network.disable_auto_reconnect`=false), 대기 시간은 `network.reconnect_timeout_ms`(예시 로그 10000 ms). Wi-Fi가 끊겨도 핸들을 지우고 다시 만들 필요 없음.
- `MQTT_EVENT_DISCONNECTED` 원인 7가지: 연결 중 TCP 오류, 연결 중 MQTT 오류, 직접 `disconnect` 호출, 송수신 오류, 기대 시간 내 PING 응답 없음, PING 전송 실패, 재연결.
- QoS: `MQTT_EVENT_PUBLISHED`는 QoS 1/2에서 브로커 ACK 후 발생. QoS 1/2의 outbox 메모리는 MQTT 계층 ACK 뒤에야 해제된다. `session.disable_clean_session`=true면 재연결 후 오프라인 중 발행된 QoS 1/2를 받을 수 있다.
- 유언(Last Will): FAQ는 설정 필드 이름을 주지 않는다. 브로커가 유언을 더 빨리 내보내게 하려면 keepalive를 줄이고, 끊을 때는 disconnect를 명시 호출하라고 권고.

## 검증·재현성
- 문서이므로 실행 근거 없음. unverified: 버퍼 크기 설정 이름·값(FAQ에 없음), TLS 설정(해당 페이지에 내용 없음).

## 한계·위험
- 메모리 부족 원인을 outbox와 LWIP 버퍼가 차는 것으로만 서술하고 수치가 없다.
- 라이선스 확인 필요: 페이지에 표기 없음 → 문구를 옮기지 않고 설정 이름·기본값(사실)만 기록.

## 재사용 메모
- 내 판단: 센서 허브 텔레메트리에서 "끊김을 얼마나 빨리 아는가 ↔ 트래픽·전력"의 절충이 keepalive 하나로 결정된다. Basys3 쪽 UART 브리지에서는 하트비트 프레임 주기와 타임아웃 레지스터가 같은 역할을 한다.
- 개조: 옮길 부분은 "하트비트 주기 + 미응답 타임아웃 → 연결 끊김 상태 비트 + 재연결 대기 카운터"를 UART 브리지 IP 레지스터(`HB_PERIOD`, `HB_TIMEOUT`, `STATUS.link_lost`)로 두는 설계와 시험 항목(응답 없음 N회 → 끊김 비트 세팅). 못 옮길 부분은 MQTT, QoS, TCP/LWIP. 아직 어떤 아이디어의 근거로 쓰이지 않음.
- 관련: [[modestos-esp32-dht-mqtt-deepsleep]], [[espressif-ota-updates-framework]].
