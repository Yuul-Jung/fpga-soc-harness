---
name: unilim-vahid-xadc-basys3-vhdl
url: https://www.unilim.fr/pages_perso/vahid/XADCinBasys3.html
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: VHDL
tools: [Vivado 2018.2]
bus: none
peripherals: [sensor, XADC, LED]
stage: T1
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.unilim.fr/pages_perso/vahid/XADCinBasys3.html]
unverified: 소스 파일 공개 여부, 라이선스, 자원 사용, 테스트벤치, JA 핀 사용 가능 여부(페이지 내부 모순)
---

## 요약
프랑스 리모주 대학 개인 페이지의 VHDL 튜토리얼. XADC 마법사 IP로 단일 채널 연속, 단일 채널 이벤트(convst) 구동, 두 채널 동시 이벤트의 세 모드를 Basys3에서 LED로 확인한다.

## 구조
- XADC 마법사 `xadc_wiz_0`, den은 eoc에, daddr은 channel_out에 연결. DRP로 drdy 후 do_out을 읽는다.
- 모드: ① 단일 채널 연속 ② 단일 채널 이벤트: convst를 카운터로 만들며 convst~eoc 약 102 클럭, 100 MHz에서 100 kHz 샘플링 예 ③ 두 채널 동시 이벤트(VAUX4, VAUX12), 상태 머신이 채널을 번갈아 읽는다.
- 출력은 16비트 do_out을 LED로 연결, 상위 12비트만 유효. 입력 0~1 V 단극성, 정격 1 MSPS(페이지 표기).
- 제약: Basys3_master.xdc의 clk·LED·JA 줄을 활성화.

## 검증·재현성
- 튜토리얼 수준이며 테스트벤치·자원 수치 없음. Vivado 2018.2 한 버전 기준.

## 한계·위험
- 내가 확인한 문서 내부 모순: JXADC·JA 핀은 VAUX에 쓸 수 없다고 적은 직후 JA 핀을 VAUX 입력으로 나열하고, 시험 단계의 핀 번호도 앞의 대응표와 다르다. 핀 대응은 Digilent 공식 데모(digilent-basys-3-xadc-demo)와 대조해야 한다(내 판단).
- 개인 페이지이며 출처 표기가 없는 서술(타입 무시 등)이 있다.

## 재사용 메모
- 내 판단: 이벤트 모드(고정 주기 샘플링)와 두 채널 동시 샘플링 예가 있어 센서 두 개를 같은 시점에 읽는 IP(예: 전류·전압)의 FSM 참고가 된다.
- 개조: convst 주기 카운터를 레지스터(샘플 주기, 시작, 상태)로 노출하는 AXI4-Lite 래퍼로 옮긴다. 두 채널 결과는 읽기 전용 레지스터 두 개. CPU 비종속.
