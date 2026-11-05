---
name: xtrinch-icestick-fpga-uart
url: https://github.com/xtrinch/icestick-fpga-uart
source_type: repo
vendor: lattice
board: [iCEstick]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog, C
tools: [icestorm, arachne-pnr]
bus: none
peripherals: [comm-uart]
stage: T2
license: MIT
stats: {stars: 4, commits: 25, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-05
sources: [https://github.com/xtrinch/icestick-fpga-uart]
---

## 요약
Lattice iCEstick(iCE40HX1K)에서 단순 패킷 프레이밍을 구현한 예제. 첫 바이트를 길이, 네 번째 바이트를 메시지 타입으로 쓰고, 나머지를 페이로드로 처리한다. PING/PONG 메시지 교환과 LED 토글 예제를 포함한다.

## 구조
- Verilog 파일: `uart_rx.v`, `uart_tx.v`(외부 osdvu 모듈), 최상위 `top.v`.
- 패킷 형식: `[0] length` | `[1..3] padding/type area` | `[4] message_type` | `[5..N] payload`. 타입 0x01=PING, 0x02=PONG(내 열람 기준; unverified: 다른 타입 존재 가능).
- C 쪽: 호스트에서 같은 패킷 형식으로 직렬 포트를 통해 메시지를 주고받는 예제 소프트웨어 포함.
- 외부 의존: `osdvu`(Open-Source Double-Rate UART, cyrozap 작성). 별도 클론 필요.
- 빌드: Icestorm 오픈소스 도구(yosys·arachne-pnr·icepack). Makefile 제공.

## 검증·재현성
- 보드 테스트: 작성자가 iCEstick에서 직접 동작을 확인한 프로젝트임(README 및 소스 구조 기준; unverified: 공개 CI 없음).
- 테스트벤치: unverified — 별도 테스트벤치 파일을 열람 범위에서 확인하지 못함.
- 보레이트: unverified — `uart_rx.v`/`uart_tx.v` 소스에서 보레이트 설정 파라미터를 직접 확인하지 못함. 12 MHz 클럭 기준이면 115200 bps 가능.

## 한계·위험
- 패킷 형식이 비표준이고 문서화가 간략함. 길이 필드의 최댓값, 오버플로 처리 등의 엣지케이스 미명시.
- osdvu 의존 — `git submodule`이나 수동 복사가 필요하고, 해당 모듈 라이선스도 함께 확인해야 함.
- Basys3(Artix-7, Vivado)와 도구가 완전히 다름. xdc 핀맵과 클럭 설정을 새로 작성해야 함.
- 타입 필드가 바이트 1~3을 건너뛰고 바이트 4에 있는 이유를 문서에서 확인하지 못함. 내 판단: 단순 데모 프로토콜이며 양측이 같은 소스를 쓸 때만 호환됨.

## 재사용 메모
- 내 판단: 패킷 경계를 "길이 접두어"로 표현하는 가장 단순한 형태의 프레임 방식 예제. HDLC처럼 비트 스터핑이 없어 구현이 쉽지만, 오류 복구 능력이 없다. T2 초입 학습용에 적합.
- 개조: 프레이밍 프로토콜 자체(첫 바이트=길이, 타입 바이트)는 Basys3로 그대로 가져올 수 있음. osdvu 대신 우리 UART IP(또는 Xilinx UART Lite)를 쓰고, 최상위 모듈을 Basys3 XDC에 맞게 수정하면 됨. MicroBlaze V에 연결하려면 AXI4-Lite 슬레이브로 감싸야 함 — 송신 버퍼·수신 버퍼·상태 레지스터 3종이면 충분. 옮길 수 없는 부분: Lattice Icestorm 도구 의존(yosys/Vivado로 대체 가능), osdvu UART 코어(FPGA 목표가 다르므로 동일 코드 사용 불가).
