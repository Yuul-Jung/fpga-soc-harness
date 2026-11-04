---
name: rpshredow-fpga-raspberry-image-display
url: https://github.com/rpshredow/FPGA-Raspberry-Image-Display
source_type: repo
vendor: intel
board: [DE0]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Quartus]
bus: SPI
peripherals: [video-vga, comm-spi]
stage: T2
license: unknown
stats: {stars: 0, forks: 1, commits: 3, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://github.com/rpshredow/FPGA-Raspberry-Image-Display]
unverified: README 본문·라이선스 직접 열람하지 못함(PROVENANCE_REQUIRED), 파일 목록과 파일명에서 추론
---

## 요약

Raspberry Pi가 SPI로 이미지 데이터를 DE0(Intel/Altera) FPGA에 전송하면 FPGA가 VGA 모니터에 표시하는 프레임 전송·디스플레이 시스템. MATLAB으로 MIF 파일을 생성해 초기 이미지를 BRAM에 적재하는 흐름도 있다.

## 구조

- RPi(SPI 마스터) → DE0 FPGA(SPI 슬레이브 + VGA 출력)
- Verilog 모듈: `PixCounter.v`, `Counter.v`, `VGAInterface.v`, `SPI 슬레이브(추정)`
- RAM IP: `ram.qip`·`ram_bb.v`(Quartus MegaWizard)로 BRAM 구성
- MIF 초기화: MATLAB `miffilegen.m`으로 이미지 → `.mif` 변환
- 7세그먼트 디버그 출력(`LED_7seg.v`)
- 샘플 이미지: 너클스·스펀지밥 변형본 포함(제3자 저작물 — 위험 항목)

## 검증·재현성

- unverified: 빌드·시뮬레이션 절차 직접 확인 불가
- 커밋 3개; 완성도 불확실
- 라이선스 없음 → 코드 가져올 경우 "라이선스 확인 필요"

## 한계·위험

- Intel/Altera Quartus 전용; Basys3(Vivado/Artix-7)로 옮기려면 xdc·클럭·BRAM IP 교체 필요
- 샘플 이미지에 상용 캐릭터(너클스, 스펀지밥) 포함 — 저작권 주의, 구조 참고용으로만 활용
- 라이선스 미기재 → `코드 복사 금지, 아이디어·구조만 참고`
- last_update 날짜 미확인

## 재사용 메모

- Basys3 연결 경로: "RPi → SPI → FPGA BRAM → VGA" 흐름은 Basys3에서도 Pmod SPI 슬레이브 IP + VGA 타이밍으로 구현 가능
- 개조: SPI 슬레이브 FSM·BRAM 주소 디코더·VGA 타이밍 로직은 Verilog-2001로 재작성 대상(Quartus → Vivado). AXI4-Lite 래퍼를 붙이면 MicroBlaze V에서 프레임 버퍼 직접 접근 가능. 라이선스 없으므로 코드 복사 불가, 사양(포트·타이밍)만 참고.
