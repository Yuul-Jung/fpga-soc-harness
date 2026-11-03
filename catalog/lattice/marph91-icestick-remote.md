---
name: marph91-icestick-remote
url: https://www.github.com/marph91/icestick-remote
source_type: repo
vendor: lattice
board: [iCEstick]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [ghdl, yosys, nextpnr, icestorm]
bus: none
peripherals: [IR 송신(적외선 LED), IR 샘플러, comm-uart(PC 제어)]
stage: T2
license: GPL-3.0
stats: {stars: 8, forks: 0}
doc_language: en
verification: L3
checked_at: 2026-11-03
sources: [https://www.github.com/marph91/icestick-remote]
unverified: 커밋 SHA(페이지에 최신 커밋 표시 없음), 최상위 포트, 펄스 거리 부호화의 클럭·분주 값(hdl/ 파일 미열람), NEC 동작(저자가 미시험이라 서술)
---

## 요약
Lattice iCEstick(iCE40)으로 적외선 리모컨 신호를 보내고 표본 수집까지 하는 VHDL 프로젝트. PC의 파이썬 GUI가 UART로 FPGA에 지시하면 FPGA가 IR LED로 코드를 내보낸다. 기본 프로토콜은 Panasonic의 Kaseikyo이고, 같은 펄스 거리 방식의 다른 프로토콜을 추가하기 쉽다고 한다.

## 구조
- 폴더: gui(파이썬 제어 스크립트), hdl(최상위·IR 인코더·샘플러), sim(자동·수동 시험), submodules(icestick-uart), syn(합성 스크립트·제약).
- 오픈소스 흐름(ghdl + yosys + nextpnr + icestorm)으로 합성. `syn`에서 make, make load 순서.
- 자원(README 표): ICESTORM_LC 474/1280(37%), RAM 2/16(12%), SB_IO 11/112(9%), SB_GB 4/8(50%).
- NEC는 generic으로 켤 수 있으나 시험하지 않았다고 서술.

## 검증·재현성
- 실기 시험은 Panasonic TV 1종. `.github/workflows`에 스크립트 점검, 합성, 시험 묶음 워크플로가 있다(내용 미열람).

## 한계·위험
- GPL-3.0이므로 코드를 가져오지 않고 구조만 참고한다(참고 전용).
- NEC 미시험, 수신(디코딩)보다 송신·표본 수집이 중심(내 판단: README 서술 기준).

## 재사용 메모
- 내 판단: "PC에서 UART로 코드를 지정해 IR로 쏘는" 구조는 Basys3에서 실제 리모컨 없이 디코더를 시험하는 신호원으로 쓸 수 있다. 같은 FPGA 두 장 또는 한 장의 송수신 루프백이 가능하다.
- 개조: 송신 FSM을 AXI4-Lite 레지스터(주소·명령·전송 시작·BUSY)로 감싸고, UART 제어는 MicroBlaze V 펌웨어로 대체. 38 kHz 반송파는 100 MHz 분주 2632(내 계산). CPU 코어 의존 부분 없음.
- 라이선스 확인 필요(GPL-3.0, 코드 반입 불가).
