---
name: digilent-basys-3-xadc-demo
url: https://digilent.com/reference/programmable-logic/basys-3/demos/xadc
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: unverified
tools: [Vivado 2022.1]
bus: none
peripherals: [sensor, XADC, 7seg, LED]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://digilent.com/reference/programmable-logic/basys-3/demos/xadc]
unverified: 읽기 방식(DRP/IP 구성), 소스 언어, 라이선스, 자원 사용(페이지에 없음, GitHub 소스 저장소는 열람하지 않음), 입력 범위 초과 시 동작
---

## 요약
Digilent가 공식 문서에 올린 Basys3 XADC 데모. JXADC 헤더의 차동 입력 한 쌍의 전압차를 LED 막대와 7세그먼트(볼트 단위)로 보여 준다. Vivado 프로젝트 압축 파일이 릴리스로 제공된다.

## 구조
- 아날로그 입력: JXADC의 차동쌍 XA1~XA4. 각각 XADC 채널 6, 14, 7, 15에 대응한다(페이지 표기).
- 입력 범위 0 V~1 V. 16개 LED가 전압차에 따라 한쪽에서 차오르고, 7세그먼트 두 자리가 선택한 쌍의 전압을 표시한다.
- SW0·SW1이 네 채널 중 표시 대상을 고른다.
- 릴리스 태그가 Vivado 버전(2020.1, 2021.1, 2022.1)에 묶여 있고 2018.2는 구성이 다르다고 적혀 있다.

## 검증·재현성
- Vivado 프로젝트(.xpr.zip)가 공식 릴리스로 제공되므로 xdc와 프로젝트 근거가 있다. 빌드 시간 5분~1시간이라는 안내가 있다.
- 테스트벤치, CI, 자원·타이밍 수치는 페이지에 없다.

## 한계·위험
- 읽기 방식과 라이선스가 페이지에 없어 코드 재사용은 라이선스 확인 필요.
- 입력 범위를 넘을 때 보호 방법은 이 페이지에 없다. 외부 신호를 직접 연결하기 전에 별도 확인이 필요하다(devices/xadc/basys3-jxadc.md 참고).

## 재사용 메모
- 내 판단: 아날로그 센서 입력 사다리의 가장 쉬운 단계. 공식 채널 대응표가 있어 xdc 핀 검증에 쓰기 좋다.
- 개조: 표시부(LED·7세그)를 떼고 변환값을 AXI4-Lite 읽기 전용 레지스터(채널별 12비트 값, 갱신 상태)로 노출. XADC 프리미티브 접근은 래퍼 안에 둔다. CPU 비종속 자료라 별도 CPU 개조 없음.
