---
name: nopnop2002-esp-idf-websocket-camera
url: https://github.com/nopnop2002/esp-idf-websocket-camera
source_type: repo
vendor: neutral
board: [AI-Thinker ESP32-CAM, Freenove ESP32-WROVER-CAM, UICPAL ESPS3 CAM, Freenove ESP32S3-WROVER-CAM]
fit_basys3: needs-port
cpu: none(MCU 펌웨어, ESP32/ESP32-S3 Xtensa LX6/LX7)
language: C (ESP-IDF)
tools: [ESP-IDF v5.0+]
bus: HTTP WebSocket (TCP/IP)
peripherals: [camera, comm-eth]
stage: T2
license: MIT
stats: {stars: 6, forks: 2, commits: 32, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://github.com/nopnop2002/esp-idf-websocket-camera]
---

## 요약
ESP32 카메라(OV2640)를 WebSocket 서버로 노출해 브라우저 한 장면 요청에 JPEG 사진 한 장을 반환하는 ESP-IDF v5.0+ 예제. AI-Thinker ESP32-CAM 및 ESP32-S3 WROVER CAM 보드 대응.

## 구조
- **기능**: ESP32가 WebSocket 서버 → 브라우저가 HTTP 접속 → 버튼 클릭으로 사진 한 장 요청 → JPEG 반환. 연속 스트리밍 없음(단일 캡처).
- **지원 보드**: AI-Thinker ESP32-CAM, Freenove ESP32-WROVER-CAM, UICPAL ESPS3 CAM, Freenove ESP32S3-WROVER-CAM (Clone)
- **빌드 순서**: `idf.py set-target {esp32|esp32s3}` → `idf.py menuconfig` (PSRAM 타입 선택) → `idf.py flash monitor`
- **플래싱 주의(AI-Thinker)**: USB-TTL 변환기 필요, 플래시 시 GPIO0 → GND, 실행 시 GPIO0 오픈 후 RESET
- **ESP-IDF v4.4 지원 종료**: 2024년 7월 기준 EOL; v5.0 이상 필수

## 검증·재현성
- MIT 라이선스 명시; 32 커밋
- README에 브라우저 접속 URL 오탈자(`http:://{IP}/`, 콜론 두 개) 존재 — 실제 접속은 `http://{IP}/`

## 한계·위험
- **연속 스트리밍 미지원**: 단일 캡처(snapshot) 방식만 구현. MJPEG 스트림이 필요하면 별도 구현 필요
- **저활성 저장소**: stars 6, forks 2로 커뮤니티 검증 최소
- README 오탈자로 초보자 혼란 가능

## 재사용 메모
- WebSocket으로 단일 JPEG 전송 패턴은 Basys3 UART/SPI 단일 프레임 전송 아키텍처와 구조적으로 같다.
- 개조: MicroBlaze V SoC로 옮기는 경우 — FPGA가 직접 OV2640을 구동하려면 AXI-IIC(SCCB) + AXI-Stream 캡처 IP 필요(§espressif-esp32-camera 개조 참고). 이 저장소의 WebSocket 서버 로직은 ESP32 전용이지만, "요청→단일 프레임 반환" 흐름은 UART 기반 명령-응답 프로토콜로 대체 가능. AI-Thinker GPIO4 플래시 LED 핀 배치는 FPGA 보드와 무관.
