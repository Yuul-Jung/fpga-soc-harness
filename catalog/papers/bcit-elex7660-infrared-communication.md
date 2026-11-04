---
name: bcit-elex7660-infrared-communication
url: https://circuit.bcit.ca/islandora/object/repository%3A783/datastream/PDF/view
source_type: report
vendor: intel
board: [Cyclone IV E 계열 (보드명 미기재)]
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: [Quartus 17.1]
bus: none
peripherals: [IR 송신(NEC), IR 수신(NEC), keypad, 7seg]
stage: T2
license: unknown
stats: {date: 2018-04-13}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://circuit.bcit.ca/islandora/object/repository%3A783/datastream/PDF/view]
unverified: 라이선스, 보드 정확한 이름, 소스 저장소 링크(보고서 PDF만 열람)
---

## 요약
BCIT ELEX 7660 수업의 팀 보고서. 키패드 숫자를 NEC 프레임으로 IR LED에 내보내고, 같은 장치의 포토다이오드 수신부가 해독해 7세그먼트에 표시한다. 송신·수신이 모두 FPGA FSM이다.

## 구조
- 시스템 클럭 50 MHz, 38 kHz 반송파는 PLL 클럭에서 생성(보고서 서술).
- 수신 FSM `nec_decode`: 에지 카운터로 단계를 추적. 1단계 9 ms 리더 확인 → 2단계 4.5 ms 공백 확인 → 이후 홀수 번째 에지마다 펄스 폭을 재서 비트 판정(경계 1000 µs). 32비트 버퍼에 주소·반전 주소·데이터·반전 데이터를 모아 반전 값과 비교해 오류를 검사하고, 단계마다 시간 창(timeout)을 둔다.
- 타이밍(보고서): 비트 0은 562.5 µs + 562.5 µs, 비트 1은 562.5 µs + 1.6875 ms, 전체 프레임 약 67.5 ms.

## 검증·재현성
- 타이머·디코더·송신기 테스트벤치 작성, 키패드 7 입력 → LED 송신 → 포토다이오드 수신 → 7세그먼트 표시, 오실로스코프 파형 측정.

## 한계·위험
- 송수신이 한 장치 안이라 외부 간섭·실제 리모컨 호환은 확인 못 함. 숫자 한 자리만 시연. 오류 검사 실패 시 처리가 불명확(보고서가 데이터 0 설정을 언급).
- 코드·주석·테스트벤치 이름 불일치를 보고서가 인정.

## 재사용 메모
- 내 판단: 에지 단위 FSM + 단계별 시간 창 구조는 NEC 해독의 사실상 표준 형태이고, 오류 시 프레임을 버리고 대기로 복귀하도록 바꾸면 실제 리모컨에도 견딘다.
- 개조: 디코더를 AXI4-Lite 읽기 레지스터(주소·명령·유효)와 인터럽트로 감싼다. 클럭 50 MHz → 100 MHz는 카운트 상수 두 배(내 계산). 수신 모듈(3.3 V 출력 IR 수신기) 선택 시 5 V 모듈은 레벨 변환 필요.
- 라이선스 확인 필요(unknown).
