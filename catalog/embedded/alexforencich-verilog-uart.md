---
name: alexforencich-verilog-uart
url: https://github.com/alexforencich/verilog-uart
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(순수 직렬 IP)
language: Verilog
tools: []
bus: AXI-Stream(내부 바이트 스트림)
peripherals: [UART-TX, UART-RX]
stage: T1
license: MIT
stats: {stars: 1800, commits: 200+, last_update: 2024}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/alexforencich/verilog-uart, https://gittrend.io/repo/alexforencich/verilog-uart]
---

## 요약 (3줄 이내, 내 표현으로)
파라메트릭 UART TX/RX Verilog 모듈로 AXI-Stream 호환 바이트 인터페이스를 제공한다. 보드레이트, 데이터비트, 패리티, 정지비트를 모두 파라미터로 조정 가능하다. 프레이밍 프로토콜(헤더/체크섬)은 포함되지 않은 순수 직렬 레이어다.

## 구조
- 검색 요약 기준: `uart_tx.v`, `uart_rx.v` 두 모듈이 AXI4-Stream(TDATA, TVALID, TREADY) 인터페이스를 사용
- 보드레이트: 클럭 주파수를 파라미터 `DATA_WIDTH`, `PRESCALE`로 설정
- 프레이밍 없음: 단순 바이트 송수신만 처리, 상위 레이어(소프트웨어 또는 별도 IP)에서 헤더·체크섬 담당
- unverified: 실제 AXI-Stream 신호 목록, 오버런 처리 — 직접 열람하지 않음

## 검증·재현성
- 검색 요약 기준: MIT 라이선스로 광범위하게 사용됨, 성숙한 프로젝트
- 테스트벤치 포함 여부, CI 여부 미확인
- Basys3 직접 사례 없음; 파라미터 조정만으로 XC7A35T에 합성 가능하다고 추정(내 판단)

## 한계·위험
- 프레이밍 없음: 패킷 프로토콜을 위해 상위 레이어 구현 필요
- 직접 열람 불가(WebFetch PROVENANCE_REQUIRED)

## 재사용 메모
- UART TX/RX 기반 레이어로 mmio-uart-axilite-bridge에 이미 비슷한 역할이 있음
- AXI-Stream 인터페이스는 MicroBlaze V의 AXI-Stream 주변장치 채널과 직결 가능(내 판단)
- 개조: 프레이밍 IP(헤더·길이·체크섬 FSM)를 별도 AXI4-Lite 슬레이브로 추가하고 이 TX/RX를 하위 레이어로 쓰면 완전한 패킷 IP 구성 가능(내 판단)
