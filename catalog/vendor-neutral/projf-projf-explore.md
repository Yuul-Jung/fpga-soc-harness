---
name: projf-projf-explore
url: https://github.com/projf/projf-explore
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(순수 RTL 그래픽 IP)
language: SystemVerilog
tools: [Vivado, iCEcube2, openXC7]
bus: none
peripherals: [video-vga]
stage: T2
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/projf/projf-explore, https://github.com/projf/projf-explore/blob/main/graphics/fpga-graphics]
---

## 요약 (검색 요약 기준)

Project F: FPGA 그래픽·게임 구현 교육 저장소. `graphics/fpga-graphics` 하위에 BRAM 기반 타일·스프라이트·애니메이션 예제를 포함하는 SystemVerilog 튜토리얼 시리즈. 다양한 보드(Arty S7, iCE40 UP5K 등)를 지원하며, VGA/HDMI 출력과 BRAM 프레임버퍼·더블 버퍼 패턴을 교육적으로 다룬다.

## 구조
- `graphics/fpga-graphics` 경로: VGA 그래픽 튜토리얼 시리즈
- BRAM 기반 프레임버퍼·타일맵·스프라이트 예제 포함 (검색 결과 기준; 세부 모듈명 `unverified`)
- 더블 버퍼(핑퐁) 구현 여부: `unverified: 본문 미열람, 검색 중 animation/double buffer 언급 없음`
- 보드: Arty S7, iCE40 UP5K — Basys3용 XDC 없음, 클럭/핀 포팅 필요
- 언어: SystemVerilog (Verilog-2001로 재작성 필요)
- 클럭·해상도: `unverified`

## 검증·재현성
- 검색 요약 기준. GitHub Stars·CI 여부: `unverified`
- 테스트벤치: `unverified`
- 자원 사용: `unverified`

## 한계·위험
- SystemVerilog 전용 → Basys3 Vivado에서 사용 가능하나 iverilog/Verilator 호환성 확인 필요
- Basys3 XDC 없음: 클럭 25 MHz VGA, 100 MHz 시스템 등 포팅 필요
- 보드별 세부 구조 미확인(L2)

## 재사용 메모
- BRAM 기반 그래픽 타일·스프라이트 패턴은 Basys3 no-dram 환경에서 가장 현실적인 VGA 그래픽 접근법이며, 이 저장소가 그 사례를 체계적으로 모은 교육 자료로 보임.
- 개조: SystemVerilog → Verilog-2001로 재작성(기능은 동일, iverilog/Verilator 호환). VGA 타이밍 모듈(`vga_timing`)을 MicroBlaze V SoC의 VGA 주변장치 RTL로 개조. 타일맵 BRAM을 AXI4-Lite 슬레이브 래퍼로 감싸 CPU가 직접 쓰도록 구성. Basys3 12비트 VGA 저항 DAC에 맞는 색상 비트폭(4비트×3채널)으로 조정. 더블 버퍼가 있으면 VSync 신호를 버퍼 전환 트리거로 사용하는 패턴 채택—MicroBlaze V는 쓰기 완료 후 레지스터에 swap 비트 세트.
