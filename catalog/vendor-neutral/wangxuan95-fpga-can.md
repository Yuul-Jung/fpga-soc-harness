---
name: wangxuan95-fpga-can
url: https://github.com/WangXuan95/FPGA-CAN
source_type: repo
vendor: neutral
board: [unspecified]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Icarus Verilog]
bus: none
peripherals: [comm-can]
stage: T1
license: GPL-3.0
stats: {stars: 360, forks: 98, commits: 10}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://github.com/WangXuan95/FPGA-CAN]
---

## 요약
CAN 컨트롤러를 순수 Verilog로 작게 구현한 저장소. 송신은 4바이트 데이터 프레임 고정, 수신은 표준(11비트)·확장(29비트) ID를 모두 받는다. 외부에 CAN 트랜시버(TJA1050 등)를 붙여 쓰는 구조.

## 구조
- 모듈: `RTL/can_top.v` → `can_level_packet.v`(프레임·중재) → `can_level_bit.v`(비트 송수신·정렬). 데모 `FPGA/fpga_top.v`, `FPGA/uart_tx.v`, 테스트벤치 `SIM/tb_can_top.v`.
- 최상위 포트(README 기준): `rstn`(능동 낮음), `clk`, `can_rx`, `can_tx`, 송신 `tx_valid/tx_ready/tx_data[31:0]`, 수신 `rx_valid/rx_last/rx_data[7:0]/rx_id[28:0]/rx_ide`. 수신 쪽에는 핸드셰이크가 없다.
- 파라미터: `LOCAL_ID`, 짧은/긴 ID의 필터·마스크, 비트 타이밍 `default_c_PTS/PBS1/PBS2`(분주값 = 합 + 1, 보율 = clk / 분주값). README 표의 50 MHz 예: 1 MHz=50, 500 kHz=100.
- 원격 프레임: 자기 ID와 맞으면 버퍼의 다음 워드를 응답, 비었으면 마지막 값을 다시 보낸다(README).
- 전기: PHY는 5 V 전원이 필요하고 FPGA 핀은 3.3 V, 그라운드는 공통(README). 

## 검증·재현성
- 시뮬레이션: iverilog 배치 스크립트, 테스트벤치는 노드 4개를 ±1% 클럭 차이로 모델링(README). 자원 사용·타이밍: unverified: README에 수치 없음.
- 실제 보드 검증은 USB-CAN 디버거와의 시험만 서술. 보드 이름: unverified: 데모는 50 MHz 발진기만 요구한다고 적음.

## 한계·위험
- 송신 프레임 종류 단일(고정 ID, 4바이트). 수신 역압 없음. 오류 프레임·bus-off 복구·CAN FD 서술 없음(README에 없다는 뜻).
- 라이선스 GPL-3.0 → 코드 복사 금지, 사양만 참고.
- 최신 커밋 SHA: unverified: 페이지에서 확인 못함.

## 재사용 메모
- 내 판단: CAN은 5 V PHY가 필요해 Basys3에서는 TX/RX 두 핀만 3.3 V로 쓰고 PHY 전원은 별도 5 V로 두는 레벨·전원 분리 항목이 필요하다(config 전기 규칙과 일치). 100 MHz에서 비트 타이밍 분주값을 다시 정해야 한다.
- 내 판단: 송신 AXI-Stream 유사 핸드셰이크와 수신 무핸드셰이크 구조는 AXI4-Lite 래퍼에서 수신 FIFO와 상태 레지스터로 감싸야 한다.
- 개조: CPU 비종속 FSM이라 그대로 IP 표준 래퍼 대상이다. ID·필터를 레지스터로, 수신 이벤트를 인터럽트로 옮기고 송신 프레임을 가변 길이로 넓히는 것은 자체 RTL로 새로 쓴다(코드는 가져오지 않음, GPL).
