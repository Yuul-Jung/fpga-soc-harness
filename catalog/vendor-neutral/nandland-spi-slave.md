---
name: nandland-spi-slave
url: https://github.com/nandland/spi-slave
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(SPI-only)
language: Verilog
tools: []
bus: none
peripherals: [SPI-slave, comm-spi]
stage: T1
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L2
checked_at: 2026-11-04
sources: [https://github.com/nandland/spi-slave, https://github.com/nandland/spi-slave/blob/master/Verilog/source/SPI_Slave.v]
---

## 요약

nandland(FPGA 튜토리얼 전문 사이트·YouTube 채널)의 SPI 슬레이브 Verilog 구현. `Verilog/source/SPI_Slave.v` 단일 파일로 구성된 교육 목적의 단순 FSM. nandland는 보통 Verilog·VHDL 양언어로 제공한다.

## 구조

- 최상위 소스 파일: `Verilog/source/SPI_Slave.v`
- VHDL 버전: 별도 디렉터리에 존재할 가능성 높음
- 단순 FSM 구조 (튜토리얼 수준)
- unverified: 지원 SPI 모드, 데이터 폭, 클럭, 테스트벤치 포함 여부 — 직접 열람 필요

## 검증·재현성

- nandland 튜토리얼은 일반적으로 ModelSim/GHDL 호환 테스트벤치를 함께 제공한다.
- 보드 무관 Verilog이므로 Basys3용 XDC는 별도 작성 필요 (`needs-port`).
- unverified: 테스트벤치 포함 여부, CI 여부, 자원 사용 — 직접 열람 필요

## 한계·위험

- 튜토리얼 수준이므로 모든 SPI 모드(CPOL/CPHA) 또는 가변 데이터 폭을 지원하지 않을 가능성 있음.
- 라이선스 미확인(`unknown`): 반입 전 LICENSE 파일 확인 필요.
- 보드 무관 → Basys3 XDC 없음(핀 배정 필요).
- unverified: 실제 지원 모드, SCLK 최고 속도, 버퍼 여부 — 직접 열람 필요

## 재사용 메모

단순하고 가독성 높은 SPI 슬레이브 FSM 패턴 참고 자료. 튜토리얼 목적이라 코드가 간결하고 주석이 잘 달려 있어 처음 AXI4-Lite 래퍼를 작성할 때 FSM 구조 참고로 적합하다. Basys3로 이식하려면 XDC 작성과 클럭 제약 추가가 필요하다.

개조: `SPI_Slave.v`의 FSM 로직(상태 이름, 에지 감지, 시프트 레지스터 패턴)을 참고하여 Verilog-2001 AXI4-Lite 슬레이브 래퍼를 직접 작성한다. nandland 코드 자체를 복사하지 않고 사양(포트·타이밍)만 추출한다(§16.3 G2 준수). 외부 MCU(Arduino) SPI 마스터 테스트벤치를 추가해 슬레이브 FSM을 시뮬레이션으로 검증하는 흐름이 [B3] 주제의 핵심 테스트벤치 패턴과 직접 대응된다.
