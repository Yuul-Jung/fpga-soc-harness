---
name: oakland-ece378-group7-paintervga
url: https://www.secs.oakland.edu/~llamocca/Courses/ECE378/FinalProject/Group7_PainterVGA.pdf
source_type: report
vendor: amd
board: [Nexys4]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: []
bus: none
peripherals: [hid-ps2, video-vga]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 2026-11-02 /verify 재열람 시도 실패(WebFetch 권한 요청 미응답) — 이번 사이클 미대조, rechecked_at 미기록
sources: [https://www.secs.oakland.edu/~llamocca/Courses/ECE378/FinalProject/Group7_PainterVGA.pdf]
unverified: Vivado 버전, 자원 사용량 수치, 소스 공개 여부와 라이선스
---

## 요약
Oakland University ECE 378 기말 프로젝트 보고서. PS/2 마우스로 VGA 화면에 그림을 그리는 간단한 그림판. 왼쪽 버튼을 누른 채 끌면 그려지고, 클릭으로 색을 고르며, 스위치로 화면을 지운다.

## 구조
- 상위 두 모듈: `mouse_top`(마우스 입력과 커서 로직), `VGA_Control`(타이밍과 RAM).
- 마우스: 버튼 신호와 9비트 x/y 이동량을 받아 10비트 x/y 커서 좌표와 왼쪽 버튼 신호로 변환.
- 화면: 640×480, 픽셀당 3비트 색. 이중 포트 RAM의 한 포트는 hcount/vcount를 따라 계속 읽어 화면을 갱신하고, 다른 포트는 버튼이 눌린 동안 커서 위치에 쓴다.
- 표시 우선순위: 커서가 가장 높고 그림 영역은 그 아래(보고서 서술).

## 검증·재현성
- 결과: 임의 픽셀에 색을 쓰고, 8색으로 그리고, 스위치로 흰색 초기화가 동작한다고 서술.
- 시뮬레이션, 빌드 절차, 자원 사용량: unverified: 보고서에 없음.

## 한계·위험
- 메모리 한계 때문에 12비트 색 계획을 3비트로 줄이고 단일 포트 RAM을 이중 포트로 바꿨다고 서술. 내 판단: 640×480×3비트 프레임 버퍼는 Basys3의 BRAM(XC7A35T)에 그대로 들어가는지 확인이 필요해 계산 없이 단정할 수 없다. `bram-bound` 후보.
- 저장·커서 크기 변경·텍스트는 미구현(향후 과제로 기재).
- 보드는 Nexys4(보고서 표기) → Basys3 포팅 필요: 마우스는 Basys3에서 USB HID→PS/2 에뮬레이션 경로이며 키보드와 동시 사용 불가.

## 재사용 메모
- 내 판단: 마우스 패킷→커서 좌표→VGA 오버레이 구조는 우리 SoC의 마우스 MMIO(좌표·버튼 레지스터)와 VGA 커서 레이어를 설계할 때 구조 참고가 된다. 프레임 버퍼를 쓰지 않고 커서 오버레이만 두는 축소판이 `no-dram` 보드에 더 맞다.
- 코드는 가져오지 않는다. 라이선스 unknown.
