---
name: opencores-nec-ir-decoder
url: https://opencores.org/projects/nec_ir_decoder
source_type: repo
vendor: neutral
board: [DE0-Nano]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: []
bus: none
peripherals: [IR 수신(NEC)]
stage: T1
license: LGPL (버전 미기재, 페이지 표기)
stats: {created: 2015-10, last_update: 2019-11}
doc_language: en
verification: L3
checked_at: 2026-11-03
status: 프로젝트 소개 페이지 두 곳(OpenCores, AllAboutCircuits 미러)만 열람. 코드 미열람(다운로드·이슈는 로그인 필요)
sources: [https://opencores.org/projects/nec_ir_decoder, https://www.allaboutcircuits.com/ip-cores/communication-controller/nec-ir-decoder/]
unverified: 포트·모듈 구성, 커밋/리비전, 자원, 갱신일(OpenCores 페이지는 2015-10-06, AAC 미러는 2019-11로 서로 다름)
---

## 요약
NEC 적외선 리모컨 프레임을 해독하는 Verilog 코어. 9 ms 리더 버스트, 4.5 ms 공백, 주소·주소 반전·명령·명령 반전 각 8비트, 562.5 µs 종료 버스트를 다룬다. 상태는 Beta이며 FPGA에서 동작 확인(proven)이라고 표기됐다.

## 구조
- 시스템 클럭 50 MHz를 가정. DE0-Nano(Altera)에서 시험했다고 서술.
- WISHBONE 비호환(페이지 표기).
- 모듈·포트 구성은 페이지에 없음(unverified).

## 검증·재현성
- 시험은 DE0-Nano 실기 1건(페이지 서술). 테스트벤치 여부 unverified.

## 한계·위험
- 반복 코드(버튼을 누르고 있을 때 오는 짧은 프레임) 미구현이라고 두 페이지가 동일하게 서술.
- LGPL이므로 코드 반입 불가, 참고 전용.
- 내려받기와 이슈 등록이 로그인을 요구해 코드를 읽지 못했다(§7에 따라 로그인하지 않음).

## 재사용 메모
- 내 판단: 100 MHz Basys3에서는 50 MHz 가정의 카운터 상수를 두 배로 해야 한다(내 계산). 반복 코드 미구현은 로봇 조종에서 "누르고 있는 동안 주행"에 영향을 주므로 별도 처리가 필요하다.
- 개조: 해독 결과(주소·명령·유효·반복 플래그)를 AXI4-Lite 읽기 레지스터와 인터럽트 한 개로 노출하는 래퍼. 코드는 자체 RTL로 새로 쓴다.
- 라이선스 확인 필요.
