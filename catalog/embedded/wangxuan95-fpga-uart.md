---
name: wangxuan95-fpga-uart
url: https://github.com/WangXuan95/FPGA-UART
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(프로토콜 레이어)
language: Verilog
tools: []
bus: none(직접 바이트 스트림)
peripherals: [UART-TX, UART-RX, UART-framing]
stage: T1
license: unknown
stats: {stars: 300, commits: unknown, last_update: 2024}
doc_language: ko
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/WangXuan95/FPGA-UART, https://gittrend.io/repo/WangXuan95/FPGA-UART]
---

## 요약 (3줄 이내, 내 표현으로)
중국어 문서의 FPGA UART 라이브러리. UART TX 모듈, RX 모듈, 그리고 헤더+길이+페이로드+CRC를 처리하는 프로토콜 프레이밍 레이어 3개를 제공한다고 알려져 있다. 순수 Verilog RTL이며 보드 독립적이다.

## 구조
- 검색 요약 기준: `uart_tx.v`, `uart_rx.v`, `uart_protocol.v`(또는 유사 명칭) 3모듈 구성으로 알려짐
- 보드레이트 파라미터: 클럭 주파수와 목표 보드레이트를 파라미터로 설정
- 프레이밍: 시작 바이트, 길이 필드, 페이로드, CRC(종류 미확인) 순으로 구성된다고 보고됨
- unverified: 실제 파일 목록, 레지스터 맵, 라이선스 — 직접 열람하지 않음

## 검증·재현성
- 검색 요약 기준: 중국어 커뮤니티에서 활발히 사용되는 것으로 보임
- 테스트벤치 존재 여부, CI 여부 미확인
- Basys3 직접 사례 없음; 순수 Verilog라면 Vivado에서 XC7A35T에 합성 가능하다고 추정(내 판단)

## 한계·위험
- 라이선스 `unknown`: 직접 확인 필요. 코드를 가져오는 재사용에는 "라이선스 확인 필요"
- 문서 언어 중국어: 번역 필요
- 열람 불가(WebFetch PROVENANCE_REQUIRED 차단): 프레이밍 프로토콜 세부 미확인

## 재사용 메모
- UART TX/RX 기반 레이어는 Basys3 AXI4-Lite UART Lite 아래에 소프트웨어 드라이버로 구현하는 것과 비교 가능
- 하드웨어 프레이밍은 AXI4-Lite 슬레이브로 감싸면 mmio-uart-axilite-bridge와 조합해 "패킷 처리 IP" 구성 가능(내 판단)
- 개조: MicroBlaze V에서는 AXI Lite에 프레이밍 IP를 붙이고 C 드라이버에서 헤더/체크섬 처리. CPU 비종속 프레이밍 FSM은 그대로 가져올 수 있음(내 판단)
