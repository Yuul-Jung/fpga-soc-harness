---
name: umd-phys495-basys3-xadc-voltmeter
url: https://www.physics.umd.edu/hep/drew/495/xadc.html
source_type: course
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [sensor, XADC, 7seg, LED]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.physics.umd.edu/hep/drew/495/xadc.html, https://physics.umd.edu/hep/drew/495/basys3io.html]
unverified: 저장소·소스 파일 공개 여부, 라이선스, 자원 사용, 강의 연도·Vivado 버전
---

## 요약
메릴랜드 대학(UMD) 물리학과 강의 실습. IP Catalog의 XADC 마법사로 단일 채널 전압계를 만들어 4자리 표시와 LED로 보여 준다. 클럭 설정과 읽기 시점의 함정을 자세히 다룬다.

## 구조
- 입력은 JXADC 핀 1(J3, 양)·핀 7(K3, 음) = VAUXP6/VAUXN6, 단극성 0~1 V. 12비트 결과가 16비트 출력 워드의 상위에 놓이고 1 LSB는 약 0.244 mV(페이지 표기).
- 마법사 설정: DRP 인터페이스, 단일 채널, 연속 모드, 채널 VAUX6, 경고 끔. daddr 0x16이 VAUX6이고 VAUX 주소는 0x10~0x1F.
- 설정 레지스터 0x40~0x42는 INIT 파라미터로 주고 DRP 쓰기는 쓰지 않는다. den을 eoc에 연결해 연속 변환.
- 변환값은 busy의 하강 에지에서 잡도록 권장한다(drdy 상승 에지 방식은 비권장으로 설명).
- 상위: 클럭 마법사, 디바운서, 4자리 표시 모듈, XADC 래퍼. 약 1초마다 표시 갱신.
- 입출력 보조 페이지: Basys3는 16쌍 중 4쌍만 JXADC에 연결, 입력 임피던스 약 10 kΩ·샘플링 커패시턴스 약 3 pF(페이지 표기).

## 검증·재현성
- 테스트 신호는 0.5 V 오프셋의 사인파. 테스트벤치·CI는 확인하지 못했다.

## 한계·위험
- 연속 단일 채널만 다루며 경고·온도 센싱 없음. 빠르게 변하는 신호는 이벤트 모드 또는 앞단 증폭이 필요하다고 페이지가 밝힌다.
- 내가 확인한 문서 내부 불일치: 같은 페이지에서 XADC 클럭을 50 MHz로 설명하다 104 MHz로 바꾸고, 104 MHz 입력에서 분주기 2 설정이면 ADCCLK이 페이지가 인용한 상한을 넘는다. 따라 하기 전에 UG480으로 클럭 분주를 다시 계산해야 한다(내 판단).
- 하위 비트는 실측 입력에서 흔들린다고 페이지가 적는다.

## 재사용 메모
- 내 판단: 클럭과 읽기 시점 설명이 상세해 XADC 래퍼를 직접 쓸 때 체크리스트로 쓸 만하다. 단 위 클럭 불일치는 그대로 따르지 않는다.
- 개조: 변환 완료(busy 하강)를 상태 비트와 인터럽트(`intc_free` 번호 후보)로 올리고 12비트 값을 읽기 전용 레지스터로 노출. 표시부는 동결 맵의 기존 GPIO/7세그 영역을 쓴다.
