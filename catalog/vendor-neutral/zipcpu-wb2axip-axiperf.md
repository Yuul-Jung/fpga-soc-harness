---
name: zipcpu-wb2axip-axiperf
url: https://github.com/ZipCPU/wb2axip
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [iverilog, verilator, yosys]
bus: AXI4-Lite
peripherals: [performance-monitor]
stage: T2
license: Apache-2.0
stats: {stars: 422, forks: 94, last_update: 2026-06-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://zipcpu.com/blog/2021/08/14/axiperf.html, https://github.com/ZipCPU/wb2axip, https://repos.ecosyste.ms/hosts/GitHub/repositories/ZipCPU%2Fwb2axip]
---

## 요약

ZipCPU의 wb2axip 라이브러리 내 `rtl/axiperf.v` 모듈. AXI 버스 링크에 삽입해 레이턴시·처리량·스톨·유휴 사이클을 클럭 사이클 단위로 측정한다. AXI-Lite 제어 인터페이스(EasyAXIL 기반)로 start/stop/clear가 가능하다.

## 구조

- **측정 대상 버스**: 풀 AXI4 (읽기·쓰기 채널 별도 측정); 제어는 AXI4-Lite
- **읽기 측정 항목 (6종 bin)**: 레이턴시(`ARVALID`→첫 `RVALID`), 처리량(%), 스톨(`RVALID && !RREADY`), 주소 스톨(`ARVALID && !ARREADY`), 비트 수·버스트 수·바이트 수, 최대 버스트 크기, 최대 미결 버스트
- **쓰기 측정 항목 (15종 bin)**: 레이턴시(`AWVALID`→첫 `WVALID && WREADY`, 그리고 `BVALID && BREADY`까지), 스톨(`WVALID && !WREADY`, `BVALID && !BREADY`), 주소 스톨(`AWVALID && !AWREADY`), 슬로우 링크·슬로우 쓰기, write-bias (AW보다 W가 먼저 오는 경우), 버스트·바이트 계수
- **구현**: `casez` 기반 exclusive bin 분류, 포화 `active_time` 카운터(오버플로 시 모든 비트 1), 최대 미결 256개(초과 시 `perf_err` 세트 후 잠금)
- **파라미터**: `C_AXI_ID_WIDTH`에 따라 ID별 읽기 통계 생성, `OPT_LOWPOWER` 옵션(전력 절감용 게이팅)
- **제어 레지스터**: 최상위 주소 쓰기로 start(bit 0), clear(bit 1), stop

## 검증·재현성

- 작성자 블로그에서 ZipCPU + 블록 RAM + AXI DMA 구성, 100 MHz 가정 Dhrystone 시뮬레이션으로 검증 사례 서술(L3 열람)
- wb2axip 전체는 iverilog, verilator 테스트벤치 및 formal verification 구비
- 별 422, 포크 94 (ecosyste.ms 기준); 마지막 커밋 약 5개월 전 (2026-11-06 기준)
- `source_rev` 미확인: axiperf.v permalink SHA 없음 (PROVENANCE_REQUIRED로 GitHub 직접 열람 불가)

## 한계·위험

- 풀 AXI4 버스 모니터 (AXI-Lite 전용 소형 버전 별도 미제공)
- ID 비트 수가 넓으면 ID별 통계 테이블이 급격히 커짐 (2^C_AXI_ID_WIDTH 항목)
- 미결 버스트가 256을 초과하면 `perf_err` 고착; 수동 리셋 필요
- 테스트 설계(`axidmacheck`)에 arrowzip SDRAM 컨트롤러 사용 → Basys3(no-DRAM) 그대로 불가
- unverified: axiperf.v 단독 라이선스 명시 여부 (블로그에서 wb2axip 전체를 "Apache 2.0"으로 언급)

## 재사용 메모

AXI-Lite 주변장치가 여러 개인 Basys3 SoC에서 버스 경합·레이턴시 실측에 직접 활용 가능. `axiperf.v`는 순수 Verilog-2001로 vendor-neutral하므로 Vivado IP 없이 MicroBlaze V AXI-Lite 패브릭에 삽입 가능.

개조: 모니터 채널을 풀 AXI4 → AXI4-Lite로 단순화하면 (읽기: AR+R, 쓰기: AW+W+B 채널, 버스트 없음) 절반 이하의 카운터로 Basys3 AXI-Lite 버스 프로파일링 가능. MicroBlaze V의 `free_slots`(예: 0xC800_0000) 하나에 axiperf 제어 레지스터를 배정하면 C 드라이버(`Xil_Out32`/`Xil_In32`)로 start/stop/clear 제어 가능. 옮길 수 없는 것: arrowzip SDRAM 컨트롤러 및 autofpga 버스 연결 스크립트(Basys3 no-DRAM 제약), ZipCPU CPU 코어 종속 인터럽트 연결.
