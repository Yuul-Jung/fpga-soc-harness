---
name: chclau-magellan-basys3-axil-regs
url: https://www.hackster.io/chclau/magellan-vhdl-hardware-monitor-for-basys-3-842c53
source_type: article
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(JTAG-to-AXI 마스터)
language: VHDL
tools: [Vivado 2018.2]
bus: AXI4-Lite
peripherals: [register-bank, 7seg]
stage: T2
license: unknown
stats: {stars: n/a, commits: n/a, last_update: "미확인"}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://www.hackster.io/chclau/magellan-vhdl-hardware-monitor-for-basys-3-842c53]
unverified: GitHub 소스 URL(Hackster 페이지에 존재한다고 명시됐으나 URL 미제공), 최신 갱신일, 쓰기 스트로브 처리 방법, VHDL 소스 본문
---

## 요약 (3줄 이내, 내 표현으로)

Basys3에서 JTAG-to-AXI 마스터와 AXI4-Lite 슬레이브 레지스터 파일을 연결한 하드웨어 모니터 데모. 소프트웨어 없이 Vivado TCL 명령으로 16개의 16비트 레지스터를 읽고 쓰며, 7세그먼트 디스플레이가 선택한 레지스터 값을 실시간 표시한다.

## 구조

**블록 구성 (Vivado 블록 디자인):**
- JTAG-to-AXI 마스터 (Xilinx IP): TCL 명령으로 AXI4-Lite 트랜잭션 발행
- AXI 인터커넥트: 마스터-슬레이브 연결
- 클럭·리셋 블록

**AXI-Lite 슬레이브 레지스터 뱅크 (VHDL 커스텀 모듈):**
- 총 레지스터: 16개, 각 16비트 폭 (Hackster 본문 기준)
- 오프셋 0x0: Version 레지스터 (읽기 전용)
- 오프셋 0x2: Date 레지스터 (읽기 전용)
- 나머지: 읽기/쓰기 레지스터
- 모니터 포트: `addr_mon[3:0]`으로 선택한 레지스터 값을 `data_mon[15:0]`에 출력
- 원본: "AXI-Lite registers bank VHDL module from Code Snippets"를 32비트→16비트로 개조

**7세그먼트 디코더 (`bin2_7seg`):**
- `data_mon` 값을 Basys3 4자리 7세그에 표시
- 스위치 0~3으로 `addr_mon` 선택

**TCL 접근 예시:**
- 읽기: `create_hw_axi_txn read_txn0 [get_hw_axis hw_axi_1] -type read -address a0000000`
- 쓰기: `create_hw_axi_txn write_txn2 [get_hw_axis hw_axi_1] -type write -address a0000004 -data 00005678 -force`

## 검증·재현성

- Hackster 페이지 전문 열람(2026-11-06, L3): 블록 다이어그램 설명, 레지스터 뱅크 구조, TCL 명령, Vivado 버전 직접 확인
- Vivado 2018.2 기준; 최신 버전(2024.2) 호환성 미확인
- Hackster 페이지에 GitHub에 소스 파일과 Vivado 2018.2 프로젝트 아카이브가 있다고 명시됐으나 URL 미제공, 소스 본문 미열람

## 한계·위험

- GitHub 소스 URL 미제공: 소스 접근 경로 불명확, 직접 재현 미확인
- 레지스터 폭 16비트: MicroBlaze V의 32비트 AXI 데이터 버스와 폭 불일치 (포팅 시 32비트로 확장 필요)
- 쓰기 스트로브(WSTRB) 처리 방법 Hackster 페이지에서 미확인(`unverified`)
- Vivado 2018.2 프로젝트 아카이브를 최신 버전으로 임포트 시 IP 업그레이드 경고 예상

## 재사용 메모

Basys3에서 소프트웨어(SDK/Vitis) 없이 JTAG-to-AXI 마스터로 레지스터 파일을 직접 접근하는 패턴은 IP 개발 초기 디버깅 환경으로 유용하다. 새 AXI4-Lite 슬레이브 IP를 개발할 때 이 패턴으로 소프트웨어 드라이버 없이 레지스터 동작을 먼저 확인할 수 있다.

개조: MicroBlaze V SoC에 연결 시: (1) 레지스터 폭 16비트→32비트로 확장, (2) 주소 베이스를 동결 맵 `free_slots`에서 배정, (3) `addr_mon`/`data_mon` 모니터 포트를 GPIO나 ILA 프로브로 대체, (4) VHDL 레지스터 뱅크를 Verilog-2001로 재작성하면 IP 표준 래퍼에 맞출 수 있다. JTAG-to-AXI 패턴은 CPU 비종속이므로 MicroBlaze V 전환 후에도 동일하게 활용 가능.
