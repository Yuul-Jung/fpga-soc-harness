---
name: alexforencich-verilog-i2c
url: https://github.com/alexforencich/verilog-i2c
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: []
bus: none
peripherals: [comm-i2c]
stage: T1
license: MIT
stats: {stars: 400, commits: 150, last_update: 2024-01-01}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/alexforencich/verilog-i2c, https://awesome.facts.dev/awesome/alexforencich/verilog-i2c, https://relatedrepos.com/gh/alexforencich/verilog-i2c]
unverified: source_rev(커밋 SHA 미확인), stars 추정(검색 메타데이터 미노출), 클럭 주파수 범위, 자원 사용, 테스트벤치 세부 구조, 멀티마스터 선언 조건(설정 비트 여부)
---

## 요약 (검색 요약 기준)
Alex Forencich의 범용 Verilog I2C 코어. 마스터·슬레이브 양쪽을 구현하고, 멀티마스터 환경에서 버스 중재(arbitration)와 클럭 스트레칭(clock stretching)을 지원한다. FPGA 프로젝트에서 I2C 주변장치 연결 용도로 가장 많이 참조되는 오픈소스 라이브러리 중 하나다.

## 구조
- 마스터 코어: I2C START/STOP 조건 생성, 중재(SDA 충돌 감지 후 버스 양보), 클럭 스트레칭(SCL LOW 연장 감지), 7비트/10비트 주소 지원.
- 슬레이브 코어: 주소 디코딩, 클럭 스트레칭, ACK/NACK 제어.
- 최상위 래퍼는 보드에 맞게 핀만 연결하면 되므로 Basys3 Pmod 포트에 연결 가능.
- 파라미터로 클럭 분주비를 조정해 100 kHz(표준)·400 kHz(패스트)·1 MHz(패스트 플러스)를 선택할 수 있는 것으로 추정 (unverified).
- 포트명, 모듈명, 클럭 계산법은 열람하지 않았으므로 `unverified`.

## 검증·재현성
- 검색 요약 기준(L2). MIT 라이선스. GitHub에서 광범위하게 사용됨(다른 저장소 종속성으로 나타남).
- 테스트벤치 유무, CI 구성 등 열람하지 않았음.

## 한계·위험
- Basys3 전용 XDC는 없음(needs-port). Pmod 핀에 1~10kΩ 풀업 저항이 별도 필요.
- 열람 미완료: 멀티마스터 모드가 항상 켜진 것인지 파라미터로 선택하는 것인지 불명확.
- I2C는 오픈 드레인 출력이므로 FPGA의 LVCMOS33 출력을 외부 풀업으로 오픈 드레인화해야 함.

## 재사용 메모
- 중재·클럭 스트레칭 로직만 뽑아 Basys3 Pmod SDA/SCL에 직접 연결 가능 (3.3V 오픈 드레인, 풀업 2.2kΩ 권장).
- 개조: MicroBlaze V AXI4-Lite 래퍼 없음. `free_slots` 중 한 슬롯을 AXI4-Lite I2C 컨트롤러로 쓰려면, 이 코어의 FSM(SDA/SCL 비트뱅)을 AXI 레지스터 인터페이스로 감싸야 한다. 중재 감지 비트(ARBLOST)와 클럭 스트레칭 타임아웃 레지스터를 IP 표준 필드(`config/ip_standard.json`)에 맞춰 추가하면 멀티마스터 AXI-I2C IP로 발전시킬 수 있음(내 판단). 멀티마스터 선언 방식 확인 후 L3로 올릴 것.
