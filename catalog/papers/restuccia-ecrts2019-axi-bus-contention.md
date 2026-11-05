---
name: restuccia-ecrts2019-axi-bus-contention
url: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ECRTS.2019.24
source_type: paper
vendor: amd
board: [Zynq-7020, ZCU102]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado 2018.2]
bus: AXI4
peripherals: [performance-monitor]
stage: T4
license: CC-BY-3.0
stats: {stars: 0, commits: 0, last_update: 2019-07-01}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://core.ac.uk/download/343692393.pdf, https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ECRTS.2019.24]
---

## 요약

ECRTS 2019 논문. FPGA SoC에서 하드웨어 가속기가 AXI 인터커넥트를 공유할 때 발생하는 버스 경합(contention) 모델과 최악 레이턴시 분석법을 제안한다. Zynq-7020과 ZCU102에서 사이클 정밀도 트래픽 발생기와 타이머 IP로 실측값을 측정하고 분석 한계값과 대조.

## 구조

- **측정 대상**: AXI SmartConnect를 통한 복수 하드웨어 태스크의 메모리 접근 경합
- **실측 수치 (AXI SmartConnect, 100 MHz FPGA 패브릭)**:
  - 주소 채널 지연: 12 클럭
  - 데이터 채널 지연: 11 클럭
  - 쓰기 응답 지연: 9 클럭
  - Hold 시간: 각 1 클럭
  - PS 메모리 읽기 지연: 50 클럭 (실험 추정)
  - PS 메모리 쓰기 지연: 40 클럭 (실험 추정)
- **최악 레이턴시 실측 (단일 계층)**:
  - 읽기: 약 190 클럭 / 쓰기: 약 160 클럭
  - 분석 한계값: 364 / 316 클럭
- **최악 레이턴시 실측 (계층적 SmartConnect)**:
  - 읽기: 약 350 클럭 / 쓰기: 약 280 클럭
  - 분석 한계값: 866 / 756 클럭
- **중재 방식**: AXI SmartConnect는 라운드로빈 (고정 우선순위·QoS는 SmartConnect에서 지원 중단)
- **측정 방법**: 프로그래밍 가능 트래픽 발생기 IP(오프셋, 간격, 버스트 크기, 미결 한도 설정 가능) + 멀티채널 타이머 IP; 모든 발생기를 AXI GPIO 신호로 동시 릴리스; ILA 프로브로 중재 순서 확인
- **이론 모델**: 라운드로빈 중재 기반 응답 시간 분석, 태스크 주기 경계와 조합

## 검증·재현성

- Zynq-7020 및 ZCU102, Vivado 2018.2 (L3 직접 열람)
- ECRTS 2019 아티팩트(DOI 별도)에 트래픽 발생기·타이머 Verilog 소스 공개 (본 논문 PDF에서 코드 미제공)
- CC BY 3.0 라이선스 (Dagstuhl LIPIcs 출판 기준)

## 한계·위험

- 타깃: Zynq HPS/PS 연결 HP 포트 → 순수 PL(FPGA 패브릭) 간 AXI 경합과는 다름
- PS 메모리 지연(50/40 클럭)은 순수 BRAM 슬레이브와 다르므로 Basys3 수치로 직접 대입 불가
- SmartConnect 계층 IP 개수 최대 16포트 제한
- 파이프라이닝 정밀 모델과 할당 전략은 미래 연구 과제로 남겨둠

## 재사용 메모

Basys3에는 PS가 없으나, AXI SmartConnect 주소·데이터·응답 지연(12/11/9 클럭)은 MBv SoC의 Vivado AXI SmartConnect에서도 동일하게 적용된다. 이 수치를 기준으로 여러 AXI-Lite 슬레이브 접근 시 최악 레이턴시를 사전 추정할 수 있다.

개조: 논문의 트래픽 발생기 아이디어(AXI GPIO로 동시 릴리스 → 타이머로 응답 시간 측정)를 Basys3에서 재현 가능. MicroBlaze V 위에서 2~4개 AXI-Lite 슬레이브를 동시에 접근하는 firmware loop를 작성하고, AXI Timer IP로 시작·종료 타임스탬프를 측정하면 버스 경합 레이턴시 실측 패키지가 된다 (캡스톤 아이디어). 옮길 수 없는 것: Zynq HP 포트·DDR4 메모리 접근 레이턴시 (BRAM 슬레이브로 대체 측정), HPS/PS 클럭 1.2 GHz 환경 (FPGA 패브릭 100 MHz만 사용).
