---
name: oakland-ece378-group4-keyboard2vga
url: https://www.secs.oakland.edu/~llamocca/Courses/ECE378/FinalProject/Group4_Keyboard2VGA.pdf
source_type: report
vendor: amd
board: [Artix-7 (보드 미명시)]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: []
bus: none
peripherals: [hid-ps2, video-vga, comm-uart]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://www.secs.oakland.edu/~llamocca/Courses/ECE378/FinalProject/Group4_Keyboard2VGA.pdf]
unverified: 정확한 보드 모델과 Vivado 버전, 자원 사용량(보고서에 없음)
---

## 요약
Oakland University ECE 378 기말 프로젝트 보고서. PS/2 키보드로 VGA 화면에 글자를 입력하는 간이 텍스트 에디터이며, PC 터미널에서 UART 명령으로 글자색과 배경색을 바꾼다. 보고서에서 가장 쓸 만한 부분은 만들면서 겪은 버그 기록이다.

## 구조
- 두 블록: UART 블록(수신기 + 색 선택 디코더)과 PS/2 블록(`text_screen_top`).
- PS/2 블록: 키보드 수신기, 키 코드 해석 FSM(눌림/뗌 코드 처리, 확정·커서 이동 명령), 키코드→ASCII 변환, 문자 배치(커서, 줄바꿈, 화살표 이동), VGA 동기와 폰트 타일.
- 화면: 640×480, 8×8 타일로 80×60 글자, 픽셀 클럭 25 MHz로 가정. 색은 3비트 RGB라 글자·배경 8가지 조합.
- 키보드 변환·문자 생성 블록은 Chu의 VHDL 교재 예제에서 가져와 고친 것이라고 보고서가 밝힘 → 제3자 저작물 포함.

## 검증·재현성
- 동작 확인: 문자, 일부 기호, 공백, 백스페이스, 엔터, 화살표가 동작하고 UART 색 변경이 동작했다고 서술. 데모 영상 링크가 있음.
- 빌드 절차, xdc, 자원 사용: unverified: 보고서에 없음.

## 한계·위험
- 눌림/뗌 코드를 무시한 첫 설계는 한 번 누르면 글자가 두 번 찍혔다. 테스트벤치가 뗌 코드를 시뮬레이션하지 않아 시뮬레이션에서는 잡히지 않았고 보드에서 발견했다고 서술.
- 키를 누르고 있어도 반복 입력 없음, 조합키(Shift+숫자 등) 미지원, 폰트에 일부 기호 없음.
- 메모리 배열을 리셋으로 초기화하자 합성·구현 시간이 크게 늘었으나 원인은 규명하지 못했다고 서술.
- 소스 코드 링크 여부와 라이선스: unverified.

## 재사용 메모
- 내 판단: 수집 주제상 가치는 교훈에 있다. PS/2 수신 테스트벤치는 뗌(F0)과 확장(E0) 시퀀스를 반드시 넣어야 한다는 검증 항목의 근거.
- 내 판단: 키→VGA 텍스트 경로는 우리 SoC에서 VGA 텍스트 MMIO와 키보드 MMIO를 잇는 T3 단계 구성의 구조 참고가 된다. VHDL이고 보드가 달라 Verilog로 새로 쓰고 xdc 포팅이 필요.
