---
name: zipcpu-wb2axip-easyaxil
url: https://zipcpu.com/blog/2020/03/08/easyaxil.html
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(AXI4-Lite 슬레이브 IP)
language: Verilog
tools: []
bus: AXI4-Lite
peripherals: []
stage: T2
license: unknown
stats: {stars: n/a, commits: n/a, last_update: "2020-03-08 (블로그 게시일)"}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://zipcpu.com/blog/2020/03/08/easyaxil.html, https://zipcpu.com/formal/2018/12/28/axilite.html]
unverified: GitHub `ZipCPU/wb2axip`의 라이선스 및 `rtl/easyaxil.v` 소스 본문(PROVENANCE_REQUIRED로 직접 미열람), 별 수·최신 커밋
---

## 요약 (3줄 이내, 내 표현으로)

ZipCPU(Gisselquist Technology) 블로그에서 제시한 AXI4-Lite 슬레이브 레지스터 파일 설계 패턴. 4개의 32비트 레지스터를 예시로, WSTRB 처리 함수·`$clog2` 기반 주소 디코더·읽기 멀티플렉서 패턴을 명확히 제시한다. 공식 검증 기사에서는 Xilinx 공식 템플릿의 `axi_arready` 버그를 지적하고 올바른 VALID/READY 핸드셰이크를 설명한다.

## 구조

**쓰기 스트로브(WSTRB) 처리 패턴:**
- `apply_wstrb(prior, new_d, wstrb)` 함수: 4바이트 각각에 strobe 비트 적용, 나머지 바이트는 `prior` 값 보존
- 각 레지스터마다 `wskd_rN = apply_wstrb(rN, wskd_data, wskd_strb)` 로 병합값 계산 후 write 시 등록

**주소 디코더 패턴:**
- `ADDRLSB = $clog2(C_AXI_DATA_WIDTH) - 3` (32비트 버스 → 2)
- 하위 `ADDRLSB` 비트를 제거한 뒤 `case` 문으로 레지스터 선택
- 미구현 주소는 `default`에서 무시

**읽기 멀티플렉서:**
- `!S_AXI_RVALID || S_AXI_RREADY` 조건에서 읽기 주소로 레지스터 선택하여 등록
- `OPT_LOWPOWER` 파라미터로 비활성 시 출력 0 처리 옵션 제공

**핸드셰이크 (AXI4-Lite 슬레이브 출력 고정 패턴):**
- 쓰기: AW와 W 채널이 모두 valid일 때만 write 수락, B 채널 stall 시 차단
- 읽기: `axi_arready = (!S_AXI_RVALID || S_AXI_RREADY)` — Xilinx 템플릿 버그 수정 포인트
- 스킵 버퍼 옵션: AW·W·AR 채널에 skid buffer 추가로 처리량 향상 가능

**공식 검증:**
- `faxil_slave.v` 연결 시 AXI4-Lite 프로토콜 준수 증명 가능
- 블로그 별도 기사(`zipcpu.com/formal/2018/12/28/axilite.html`)에서 Xilinx 데모 버그 직접 확인

**GitHub 소스 (L2, 직접 미열람):**
- 저장소: `github.com/ZipCPU/wb2axip`
- 슬레이브 파일: `rtl/easyaxil.v`
- 공식 검증: `bench/formal/faxil_slave.v`, `bench/formal/easyaxil.sby`

## 검증·재현성

- 블로그 포스트 전문 열람(2026-11-06, L3): 설계 패턴, Verilog 코드 스니펫, `apply_wstrb` 함수, 주소 디코더 공식 직접 확인
- 공식 검증 기사(`zipcpu.com/formal/2018/12/28/axilite.html`) 전문 열람(2026-11-06, L3): `axi_arready` 버그 패턴, AXI4-Lite 5채널 프로토콜 규칙, 형식 검증 방법 직접 확인
- 내 판단: Xilinx 공식 템플릿 버그 지적이 구체적이고 SymbiYosys로 검증된 근거가 있어 패턴의 신뢰도가 높다
- iverilog·Vivado에서 직접 합성 여부는 미확인 (GitHub 접근 불가)

## 한계·위험

- 블로그 예시는 4개 레지스터 고정; 실제 IP로 활용하려면 레지스터 수 파라미터화 필요
- 라이선스: 블로그 본문에 명시 없음. GitHub `ZipCPU/wb2axip` 라이선스 직접 확인 필요 (열람 전 추정 금지)
- 스킵 버퍼 없는 버전에서는 AW/W 채널이 같은 사이클에 도착하지 않으면 추가 지연 발생 가능

## 재사용 메모

MicroBlaze V와 연결하는 AXI4-Lite 슬레이브 IP 작성 시 이 패턴의 `apply_wstrb` 함수와 `$clog2` 주소 디코더를 그대로 적용할 수 있음. T2(SoC 접착) 단계에서 커스텀 IP의 "표준 뼈대"로 활용 가능.

개조: MicroBlaze V 기준 AXI4-Lite IP 표준(`config/ip_standard.json`)에 맞추려면: (1) 레지스터 주소를 동결 맵(`config/soc_address_map.json`)의 `free_slots`에서 배정, (2) 최상위 AXI 포트 이름을 IP 표준 명명 규칙으로 변경, (3) `faxil_slave.v` 연결로 형식 검증 추가. WSTRB 처리 함수와 핸드셰이크 로직은 CPU 비종속 부분이므로 그대로 사용 가능.
