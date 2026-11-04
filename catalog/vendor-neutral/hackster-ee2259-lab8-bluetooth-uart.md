---
name: hackster-ee2259-lab8-bluetooth-uart
url: https://www.hackster.io/457040/lab-8-bluetooth-uart-module-ee2259
source_type: course
vendor: neutral
board: ["unverified: 보드명 미기재(16 MHz 클럭 FPGA 보드)"]
fit_basys3: needs-port
cpu: none(FSM)
language: "unverified: 페이지에 HDL 언어 미기재"
tools: ["unverified"]
bus: none
peripherals: [comm-bt, comm-uart, actuator-led]
stage: T1
license: unknown (페이지에 미기재, 소스는 GitHub라고만 언급)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.hackster.io/457040/lab-8-bluetooth-uart-module-ee2259]
---

## 요약
수강 실습 8번. FPGA에 수신 전용 UART를 만들어 HC-06류 블루투스 모듈의 바이트를 받고, 마지막 4비트를 LED 4개에 보인다. 다음 실습(블루투스 원격 자동차)의 준비 단계.

## 구조
- 9600 baud, 8N1. 16 MHz 클럭에서 한 비트 약 1667 사이클(페이지 기재). 비트 중앙에서 표본.
- 수신 완료 신호나 출력 레지스터로 무효 데이터 읽기를 막음.
- 연결: 모듈 TX → FPGA RX 핀, VCC/GND. 시험은 안드로이드 앱, PC 파이썬, LightBlue(BLE)로 안내.
- 모듈은 HM-10 또는 HC-06 계열이라고 쓰고 HC-05는 언급하지 않음.

## 검증·재현성
- 테스트벤치·자원 사용: unverified: 페이지에 없음. 소스 저장소는 열람하지 않음.

## 한계·위험
- 수신 전용이며 송신·AT 설정은 다루지 않음. 라이선스 unknown → 코드 가져오기 전 "라이선스 확인 필요".
- 모듈의 전압 레벨 언급 없음(unverified).

## 재사용 메모
- 내 판단: 100 MHz Basys3에서는 분주비가 10417(내 계산: 100e6/9600)로 바뀐다. 입문(T1) 단계 UART 수신 실습의 난이도 사다리 첫 칸으로 쓸 수 있다.
- 개조: CPU 비종속. 수신 FSM은 동결 맵 uart 영역의 레지스터(수신 데이터, 수신 완료 상태)와 같은 구조라 그대로 대응된다.
