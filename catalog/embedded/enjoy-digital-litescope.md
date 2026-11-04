---
name: enjoy-digital-litescope
url: https://github.com/enjoy-digital/litescope
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: VexRiscv | LiteX SoC 임의 CPU
language: Python(Migen/LiteX HDL)
tools: [LiteX, Vivado, yosys+nextpnr]
bus: Wishbone | AXI-Lite (LiteX SoC 버스 선택)
peripherals: [debug]
stage: T3
license: BSD-2-Clause
stats: {stars: 300, commits: 500, last_update: 2024-10-01}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://software.mcgoron.com/peter/litescope (mirror README), https://github.com/enjoy-digital/litescope]
---

## 요약

LiteX SoC 프레임워크와 통합된 FPGA 소프트 논리 분석기. Python(Migen HDL)으로 작성되어 Verilog가 아닌 LiteX 환경에서만 쓸 수 있다. UART·Ethernet·PCIe를 PC 브리지로 지원하며, 파형은 .vcd/.sr/.csv로 출력한다. `litescope_cli`와 `litescope_server`로 PC에서 원격 제어. 별도 `peek`/`poke`로 레지스터 직접 접근도 가능하다. GitHub 직접 열람 불가(PROVENANCE_REQUIRED), mirror README로 L2 등급 부여.

## 구조 (mirror README 기준, L2)

- **LiteScopeAnalyzer**: FPGA 온칩 모듈 — 모든 LiteX SoC 버스 신호·사용자 신호 계측
- **LiteScopeBridge**: UART, Ethernet, PCIe 중 선택해 PC에 연결
- **PC 클라이언트**: `litescope_cli` (CLI 파형 덤프), `litescope_server` (Sigrok .sr 형식 출력)
- **출력 포맷**: .vcd(GTKWave), .sr(PulseView), .csv(Excel 등)
- **트리거**: Python 측 조건식(Rising/Falling/Edge/Sum)으로 선언
- **통합**: `migen`/`litex.soc.interconnect.csr` 모듈로 SoC에 CSR 자동 추가
- unverified: 채널 수·샘플 깊이 상한, BRAM 소모량 (mirror README에 미명시)

## 검증·재현성

GitHub PROVENANCE_REQUIRED로 직접 열람 불가 → mirror README 열람(L2). `litex` 의존성 필요. Basys3에서 테스트된 사례 미확인(LiteX 공식 문서에 Basys3는 RAM 없는 보드로 표기). yosys+nextpnr 경로에서도 사용 가능.

## 한계·위험

- **LiteX 종속성**: LiteX SoC 프레임워크 없이 단독 사용 불가. MicroBlaze V SoC에 직접 붙일 수 없음.
- **Basys3 제약**: Basys3는 외부 RAM이 없어 샘플 깊이가 BRAM 용량으로 제한됨. LiteX 공식 문서에 Basys3를 'no DRAM 보드'로 표기.
- **Python HDL**: Verilog가 아닌 Migen/LiteX Python HDL로 작성 — RTL 직접 수정 어렵고, iverilog·verilator로 직접 린트 불가.
- **L2 등급**: mirror README만 열람. 채널 수·샘플 깊이·BRAM 소모 등 핵심 수치 미확인.

## 재사용 메모

- LiteX+VexRiscv SoC(CFU-Playground 등)로 작업할 때 온칩 디버그 도구로 가장 적합한 선택. MicroBlaze V 기반 프로젝트에는 직접 쓸 수 없음.
- **개조**: MicroBlaze V SoC 대응은 직접 이식 불가. 대신 ① 아이디어 측면: LiteScope의 `트리거 선언→CSR 자동 추가→.vcd 출력` 패턴을 AXI4-Lite 래퍼+VexRiscv 조합으로 참고 가능 ② 구현 측면: sampler·trigger·UART dump 로직은 사양을 참고해 MicroBlaze V용 AXI4-Lite IP로 자체 작성해야 함 ③ 출력 포맷: .vcd를 직접 출력하면 GTKWave에서 Vivado ILA 없이 파형 확인 가능(내 판단). `free_slots` 활용 시 샘플 메모리는 AXI BRAM Controller로 연결 추천.
