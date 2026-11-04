---
name: vishay-fpga-power-supply-consideration
url: https://www.vishay.com/docs/62830/fpgapowersupplyconsideration.pdf
source_type: paper
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none
language: none
tools: []
bus: none
peripherals: []
stage: T0
license: unknown
stats: {stars: 0, commits: 0, last_update: 2013-03-05}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://www.vishay.com/docs/62830/fpgapowersupplyconsideration.pdf]
---

## 요약

Vishay Siliconix 애플리케이션 노트(Owain Bryant, 2013-03). FPGA(Cyclone IV EP4CGX75 예제)에 필요한 복수 전압 레일(코어·I/O·보조)을 12V 버스에서 공급하는 설계 절차 전체를 다룬다. 레귤레이터 선택, 전원 순서, 디커플링, 레이아웃, 시뮬레이션 효율까지 커버한다.

## 구조

**레귤레이터 선택**
- 고전류 코어 레일과 I/O 레일: 동기 벅(synchronous buck). 비동기 벅보다 효율 높음(저전압 쪽 MOSFET의 도통 손실 < 다이오드 순방향 전압 손실).
- 저전류 보조 레일: LDO 적합. 단, Vin/Vout 비 작을 때만(dropout 최소화).
- Vishay microBUCK 시리즈: constant-on-time 제어 → 빠른 과도응답, 소형 외부 부품.

**전원 순서(Power Sequencing)**
- Cyclone IV 예: 코어 → I/O → 보조 순.
- 구현 방법: 인에이블 핀 체이닝, 외부 RC 지연, MCU 감시.
- 최신 FPGA는 순서 미요구 경우도 있으나 안전 측은 코어 선행.

**디커플링과 레이아웃**
- FPGA 근처에 저ESR·저ESL 커패시터를 최대한 가깝게 배치.
- 비아와 트레이스의 인덕턴스가 불필요한 공진 회로를 만들 수 있으므로 주의.
- POL(Point-of-Load) 레귤레이터는 FPGA 근처에 배치, I/O 라우팅 방해 최소화.

**Cyclone IV 설계 예 (12V 입력)**
| 레일 | 전압 | 전류(10% 여유 포함) | 레귤레이터 |
|---|---|---|---|
| 코어 | 1.2V | 6.6A | SiC402A |
| 보조 | 2.5V | 0.66A | SiP12108 (3.3V 입력) |
| I/O | 3.3V | 4.95A | SiC403A |

**PowerCAD 시뮬레이션 효율**
| 레귤레이터 | 변환 | 부하 | 효율 |
|---|---|---|---|
| SiC402A | 12V → 1.2V | 6A | 88% |
| SiC403A | 12V → 3.3V | 5.1A | 94% |
| SiP12108 | 3.3V → 2.5V | 0.6A | 96% |
- 시뮬레이션과 실제 오차: 1~2% 이내.

## 검증·재현성

- 공식 애플리케이션 노트(PDF, L3 직접 열람).
- PowerCAD 시뮬레이션 기반 효율 수치 포함 — 실제 Vivado 타이밍과 무관.
- 2013년 작성이나 전원 설계 원칙은 여전히 유효.

## 한계·위험

- Intel/Altera Cyclone IV 예제이므로 Basys3(Artix-7) 레일 요건과 다름.
- 2013년 Vishay 전용 IC 추천 — 현재 대체 IC 필요 시 별도 조사.
- Basys3는 USB 5V 단일 입력(보드 내부에서 1.0V/1.8V/3.3V 생성 완료)이므로 본 노트의 외부 버스 설계는 확장 보드 대상.

## 재사용 메모

Basys3에 외부 모터 드라이버 보드, 카메라 모듈, 고전류 센서 허브를 연결할 때 별도 전원 보드(5V 또는 12V 버스 → 다중 레일)를 설계하는 경우 직접 참조 가능. 전원 순서 패턴(코어 선행)은 Artix-7(Basys3)에도 적용 원칙은 같다.
개조: Basys3 외부 확장 보드에서 12V 모터 전원을 5V(로직)와 3.3V(센서)로 분리할 때, SiC403A 계열 동기 벅(Artix 호환 등가 IC)으로 3.3V 레일 구성, 2.5V 보조 레일은 LDO로 처리하는 패턴을 적용할 수 있다.
