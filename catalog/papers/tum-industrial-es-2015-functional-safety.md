---
name: tum-industrial-es-2015-functional-safety
url: https://archivedsite.air.in.tum.de/pub/Main/TeachingWs2015IndEmbSystems/Industrial_ES_7_WS2015.pdf
source_type: course
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(강의 자료, 하드웨어 플랫폼 비특정)
language: []
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://archivedsite.air.in.tum.de/pub/Main/TeachingWs2015IndEmbSystems/Industrial_ES_7_WS2015.pdf]
---

## 요약

TUM(뮌헨 공과대학) 2015년 겨울학기 "Industrial Embedded Systems" 강좌의 7번째 강의 슬라이드.
IEC 61508(기능 안전 국제 표준)의 핵심 개념인 FMEA/FMEDA, CRC 메모리 검사, 스택 보호, 진단 커버리지를 이론 위주로 설명한다.

## 구조

### IEC 61508 개요
- **SIL(Safety Integrity Level) 1~4**: 위험도에 따른 안전 요구사항 등급
- **PFD/PFH**: 요구 모드(PFD) / 연속 모드(PFH) 고장 확률 지표
- IEC 61508-2(하드웨어), IEC 61508-3(소프트웨어) 각각 테이블 형태로 요구사항 제시
- 진단 커버리지(Diagnostic Coverage): none / low / medium / high 4단계

### FMEA / FMEDA (Failure Mode Effects and Diagnostic Analysis)
- **FMEA**: 각 부품의 고장 모드 → 영향 → 심각도를 열거하는 표
- **FMEDA**: FMEA 확장. 각 고장 모드에 "진단으로 감지 가능한가"를 추가해 안전 고장 비율(SFF) 계산
- 목적: IEC 61508 하드웨어 무결성 요구 충족 근거 작성
- 슬라이드에 코드 없음; 개념과 절차 설명만 있음

### CRC 메모리 검사
- **수학적 기반**: 모듈로-2 다항식 나눗셈 (모듈로-2 나머지가 0이면 무결성 확인)
- **오류 감지 범위**: 단일 비트 오류 100% 감지, 짝수·홀수 비트 오류, 버스트 오류(CRC 길이 이하 100%) 감지; 다중 비트 오류의 경우 약 99.6% 감지율 (내 계산 근거 없이 슬라이드 수치 인용)
- **IEC 61508 Class B** 테스트: 프로그램 플래시의 CRC를 주기적으로 계산해 기준값과 비교
- 코드 없음; 원리와 커버리지 수치만 슬라이드에 있음

### 스택 보호
- 소프트웨어: 스택 최상단·최하단에 시그니처(패턴) 기록, 태스크 전환 시 체크
- 하드웨어: 일부 MCU에 하드웨어 스택 포인터 한계 레지스터 존재 (ARM Cortex-M 예시 간략 언급)
- 슬라이드에 구체 코드 없음

## 검증·재현성

- PDF 직접 열람 (L3). 아카이브 URL로 접근; 현재 TUM 웹사이트에서는 같은 URL로 접근 불가한 가능성 있음(아카이브이므로).
- 강의 자료이므로 소스 코드 없음. 개념과 수치의 출처는 IEC 61508 표준 (직접 확인하지 않음, unverified).
- 2015년 자료: IEC 61508:2010 기준. 최신 개정판 반영 여부 불명.

## 한계·위험

- 실습 코드 없음; 개념 이해용 자료.
- 2015년 작성: 최신 버전 Zephyr, FreeRTOS, MISRA C:2020 등은 미반영.
- CRC 커버리지 수치(99.6%)는 슬라이드 출처만 확인; 다항식 차수·데이터 길이에 따라 달라짐 (내 판단: 직접 계산하지 않았으므로 "슬라이드 인용"으로만 사용).
- 라이선스 불명: 대학 강의 슬라이드, 비상업적 학습 목적에만 사용 권장.

## 재사용 메모

- FMEA/FMEDA 절차와 IEC 61508 개념을 처음 익히는 데 적합. 캡스톤 보고서의 "안전 분석" 절 작성 시 참고 형식으로 활용 가능.
- `개조:` CRC 메모리 검사는 MicroBlaze V + Basys3 환경에서 AXI4-Lite CRC 검사 IP로 구현 가능. 프로그램 플래시(실제로는 BRAM 기반 명령 메모리) 내용의 CRC를 주기적으로 계산해 기준값과 비교하는 하드웨어 블록, 불일치 시 인터럽트 또는 시스템 리셋 출력. 옮길 수 없는 것: IEC 61508의 SFF 계산은 하드웨어 FMEDA가 필요하므로, Basys3 소프트코어 환경에서는 형식 인증보다는 설계 참고로만 활용.
