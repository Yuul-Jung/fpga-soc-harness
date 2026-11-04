---
name: csselectronics-can-fd-frame-guide
url: https://www.csselectronics.com/pages/can-fd-flexible-data-rate-intro
source_type: article
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(프로토콜 기사)
language: []
tools: []
bus: CAN FD
peripherals: [comm-can]
stage: T2
license: 미확인(기사 저작권, 코드 없음)
stats: {stars: null, commits: null, last_update: 2026}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.csselectronics.com/pages/can-fd-flexible-data-rate-intro]
---

## 요약

CAN FD(Flexible Data-rate) 프레임 구조와 CAN 2.0과의 차이를 설명하는 CSS Electronics 기술 기사. 프레임 필드별 역할, DLC 테이블, 중재 단계·데이터 단계 비트율 전환 메커니즘을 직접 열람해 정리했다.

## 구조

### CAN FD 데이터 프레임 주요 필드

- **FDF(FD Format)**: CAN 2.0의 예약 비트 r0 위치에 열성(recessive) → CAN 2.0 노드는 에러 프레임 발생. CAN FD 프레임의 필수 식별자.
- **BRS(Bit Rate Switch)**: 열성이면 데이터 단계 고속 전환. 우성이면 단일 속도 전송.
- **ESI(Error State Indicator)**: 우성 = error-active, 열성 = error-passive 상태 표시.
- **RRS**: RTR 위치에 오며 항상 우성(0). CAN FD에서 원격 프레임 없음.
- **SBC**: CRC 앞 3비트 그레이 코드 Stuff Bit Count + 1비트 패리티 + 1 고정 스터프 비트.
- **CRC**: 페이로드 ≤16 B이면 17비트, 20~64 B이면 21비트. 고정 스터프 4비트 포함.
- **ACK**: 데이터 단계 종료점(고속 구간 끝).
- **DLC**(4비트): 0~8은 CAN 2.0과 동일, 9→12 B, 10→16 B, 11→20 B, 12→24 B, 13→32 B, 14→48 B, 15→64 B.

### CAN 2.0과 비교

| 항목 | CAN 2.0 | CAN FD |
|---|---|---|
| 최대 페이로드 | 8 B | 64 B |
| 명목 비트율 | 최대 1 Mbit/s | 최대 1 Mbit/s |
| 데이터 비트율 | 없음 | 실용 최대 5 Mbit/s |
| CRC | 15비트 | 17 또는 21비트 |
| 원격 프레임 | 있음 | 없음 |

### 비트율 전환 타이밍

- **중재 단계**: 명목 속도(≤1 Mbit/s). 모든 노드가 버스 경쟁.
- **데이터 단계**: 승자 노드만 전송, BRS부터 ACK까지 고속 전환. 실용 ≈5 Mbit/s, ECU 플래싱 목적 최대 12 Mbit/s.
- **다중 드롭 버스**: -40~+125 °C 조건에서 실용 최대 약 2 Mbit/s.

## 검증·재현성

원문 직접 열람(L3). 코드·시뮬레이션 없음(참조 기사). CRC 길이·DLC 테이블 수치는 원문 그대로다.

## 한계·위험

- 에러 프레임 구조는 본문에서 "FDF 비트 이후 비-CAN FD 노드가 에러 프레임 발생"만 언급하고 상세 구조는 없음.
- 비트 타이밍 값(샘플 포인트, prescaler)은 다루지 않음.
- 데이터 단계 종료 경계(BRS~CRC delimiter vs BRS~ACK)에 대해 본문 내 설명이 상충하는 부분 있음(원문 그대로 기록).
- 라이선스: 기사 저작권(CSS Electronics). 내용은 요약·인용 한도 내 정리; 코드 없음.

## 재사용 메모

- CAN FD 컨트롤러를 Basys3 Verilog RTL로 구현할 때 프레임 파서/필터 설계 기준으로 쓸 수 있음.
  - 비교: 기존 `wangxuan95-fpga-can`(CAN 2.0, Verilog), `dpiegdon-verilog-can`(CAN 2.0, Verilog) 카드 → FDF 비트·BRS·ESI 처리 로직이 추가됨.
  - 실용 데이터 비트율(5 Mbit/s)은 Basys3 100 MHz 클럭으로 오버샘플링 가능(최소 20 샘플/비트).
- 개조: MicroBlaze V SoC에 CAN FD 수신 IP를 붙이려면 ① FDF/BRS/ESI 비트 감지 FSM ② DLC→페이로드 길이 디코더 ③ 17/21비트 CRC 검사 모듈이 필요. `free_slots`에서 64 KB 슬롯 1개 배정 후 AXI4-Lite 래퍼로 연결. 기존 CAN 2.0 RTL은 FDF 미인식으로 그대로 쓸 수 없고 FSM 분기 추가 필요(내 판단).
