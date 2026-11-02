---
name: markdannemiller-ttu-lab1-bc5-hardware-guide
url: https://github.com/MarkDannemiller/TTU-Lab1-BC5/wiki/7-%E2%80%90-Hardware-Guide
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: unverified: 위키 해당 쪽에 없음
language: unverified: 위키 해당 쪽에 소스 없음
tools: []
bus: none
peripherals: [actuator-servo, sensor]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L2
checked_at: 2026-11-02
sources: [https://github.com/MarkDannemiller/TTU-Lab1-BC5/wiki/7-%E2%80%90-Hardware-Guide]
---

## 요약
TTU 프로젝트 위키의 하드웨어 안내 쪽(저장소 전체는 열람하지 않아 L2). Basys3의 3.3V 출력으로 L298 기반 듀얼 H-브리지 보드를 구동하는 배선과 주의점을 서술한다. PWM 생성 RTL은 이 쪽에 없다.

## 구조
- 제어: Basys3 JA Pmod에 H-브리지 제어선, 전류 감지(SNS A)와 GND는 JX Pmod(XADC)로 연결해 전류를 읽는 구성.
- 모터 전압 상한 13V (11.1V 리튬이온 직결 가정). 모터마다 직렬 인덕터와 병렬 소형 커패시터를 두어 역방향 전류·잡음을 완화한다고 서술.
- 속도는 전압을 낮추지 않고 PWM으로 조절해 토크를 유지한다고 서술.

## 검증·재현성
- unverified: 테스트벤치·빌드 방법·자원 사용은 이 쪽에 없고 저장소 본체를 열람하지 않음. source_rev도 미고정.

## 한계·위험
- 모터 전원과 논리 전원의 분리 여부는 이 쪽에서 다루지 않음.
- 라이선스 unknown → 코드 반입 불가, 배선 사실만 참고.

## 재사용 메모
- 내 판단: 모터 전류를 XADC(JX Pmod)로 읽는 구성은 과전류 보호 래퍼(I-014)의 전류 입력 후보다. XADC 입력 범위(1V)는 별도 확인 필요.
- 개조: 해당 없음 (CPU 비종속). 저장소 본체를 열람해 L3로 올릴 후보.
