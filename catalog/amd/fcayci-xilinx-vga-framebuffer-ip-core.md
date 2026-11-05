---
name: fcayci-xilinx-vga-framebuffer-ip-core
url: https://github.com/fcayci/xilinx_vga_framebuffer_ip_core
source_type: repo
vendor: amd
board: []
fit_basys3: needs-port
cpu: none(IP 코어, 호스트 버스 의존)
language: Verilog
tools: [Vivado]
bus: 듀얼포트 BRAM 공유 접근 (상위 버스 종류 미확인)
peripherals: [video-vga]
stage: T2
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/fcayci/xilinx_vga_framebuffer_ip_core]
---

## 요약 (검색 요약 기준)

Xilinx FPGA용 VGA 프레임버퍼 IP 코어. 듀얼포트 BRAM을 프레임버퍼로 사용하며, CPU(호스트)와 VGA 컨트롤러가 BRAM을 공유 접근하는 구조. Verilog로 작성.

## 구조
- 핵심 구조: 듀얼포트 BRAM 1개를 프레임버퍼로 사용; 포트 A = 호스트(CPU 쓰기), 포트 B = VGA 스캔 읽기
- 단일 버퍼 구조(더블 버퍼 여부 미확인): `unverified: 더블 버퍼·핑퐁 전환 여부는 본문 미열람`
- 대상 보드: `unverified: 보드명·FPGA 파트 미확인` (제목의 "Xilinx"로 Artix-7 계열 추정)
- 클럭·해상도: `unverified: 열람하지 못함`
- 버스 프로토콜(호스트 측): `unverified: AXI4-Lite 여부 미확인`

## 검증·재현성
- 검색 요약 외 열람 없음. 테스트벤치·CI 여부: `unverified`
- 자원 사용(LUT/FF/BRAM): `unverified`

## 한계·위험
- L2(검색 요약 기준)이므로 세부 사항은 열람 후 갱신 필요
- 보드별 XDC 제약 파일 포함 여부: `unverified`
- 단일 버퍼라면 프레임 전환 시 테어링 발생 가능성: `unverified`

## 재사용 메모
- 듀얼포트 BRAM 공유 접근 패턴(포트 A=CPU, 포트 B=VGA 스캔)은 Basys3 MicroBlaze V SoC의 VGA 주변장치 설계에 직접 적용 가능.
- 개조: AXI4-Lite 슬레이브 래퍼를 붙여 MicroBlaze V가 프레임버퍼에 AXI 쓰기를 하도록 연결. 버스 종류가 AXI가 아닌 경우 axil_regs.v 패턴으로 변환. 더블 버퍼(핑퐁)가 없으면 BRAM 2개로 확장해 VSync에서 버퍼 전환 로직 추가—Basys3의 225 KB BRAM 예산에서 160×120 × 1 byte × 2 = ~38 KB 소요, 여유 충분. 고정 맵 `free_slots` 중 64 KB 슬롯 1개를 프레임버퍼 쓰기 포트에 배정하고 `integration.plan`에 제안.
