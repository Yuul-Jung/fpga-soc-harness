---
name: jpralves-car-hud-speed-compass
url: https://jpralves.net/post/2020/12/10/car-hud-windscreen-display-for-speed-compass.html
source_type: article
vendor: neutral
board: [Arduino Nano]
fit_basys3: needs-port
cpu: none(MCU 펌웨어)
language: C++ (Arduino 스케치)
tools: [Arduino IDE]
bus: UART
peripherals: [comm-uart, sensor, actuator-led-7seg]
stage: T1
license: unknown (페이지에 라이선스 표기 없음 → 코드 반입 금지)
stats: {last_update: 2020-12-10}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://jpralves.net/post/2020/12/10/car-hud-windscreen-display-for-speed-compass.html]
---
## 요약
Beitian BN-220 GPS가 1 Hz로 보내는 GPRMC 문장에서 속도와 방향을 뽑아, 7세그먼트 3자리에 속도(또는 1~360° 방향)를 보여 주는 차량 HUD 글이다. GPS 문장 → 체크섬 검증 → 숫자 표시라는 짧은 경로가 한 글에 모두 있다.

## 구조
- 제어기: Arduino Nano. GPS는 4핀 헤더의 직렬 TTL 연결이며, 업로드할 때 GPS의 Tx와 충돌하지 않도록 Rx 점퍼를 빼야 한다(글 서술).
- 입력: 밝기 ± 버튼 2개와 속도/방향 전환 버튼 1개.
- 표시: 적색 공통 캐소드 7세그먼트(5161AS형) 3개를 14511 BCD 디코더·래치 3개와 공유 4비트 버스로 구동. 앞자리 0은 소등, 방향 모드는 별도 LED로 표시.
- 소프트웨어: 시리얼 이벤트로 초당 1회 문장 수신 → 파서가 속도·방향 추출 → 체크섬 루틴으로 검증 → 래치 활성/버스 값 출력/래치 비활성 순서로 표시. 밝기는 PWM, 마지막 변경 약 1분 뒤 EEPROM에 저장.
- 전원·전압 수준: unverified: 글에 없음.

## 검증·재현성
- 테스트·측정 자료: unverified: 글에 없음. 소스 공개 여부와 라이선스도 unverified.

## 한계·위험
- 글이 밝힌 한계: 다른 GPS 모듈은 `$GNRMC`처럼 문장 ID가 다를 수 있어 파서 수정이 필요, 유효 데이터가 있을 때만 방향이 의미 있음, Arduino `String` 클래스를 많이 써서 작은 MCU에서는 메모리 부담, 7세그 배선이 거울상이라 소프트웨어로 보정.
- 라이선스 표기 없음 → 코드를 가져오지 않는다. 라이선스 확인 필요.

## 재사용 메모
- 내 판단: NMEA 문장 수신(`$`로 시작, `*` 뒤 체크섬, 줄 끝)은 문자열 객체 없이 고정 폭 버퍼와 상태기계로 처리하기 좋은 형식이라 RTL/펌웨어 어느 쪽으로도 옮기기 쉽다. 토론 글(Digilent 포럼)의 프레임 오류 사례와 함께 보면 문장 ID(`GP`/`GN`) 일반화가 첫 시험 항목이다.
- 개조: Basys3의 7세그(4자리, 공통 애노드 동적 구동)는 BCD 디코더·래치가 필요 없고 RTL 스캔 구동이면 된다. UART 수신기와 NMEA 필드 추출은 AXI4-Lite 레지스터 IP(수신 FIFO, 문장 완료 인터럽트)로, 속도 변환·표시 선택은 MicroBlaze V 펌웨어로 옮긴다. 옮길 수 없는 부분은 Arduino 시리얼 이벤트·EEPROM API(MCU 전용, 한 파일로 격리). 코드는 가져오지 않는다.
