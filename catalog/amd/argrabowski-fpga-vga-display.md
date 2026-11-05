---
name: argrabowski-fpga-vga-display
url: https://github.com/argrabowski/fpga-vga-display
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: Verilog
tools: [Vivado 2021.1]
bus: none
peripherals: [video-vga, 7seg-mux, hid-btn, hid-sw]
stage: T2
license: unknown
stats: {stars: 1, commits: 2, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/argrabowski/fpga-vga-display]
---

## 요약

Basys3 Artix-7에서 VGA 패턴 애니메이션과 4자리 7세그먼트 hex 표시를 동시에 구동하는 Lab 2 프로젝트. 모드 선택에 따라 VGA 화면의 패턴/이동을 바꾸고, 7세그먼트에는 hex 값을 표시한다.

## 구조

- 모듈 3개: `vga_display.v`(VGA 패턴 생성·이동), `seven_seg.v`(4자리 hex 표시), `debounce.v`(버튼·스위치 디바운스)
- 최상위(`lab_2.xpr` Vivado 프로젝트) — VGA와 7세그먼트가 각각 독립 모듈로 구성됨
- 클럭: `clk_mmcm_wiz` IP 블록으로 클럭 관리 (100 MHz 입력에서 25 MHz VGA 픽셀 클럭 파생 추정)
- VGA: 패턴 생성 + 이동 (640×480 추정), 버튼·스위치로 모드 선택
- 7세그먼트: 4자리 hex 값 표시, 아노드 멀티플렉싱

## 검증·재현성

- Vivado 2021.1 프로젝트 파일(`lab_2.xpr`) 포함
- 테스트벤치: 미확인(L2, 디렉터리 목록만 열람)
- CI: 없음
- 자원 사용·WNS: 미확인
- unverified: 7-seg와 VGA의 공유 데이터 버스 구조, 우선순위 멀티플렉서 유무, 테스트벤치 존재 여부

## 한계·위험

- 라이선스 미기재 — 코드 가져오기 전 반드시 확인 필요
- 커밋 2건의 최소 이력 (최초 구현 단계)
- 7세그먼트와 VGA 간 데이터 공유 방식 미확인 (내 판단: 별도 포트로 분리된 독립 모듈 구조일 가능성 높음)

## 재사용 메모

- VGA 패턴 생성 모듈과 7세그먼트 멀티플렉서 모듈이 하나의 최상위에 공존하는 구조 — 7세그+VGA 동시 표시 패턴의 기본 참고 사례
- 개조: MicroBlaze V SoC 적용 시 VGA 모듈을 AXI4-Lite MMIO 슬레이브로 감싸고, 동결 맵(`config/soc_address_map.json`)의 VIDEO 슬롯에 배정; 7세그 IP는 기존 `mmio-7seg-adv-ip` 패키지와 연결 가능. `clk_mmcm_wiz` IP는 Vivado에서 재생성 필요
