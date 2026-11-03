---
name: opencores-onewire-ds1820
url: https://www.allaboutcircuits.com/ip-cores/communication-controller/onewire/
source_type: repo
vendor: neutral
board: [미명시]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: []
bus: none
peripherals: [sensor, 1-wire(DS1820)]
stage: T2
license: LGPL (페이지 표기, 코드 미열람)
stats: {created: 2018-08-07, last_update: 2020-01-27}
doc_language: en
verification: L2
checked_at: 2026-11-03
status: 검색 요약 기준(OpenCores 프로젝트 소개 페이지만 열람). 코드·README 본문 미열람
sources: [https://www.allaboutcircuits.com/ip-cores/communication-controller/onewire/]
unverified: 포트·레지스터 맵, 클럭 가정, 자원, 합성 이력, 저장소 URL과 커밋 SHA. 이 페이지에서는 열람하지 못함.
---

## 요약
OpenCores의 "Simple One Wire Controller with DS1820" 소개 페이지(페이지 서술). CPU 없이 동작하는 단순 1-Wire 컨트롤러와, 그 위의 DS1820 상위 컨트롤러(검색, 설정, 변환 시작, 읽기)로 구성되며 테스트벤치에 DS1820 시뮬레이션 모델이 있다고 한다.

## 구조
- 언어 VHDL, 라이선스 LGPL, 상태 Beta, WishBone 호환 아님(페이지 표기: n/a).
- 계층: 하위 1-Wire 마스터 + 상위 DS1820 컨트롤러(ROM 검색 포함, 페이지 서술).
- 레지스터 맵과 포트는 unverified.

## 검증·재현성
- 테스트벤치에 DS1820 모델 포함(페이지 서술). 시뮬레이터, 합성 결과는 unverified.

## 한계·위험
- 상태가 Beta이고 마지막 갱신이 2020년이다. LGPL이라 코드를 가져오면 조건이 따르므로 `config/policy.json` permissive 목록 밖일 가능성이 높다(확인 필요). 자동 모드에서는 코드를 가져오지 않는다.
- DS1820(구형)이라 DS18B20의 12비트 해상도 해석이 다를 수 있다(내 판단, 미검증).

## 재사용 메모
- 내 판단: "하위 비트 마스터 + 상위 센서 컨트롤러" 2계층과, 센서 모델이 들어간 테스트벤치 구성은 CI(iverilog/verilator) 시험 환경 설계의 참고가 된다. 코드는 가져오지 않고 자체 RTL로 새로 쓴다.
- 개조: CPU 자료가 아니다. 상위 컨트롤러의 검색 기능은 소프트웨어(MicroBlaze V)로 올리고 하드웨어는 비트·바이트 마스터만 두는 분담이 AXI4-Lite IP 표준에 더 맞는다(내 판단). 라이선스 확인 필요.
