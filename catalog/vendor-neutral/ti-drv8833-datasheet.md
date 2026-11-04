---
name: ti-drv8833-datasheet
url: https://www.ti.com/document-viewer/DRV8833/datasheet/detailed_description
source_type: report
vendor: neutral
board: [없음 (모듈 데이터시트)]
fit_basys3: needs-port
cpu: none(FSM)
language: unverified: 데이터시트에 HDL 없음
tools: []
bus: none
peripherals: [actuator-servo]
stage: T2
license: 제조사 저작물 (링크·요약만, 반입 없음)
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://www.ti.com/document-viewer/DRV8833/datasheet/detailed_description]
---

## 요약
TI DRV8833 듀얼 H-브리지 드라이버 데이터시트의 상세 설명 절(열람 범위: 이 절). 채널당 IN1/IN2 두 선만으로 방향과 감쇠 방식(빠른/느린)을 고르는 구성이며, nFAULT·nSLEEP 핀을 가져 FPGA에서 상태 레지스터로 연결하기 좋다.

## 구조
- 모터 전원 VM 2.7~10.8V, 출력 최대 1.5A RMS, NMOS H-브리지 2개(브러시 DC 2개 또는 2상 스테퍼 1개).
- 진리표(xIN1/xIN2): 0/0 코스트(Z/Z, 빠른 감쇠), 0/1 역방향, 1/0 정방향, 1/1 브레이크(L/L, 느린 감쇠).
- PWM 방식: 정방향 빠른 감쇠는 IN1에 PWM·IN2=L, 정방향 느린 감쇠는 IN1=H·IN2에 PWM. 역방향은 역할 교환.
- nSLEEP: L이면 H-브리지·차지펌프 정지, 입력 무시. H로 복귀 후 정상 동작까지 최대 1ms. 내부 500kΩ 풀다운.
- 전류 제한: xISEN 저항 전압을 200mV 기준과 비교해 초핑(한계전류=200mV/저항, 예 1Ω→200mA), 블랭킹 3.75µs. 쓰지 않으면 xISEN을 GND에 직결.
- 보호: 과전류(OCP)는 해당 브리지만 정지 후 재시도, 과열(TSD)과 저전압(UVLO)은 nFAULT를 L로 내림.

## 검증·재현성
- HDL·테스트벤치 없음. 논리 입력 문턱 전압과 PWM 최대 주파수는 열람 범위에 없음 (unverified: 같은 문서의 전기 특성 절 미열람).

## 한계·위험
- 문서 내 불일치: 표는 UVLO를 오류 미보고로 적고 본문은 nFAULT가 L이 된다고 서술. 본문을 따름(더 구체적).
- 입력 문턱 미확인이므로 FPGA 3.3V 직결 가능 여부는 확정하지 말 것.

## 재사용 메모
- 내 판단: 감쇠 방식이 입력 조합으로 정해지므로 IP에 `decay` 모드 비트를 두면 한 레지스터로 4가지 구동(정/역 × 빠른/느린)을 표현할 수 있다.
- 내 판단: nFAULT 입력을 상태 레지스터와 인터럽트 소스로 올리고, 과전류 시 PWM 출력을 하드웨어에서 끄는 안전 래퍼(I-014)의 근거로 쓸 수 있다.
- 개조: 해당 없음 (CPU 비종속 부품 자료).
