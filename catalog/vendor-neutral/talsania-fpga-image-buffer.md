---
name: talsania-fpga-image-buffer
url: https://github.com/talsania/fpga-image-buffer
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(UART 로더 + VGA 출력 전용 RTL)
language: Verilog
tools: []
bus: none(UART 입력, VGA 출력)
peripherals: [video-vga, comm-uart]
stage: T2
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/talsania/fpga-image-buffer]
---

## 요약 (검색 요약 기준)

FPGA 이미지 버퍼: 듀얼포트 BRAM을 프레임버퍼로 쓰고 UART로 이미지를 로드한 뒤 VGA로 출력하는 Verilog 설계. UART 로더(이미지 수신 FSM)가 BRAM 쓰기 포트에 접근하고, VGA 컨트롤러가 읽기 포트에서 픽셀을 스캔하는 구조로 추정.

## 구조
- 핵심 구조: 듀얼포트 BRAM, UART → BRAM 로더, BRAM → VGA 스캔 출력
- 더블 버퍼(핑퐁) 여부: `unverified: 단일 버퍼 가능성 높음(제목에 'buffer' 단수)`
- 대상 보드·FPGA: `unverified: 본문 미열람`
- 해상도·색 깊이: `unverified`
- UART 프로토콜(보레이트, 패킷 형식): `unverified`

## 검증·재현성
- 검색 요약 외 열람 없음
- 테스트벤치·CI 여부: `unverified`
- 자원 사용(LUT/FF/BRAM): `unverified`

## 한계·위험
- L2(검색 요약 기준). 보드명·FPGA 파트 미확인
- 단일 BRAM 구조라면 로딩 중 화면 깜박임 발생 가능
- UART 로딩 속도 제한(115200 bps ≈ 11.5 KB/s → 160×120×1 byte 로드에 약 1.7초 소요 추정)

## 재사용 메모
- S4 제약 역전 사례: Basys3에 SD 카드·DDR 없이 UART 로더로 이미지를 BRAM에 적재하는 접근은 no-dram 제약을 우회하는 현실적 패턴.
- 개조: UART 로더 FSM을 그대로 쓰거나, AXI4-Lite 슬레이브 래퍼로 교체해 MicroBlaze V가 직접 BRAM에 픽셀 데이터를 쓰도록 변경. 이미지 로더 역할을 MicroBlaze V 소프트웨어(UART 수신 → memcpy → 프레임버퍼)로 올리면 RTL 단순화. 더블 버퍼가 없으므로 쓰기·읽기를 동시에 허용하는 대신 VSync 기간에만 버퍼를 갱신하거나, BRAM 2개 핑퐁 구조로 확장해 테어링 제거 가능. Basys3 225 KB BRAM 예산에서 160×120 × 1 byte × 2 = ~38 KB 소요—적합.
