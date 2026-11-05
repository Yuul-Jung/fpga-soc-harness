---
name: bugratufan-axion-hdl
url: https://pypi.org/project/axion-hdl/0.3.1/
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(레지스터 생성 도구)
language: Python
tools: []
bus: AXI4-Lite
peripherals: []
stage: T2
license: MIT
stats: {stars: n/a, commits: n/a, last_update: "2025 (v1.7.1 최신)"}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://pypi.org/project/axion-hdl/0.3.1/, https://axion-hdl.readthedocs.io/en/stable/outputs.html]
unverified: GitHub `bugratufan/axion-hdl` 소스 본문 및 테스트 현황(PROVENANCE_REQUIRED로 미열람), 별 수, Basys3/Vivado IP 패키징 절차
---

## 요약 (3줄 이내, 내 표현으로)

VHDL 소스의 `@axion` 주석에서 AXI4-Lite 슬레이브 레지스터 인터페이스와 C 헤더·XML 등록 맵을 자동 생성하는 Python CLI 도구. MIT 라이선스. 레지스터별 접근 모드(RO/WO/RW) 선언으로 읽기/쓰기 스트로브와 선택적 CDC 동기화기를 포함한 VHDL 또는 SystemVerilog 슬레이브를 출력한다.

## 구조

**입력:**
- VHDL 소스 파일에 `@axion` 태그로 레지스터와 필드를 선언
- `csrconfig` 파일의 `globcfg` 섹션에서 버스 폭 설정

**출력 파일:**
- `*_axion_reg.vhd`: VHDL AXI4-Lite 슬레이브 레지스터 모듈 (fully compliant)
- `*_axion_reg.sv`: SystemVerilog 버전
- `*_regs.h`: C 헤더 (오프셋·비트 마스크)
- `*_regs.xml`: IP-XACT 호환 XML 등록 맵
- `register_map.md/html/pdf`: 레지스터 맵 문서

**AXI4-Lite 슬레이브 특성 (readthedocs 열람 기준):**
- `BASE_ADDR` 제네릭/파라미터 지원
- 바이트 스트로브(`wstrb`) 적용으로 부분 레지스터 업데이트 지원
- 접근 모드 RO: `in` 포트 + `_rd_strobe` 단일 사이클 출력
- 접근 모드 WO: `out` 포트 + `_wr_strobe` 단일 사이클 출력
- 접근 모드 RW: 읽기 + 쓰기 스트로브 모두 출력
- CDC 옵션: 토글 동기화기 추가, XDC 타이밍 제약 자동 생성

**optional `use_axion_types`:**
- flat AXI 신호를 axion-common 패키지의 레코드 타입 포트로 대체

## 검증·재현성

- PyPI 페이지(v0.3.1) + readthedocs 출력 문서 전문 열람(2026-11-06, L3): 출력 형식, 레지스터 접근 모드, 스트로브 처리, CDC 옵션 직접 확인
- GitHub(`github.com/bugratufan/axion-hdl`) PROVENANCE_REQUIRED로 미열람: 소스 코드, 예제, CI/테스트 현황 미확인
- 최신 버전 1.7.1이 PyPI에 존재하나 readthedocs에는 v0.3.1 기준 문서

## 한계·위험

- VHDL 1차 타겟; Verilog-2001(iverilog·yosys 등) 직접 출력 없음 (SystemVerilog 출력은 별도 옵션)
- Basys3나 MicroBlaze V 특화 예제 없음
- GitHub 접근 불가로 테스트 현황, Vivado IP 패키징 절차 미확인
- 도구의 지속적 유지보수 여부 불명확 (1인 개발, 최신 커밋 날짜 미확인)

## 재사용 메모

AXI4-Lite 슬레이브 레지스터 파일의 보일러플레이트를 반복 작성하는 대신 이 도구로 VHDL 뼈대를 자동 생성하면 개발 시간을 단축할 수 있음. IP 등록 맵 문서도 함께 생성되므로 카드의 `memory_map` 항목 채우기에 활용 가능.

개조: MicroBlaze V AXI4-Lite IP 래퍼에 활용하려면: (1) VHDL 출력 사용하거나 SystemVerilog 출력을 Verilog-2001과 함께 사용, (2) `BASE_ADDR` 파라미터에 동결 맵(`config/soc_address_map.json`)의 `free_slots` 중 배정된 주소 기입, (3) 생성된 `*_regs.h`를 MicroBlaze V BSP에 포함. 도구가 없는 환경(빠른 프로토타이핑)에서는 ZipCPU easyaxil 패턴(`zipcpu-wb2axip-easyaxil`)을 직접 적용하는 것이 더 빠를 수 있다(내 판단).
