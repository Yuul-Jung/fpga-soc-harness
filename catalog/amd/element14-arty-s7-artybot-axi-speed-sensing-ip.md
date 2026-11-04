---
name: element14-arty-s7-artybot-axi-speed-sensing-ip
url: https://community.element14.com/technologies/fpga-group/b/blog/posts/arty-s7-50-artybot-custom-axi4-lite-ip-peripheral-for-sensing-motor-rotational-speed
source_type: article
vendor: amd
board: [Arty S7-50]
fit_basys3: needs-port
cpu: MicroBlaze
language: Verilog
tools: [Vivado ML 2021.1]
bus: AXI4-Lite
peripherals: [sensor, encoder-counter, 2ch-motor-speed]
stage: T3
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://community.element14.com/technologies/fpga-group/b/blog/posts/arty-s7-50-artybot-custom-axi4-lite-ip-peripheral-for-sensing-motor-rotational-speed]
unverified: 저장소 없음(소스 원문 미확인), 보드 클럭 값, 자원 사용, 게시일, 라이선스
---

## 요약
Arty S7-50 위 MicroBlaze에서 모터 2개의 회전 속도를 재는 AXI4-Lite 사용자 IP를 만든 element14 글. 엔코더 에지 수를 세고 소프트웨어가 비우는 클럭 카운터와 함께 읽어 속도를 계산한다.

## 구조
- 버스: AXI4-Lite 슬레이브, 데이터 32비트, 주소 5비트 (글 서술).
- 엔코더: Pololu Romi 12 CPR 홀 센서, 모터당 출력 1개의 상승 에지만 셈 — 직교 4체배가 아니라 단상 에지 계수다 (글 서술).
- 레지스터(글 서술): 0x00 CLEAR(비트0 속도 카운터, 비트1 위치 카운터 지움), 0x04 M1 POSITION(상위 16 속도 카운터, 하위 16 제어 카운터), 0x08 M2 POSITION(같은 배치), 0x0C 위치 차이(하위 16비트, M1−M2), 0x10 CLOCK COUNTER(32비트). 0x04~0x10은 사실상 읽기 전용(쓰기 케이스 주석 처리).
- 입력 처리: 홀 입력마다 2단 레지스터 후 에지 검출. 디바운스 없음.
- 속도 계산: 글 수식은 주기 방식(Speed = 360*60/Period)이나 드라이버는 에지 수 ÷ 클럭 수(소프트웨어가 비우는 창)를 클럭 주파수·한 바퀴 에지 수·감속비로 환산. 즉 실제 구현은 창 계수 방식 (글 서술 간 불일치).

## 검증·재현성
- 테스트벤치는 10 ns 주기 클럭을 쓴다고만 기술. 자원 수치와 보드 동작 영상 근거는 글에 없음.
- 프로젝트 저장소 링크 없음. Digilent vivado-library 기반이라는 언급만 있음.

## 한계·위험
- 한 채널당 센서 출력 하나라 방향을 알 수 없고 위치는 증가만 한다 (내 판단: 홀 1상 방식의 구조적 한계).
- 소스·라이선스 없음 → 코드 가져오기 불가. 사양만 참고.
- 레지스터 이름과 필드 배치가 글 안에서도 속도 카운터와 "위치"를 섞어 써서 혼동 소지가 있다 (내 판단).

## 재사용 메모
- 내 판단: "에지 수 + 자유 구동 클럭 카운터를 같은 시점에 읽어 소프트웨어가 나눈다"는 구조는 MicroBlaze V에서 나눗셈 부담 없이 속도를 얻는 가장 작은 사양이다. 원자적 스냅샷 레지스터가 없으면 읽는 사이에 값이 어긋날 수 있어 보완이 필요하다.
- 개조: 레지스터 배치 아이디어(CLEAR, 카운터, 클럭 카운터)만 취해 IP 표준 래퍼로 새로 쓰고, 직교 4체배 + 방향 + 스냅샷 래치를 더해 `free_slots`에 한 칸 제안한다. MicroBlaze 계열이라 CPU 변경은 필요 없고 Arty S7 핀·클럭은 Basys3 XDC로 바꾼다. Pololu 홀 센서는 3.3V 동작 여부를 부품 자료로 확인해야 한다(미확인).
