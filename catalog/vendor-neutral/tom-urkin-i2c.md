---
name: tom-urkin-i2c
url: https://github.com/tom-urkin/I2C
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: SystemVerilog
tools: []
bus: none
peripherals: [comm-i2c]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/tom-urkin/I2C, https://github.com/tom-urkin/I2C/blob/main/README.md]
unverified: source_rev(커밋 SHA 미확인), 라이선스, 멀티마스터·중재 지원 명시 여부, 클럭 스트레칭, 포트 목록, 테스트벤치, 자원 사용
---

## 요약 (검색 요약 기준)
Tom Urkin의 SystemVerilog I2C 통신 프로토콜 구현. 검색 결과에서 "SystemVerilog I2C communication protocol"이라는 제목으로 반복 등장했으며, 교육 목적의 명확한 FSM 구조가 특징으로 추정된다(내 판단, unverified).

## 구조
- 열람하지 않아 모듈 구성, 포트, 클럭 주파수, 멀티마스터 여부 모두 `unverified`.
- 검색 결과 제목("SystemVerilog I2C communication protocol")으로부터 단일 파일 또는 소규모 구현일 가능성 있음(내 판단).

## 검증·재현성
- 검색 요약 기준(L2). 라이선스 미확인.
- 열람 필요: README를 직접 읽어 멀티마스터 중재, 클럭 스트레칭, 7비트/10비트 주소 지원 여부 확인.

## 한계·위험
- SystemVerilog: Vivado OK, iverilog는 --sv 플래그 필요.
- 라이선스 `unknown`: 사용 전 확인 필수.
- 모든 기능 항목 열람 미완료.

## 재사용 메모
- 멀티마스터·중재 여부 확인 후 쓸 가치 판단 가능. 교육 목적 구현이라면 중재 로직이 명확하게 분리돼 있을 가능성이 있고, 이를 AXI4-Lite 래퍼 작성 참고 자료로 활용할 수 있음(내 판단).
- 개조: MicroBlaze V `free_slots` I2C IP 설계 시 — 이 코어의 FSM(SDA/SCL 비트뱅)을 AXI 레지스터 인터페이스로 감싸고, 멀티마스터 감지 비트를 IP 표준 필드에 맞춰 추가한다. 열람 후 L3 승격 대상.
