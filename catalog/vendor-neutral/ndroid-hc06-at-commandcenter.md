---
name: ndroid-hc06-at-commandcenter
url: https://github.com/ndroid/HC06_AT_CommandCenter
source_type: repo
vendor: neutral
board: ["해당 없음(Arduino: Mega, MKR, Uno WiFi, Zero, Due, MSP432)"]
fit_basys3: needs-port
cpu: none(MCU 라이브러리, FPGA 아님)
language: "unverified: 언어 비율 미확인(Arduino 라이브러리)"
tools: [Arduino]
bus: UART
peripherals: [comm-bt, comm-uart]
stage: T2
license: MIT (1.0.0부터), 0.4.0 이하는 GPLv3
stats: {stars: 3, commits: 47, last_update: "unverified: 날짜 미확인(개정 2.0.1은 2023-10)"}
doc_language: en
verification: L3
checked_at: 2026-11-03
source_rev: "unverified: 열람 화면에 커밋 SHA가 보이지 않음"
sources: [https://github.com/ndroid/HC06_AT_CommandCenter]
---

## 요약
HC-05/HC-06을 UART로 연결해 AT 명령으로 설정하는 Arduino 라이브러리. 메뉴로 설정을 고르고, 모듈 종류·펌웨어 버전·보율을 자동 감지한다. FPGA 코드는 아니지만 AT 설정 절차의 근거 자료다.

## 구조
- 모듈은 AT 모드(LED 빠른 점멸)여야 하고, 모듈 TXD→보드 Serial1 RX, 모듈 RXD←보드 TX는 1K 저항과 2K 분압으로 연결한다. 3.3V 보드는 분압이 필요 없다고 README가 적음.
- 응답 종료 방식: 펌웨어 3.x는 줄바꿈 종료(약 10~25 ms, 최대 35 ms 관측), 1.x는 시간 초과 종료(약 500 ms, 최대 525 ms 관측).
- 최근 HC-06 일부는 버전 3 펌웨어를 보고하고 HC-05식 명령과 CR+NL 종단을 쓴다. 이 펌웨어의 공식 문서는 없다고 README가 적음.
- HC-05는 STATE 핀과 EN/KEY 핀 배선이 필요. HC-05가 AT 모드에 고정되는 문제를 README가 다룸(세부 unverified).

## 검증·재현성
- 테스트벤치·CI: unverified: 열람 범위에서 확인 못 함. 예제는 `examples/` 폴더.

## 한계·위험
- Arduino 전용이므로 FPGA 재현성은 구조 참고 수준. 명령 목록 전체와 `src/` 코드는 열람하지 않았다(unverified).
- 응답 지연이 모듈마다 다르므로 FPGA FSM이 같은 설정을 하려면 시간 초과 대기를 파라미터로 둬야 한다(내 판단).

## 재사용 메모
- 내 판단: 우리 SoC에서는 설정(AT)을 FPGA가 하지 않고 PC/Arduino로 1회 설정한 뒤 데이터 모드만 UART IP(동결 맵 uart 영역)로 쓰는 편이 단순하다.
- 개조: CPU 비종속 자료. AT 설정은 소프트웨어(UART 레지스터 폴링) 절차로 옮길 수 있고, 보드는 3.3V 기준이라 분압 부분은 필요 없다. MCU 전용 Serial1 호출은 옮길 수 없다.
