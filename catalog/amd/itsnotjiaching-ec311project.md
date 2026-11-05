---
name: itsnotjiaching-ec311project
url: https://github.com/ItsNotJiaching/ec311project
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado 2024.1]
bus: none
peripherals: [video-vga, 7seg-mux, hid-btn, hid-sw]
stage: T2
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-12}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/ItsNotJiaching/ec311project]
---

## 요약

Boston University EC311 Fall 2024 기말 프로젝트. 2인 퐁(Pong) 게임으로 VGA에 게임 화면을 출력하고 4자리 7세그먼트 디스플레이에 점수를 동시에 표시한다. 공 속도는 패들 충돌 시마다 증가하고, 점수는 L00R 형식(예: 2003 = 왼쪽 2점·오른쪽 3점)으로 표시한다.

## 구조

- 최상위: `vga_top.v` — 게임 상태(시작/종료), 픽셀별 VGA 출력, 버튼·7세그먼트 연결
- VGA 경로: `vga_controller.v`(hsync/vsync, 25 MHz 픽셀 클럭) → `rectangle.v`(픽셀 위치 판별)
- 게임 로직: `ball.v`(위치·속도·충돌), `ball_collision.v`(패들 충돌 속도 변경), `paddle.v`(2인 패들, 스위치 입력)
- 표시: `score.v`(점수 유지 + 7세그먼트 아노드 멀티플렉싱 + case 세그먼트 디코딩)
- 클럭: `clk_divider.v`(100→25 MHz VGA), `game_clk_divider.v`(100→~13 MHz 게임 로직)
- 디렉터리: `1-module-code/`, `2-module-testbenches/`, `3-constraints/`
- 보드 미명시: Vivado 2024.1 + VGA 25 MHz + 7세그먼트 → Basys3 추정 (내 판단, `3-constraints/` 미열람)

## 검증·재현성

- Vivado 2024.1 프로젝트 파일(`0-all-project-files/ec311project.xpr`) 포함
- 테스트벤치: `2-module-testbenches/` 폴더 존재 (내용 미열람)
- CI: 없음
- 자원 사용·WNS: 미확인
- unverified: 정확한 보드명, XDC 내용, 테스트벤치 세부 항목

## 한계·위험

- 라이선스 미기재 — 코드 가져오기 전 반드시 확인 필요
- 보드 명칭 미기재 (README 기준 L2)
- 점수 최대 4점, 그 이상은 미처리 (게임 종료 로직 불명확)
- 커밋 수·별점 미확인 (GitHub 메인 페이지 L2)

## 재사용 메모

- VGA+7세그먼트 동시 표시 패턴의 실용적 사례: `score.v`가 7세그먼트 멀티플렉싱을 담당하고, `vga_controller.v`가 VGA 타이밍을 담당하는 명확한 모듈 분리 구조
- 개조: MicroBlaze V SoC 적용 시 ① `score.v`의 7세그먼트 로직 → 기존 `mmio-7seg-adv-ip`로 대체, ② `vga_controller.v` → AXI4-Lite MMIO VGA IP로 감쌈, ③ 게임 상태(공·패들 위치)는 AXI 레지스터로 소프트웨어와 공유. 패들 제어를 MicroBlaze 소프트웨어로 이식하면 T3 단계 SoC 게임 사례가 됨
