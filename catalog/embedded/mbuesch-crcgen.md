---
name: mbuesch-crcgen
url: https://github.com/mbuesch/crcgen
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(소프트웨어 도구)
language: Python (출력: Verilog | VHDL | MyHDL)
tools: [Python 3, iverilog(검증용)]
bus: none(조합 논리 출력, 버스 래퍼 별도)
peripherals: []
stage: T2
license: MIT
stats: {stars: 211, commits: unknown, last_update: 2024-10-01}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/mbuesch/crcgen, https://bues.ch/h/crcgen, https://pypi.org/project/crcgen/]
---

## 요약

임의 CRC 다항식에 대한 합성 가능한 HDL 코드(Verilog, VHDL, MyHDL)를 자동 생성하는 Python 명령줄 도구. CRC-8/16/32는 물론 사용자 정의 다항식도 지원. 출력은 순수 조합 논리(combinational)로 레지스터 없이 한 클럭에 CRC를 계산한다(S1 인접 도메인 이식: 소프트웨어 CRC 명세를 하드웨어 Verilog로 직접 변환).

## 구조

- **입력 파라미터**: CRC 너비(crcWidth), 다항식(polynomial), 비트 반전(reflect-in/out), 초기값(xorIn), 최종 XOR(xorOut)
- **출력 형식**: Verilog / VHDL / MyHDL (CLI 옵션 `--verilog`, `--vhdl`, `--myhdl`)
- **생성 로직**: 병렬 XOR 트리 — data_in 각 비트별로 CRC 비트에 미치는 영향을 행렬 계산으로 전개. 결과는 `function CRC_<n>(input [w-1:0] data, input [n-1:0] crc) → output [n-1:0]` 패턴
- **사전 정의 프로필**: `--crc-type` 옵션으로 CRC-16-CCITT, CRC-32-IEEE, CRC-32C, CRC-8-MAXIM 등 표준 명세 직접 선택 가능
- **데이터 너비**: `--data-width` 옵션으로 8/16/32비트 단위 조정 가능
- **검증**: 생성된 Verilog를 iverilog로 시뮬레이션해 소프트웨어 CRC와 비교하는 단위 테스트 포함(Python `unittest`)

## 검증·재현성

- MIT 라이선스. PyPI에 `crcgen` 패키지로 배포(`pip install crcgen`)
- 생성된 Verilog는 순수 Verilog-2001 호환. iverilog, Vivado, Yosys 모두 처리 가능
- unverified: 별 수 (검색 요약 기준 211, 실제 확인 미완)
- unverified: 최신 커밋 날짜 (pypi 패키지 버전 2.3 기준 2024년으로 추정, 미열람)

## 한계·위험

- 도구가 생성한 Verilog는 조합 논리만: AXI4-Lite 버스 인터페이스, 레지스터, 인터럽트는 별도 작성 필요
- 스트리밍(multi-word) CRC 계산을 위한 프레이밍(reset, accumulate) 로직도 별도 필요
- Basys3 보드 전용 XDC 없음 (범용 도구이므로 당연)

## 재사용 메모

가져올 수 있는 부분: 다항식 행렬 계산 로직. `python3 -m crcgen --verilog --crc-type CRC-32 --data-width 8` 실행 시 8비트 단위 CRC-32 Verilog 함수 즉시 생성. 이를 AXI4-Lite 슬레이브 래퍼로 감싸면 MicroBlaze V에서 직접 사용 가능.

개조: AXI4-Lite 래퍼 작성 절차 — ① crcgen 생성 Verilog(순수 조합)를 `crc32_core.v`로 저장 ② `axil_crc32.v` 슬레이브 모듈에서 DATA_IN(0x00), CTRL(0x04, bit0=load), STATUS(0x08), RESULT(0x0C) 레지스터 4개 구현 ③ 동결 맵 `free_slots` 한 칸(64KB)에 배정 제안. 못 옮기는 부분: 도구 자체(Python)는 Verilog 소스 생성기이므로 FPGA에 올라가지 않는다. 생성된 Verilog만 IP로 활용.
