---
name: alexforencich-verilog-axi-crossbar
url: https://github.com/alexforencich/verilog-axi
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(AXI4 버스 IP)
language: Verilog
tools: []
bus: AXI4
peripherals: []
stage: T2
license: MIT
stats: {stars: 1200+, commits: n/a, last_update: "2026 활성"}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev: 25912d48fec2abbf3565bbefe402c1cff99fe470
sources: [https://github.com/alexforencich/verilog-axi/blob/25912d48fec2abbf3565bbefe402c1cff99fe470/rtl/axi_crossbar_addr.v]
---

## 요약

Alex Forencich의 파라메트릭 AXI4 크로스바 IP 모음. 이 카드는 주소 디코딩과 접수 제어를 담당하는 `axi_crossbar_addr.v` 모듈에 집중한다. 범위 기반 주소 디코딩과 elaboration 단계 충돌 검출을 함께 제공한다.

## 구조

**`axi_crossbar_addr.v` 주요 파라미터 (소스 직접 열람):**
- `S` / `S_COUNT` / `M_COUNT`: 슬레이브 포트 인덱스, 슬레이브 수, 마스터 수 (기본 4)
- `ADDR_WIDTH` (기본 32), `ID_WIDTH` (기본 8)
- `S_THREADS` (기본 2): 동시에 추적할 고유 ID 수
- `S_ACCEPT` (기본 16): 최대 동시 진행 트랜잭션 수
- `M_REGIONS` (기본 1): 마스터 인터페이스당 리전 수
- `M_BASE_ADDR`: 마스터별 기본 주소. 0이면 `M_ADDR_WIDTH` 기준으로 자동 순차 계산
- `M_ADDR_WIDTH` (기본 24): 리전별 주소 폭 (2의 거듭제곱 크기)
- `M_CONNECT`: 슬레이브-마스터 연결 비트맵, `M_SECURE`: 보안 플래그

**주소 디코딩 방식:**
- 자동 주소 계산 (`calcBaseAddrs` task): `M_BASE_ADDR`가 0이면 리전을 순차 배치, 2^width 경계로 정렬
- 마스크: `mask = {ADDR_WIDTH{1'b1}} >> (ADDR_WIDTH - width)` (하위 width 비트)
- 범위 비교: `(aaddr >> width) == (base >> width)` — 상위 비트 일치 여부 확인
- 보안 조건: `!M_SECURE[i] || !s_axi_aprot[1]`, 연결 비트맵: `M_CONNECT[S + i*S_COUNT]`
- 복수 일치 시 마지막 일치 항목 선택 (정상 구성에서는 중첩 금지)

**주소 충돌 검출 (elaboration 시점):**
- 리전 주소 미정렬, 리전 간 범위 겹침, 주소 폭 범위 위반 (`< 12` 또는 `> ADDR_WIDTH`) 시 `$error` 후 `$finish`
- 시뮬레이션과 합성 양쪽에서 즉시 중단 → 런타임 이전에 충돌 차단

**접수(admission) 제어:**
- 같은 ID의 트랜잭션은 반드시 같은 목적지(마스터 + 리전)로만 허용. 목적지가 다르면 이전 트랜잭션 완료까지 대기
- 활성 스레드 `S_THREADS` 초과 시 새 ID 거부, `S_ACCEPT` 초과 시 완전 스톨
- `s_cpl_valid`+`s_cpl_id`로 완료 ID를 수신해 카운트 감소

**에러 처리:**
- 주소가 어떤 슬레이브 범위에도 속하지 않으면 `m_decerr` 플래그로 AXI DECERR 응답 반환

## 검증·재현성

- Verilog-2001 스타일, Icarus Verilog/Verilator/Vivado로 시뮬레이션 가능
- MIT 라이선스, `source_rev` SHA에서 직접 소스 열람 완료
- 별도 CI 구성 미확인 (search 결과 기준)
- Basys3 직접 XDC 미포함 — 보드 래퍼 작성 필요

## 한계·위험

- `M_ADDR_WIDTH`가 2의 거듭제곱이어야 하므로 임의 크기 범위 지정 불가 (64KB, 128KB 단위만)
- 복수 일치 시 마지막 항목 선택 → 의도적 중첩이 가능하나 권장하지 않음
- 대규모 크로스바(M×N이 클수록)에서 중재 로직이 임계 경로가 될 수 있음
- Basys3 Pmod 범위(4KB 미만)는 `M_ADDR_WIDTH` 최소 12비트 조건에 걸림

## 재사용 메모

- `axi_crossbar_addr.v`의 범위 비교 패턴(`base >> width` 비교)과 elaboration-time `$error`는 MicroBlaze V 동결 맵 IP 추가 시 주소 충돌을 사전 검출하는 간결한 패턴으로 적용 가능.
- 개조: AXI4 전용 ID 추적 로직(`S_THREADS`, `S_ACCEPT`)은 MicroBlaze V의 AXI4-Lite 슬레이브로 단순화 가능. `M_CONNECT` 비트맵만 유지하면 2M+4S 정도의 소형 크로스바를 Basys3에서 구현 가능. 이식 시 `M_BASE_ADDR`을 동결 맵(`config/soc_address_map.json`)의 `free_slots`에서 직접 채우는 Verilog `parameter` 블록 작성 필요. `M_ADDR_WIDTH` 최소 12 조건(4KB)은 동결 맵의 64KB 슬롯과 호환.
