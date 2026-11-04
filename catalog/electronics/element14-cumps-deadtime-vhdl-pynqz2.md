---
name: element14-cumps-deadtime-vhdl-pynqz2
url: https://community.element14.com/technologies/fpga-group/b/blog/posts/vhdl-pwm-generator-with-dead-time-the-design
source_type: article
vendor: amd
board: [Pynq-Z2]
fit_basys3: needs-port
cpu: none(전자회로·PWM RTL)
language: VHDL
tools: []
bus: none
peripherals: [deadtime-pwm, complementary-pwm, gate-driver]
stage: T2
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.element14.com/technologies/fpga-group/b/blog/posts/vhdl-pwm-generator-with-dead-time-the-design]
---

## 요약

Jan Cumps(element14 커뮤니티)가 작성한 Pynq-Z2(Zynq-7020) 대상 VHDL PWM 발생기. 풀브리지/하프브리지 용 보완 출력(pwmA_o / pwmB_o)에 4비트 데드타임(0–15 클럭 틱) 삽입을 RTL로 구현한다. 초판의 비동기 리셋 버그를 발견·수정한 사례도 함께 다룬다.

## 구조

- 출력 쌍: `pwmA_o`, `pwmB_o` — 보완 신호(complementary), 동시에 High가 되지 않도록 데드타임 삽입
- 데드타임 파라미터: 4비트, 0–15 클럭 틱 범위. 클럭 주파수에 따라 나노초 단위로 환산
- 슛스루 경고: 두 스위치가 동시에 도통되면 버스와 GND 단락 → 소자 파손 명시
- 초판 버그: 비동기 리셋이 출력 에지와 충돌 가능 → 개정판에서 동기 리셋으로 수정
- 보드: Pynq-Z2(Zynq-7020), 클럭은 Pynq 플랫폼 클럭 사용

## 검증·재현성

- 블로그 포스트 본문 직접 열람(L3). 웨이브폼 캡처와 RTL 코드 발췌 포함
- Pynq-Z2에서 하드웨어 동작 확인(작성자 보고)
- 비동기 리셋 버그: 시뮬레이션에서 엣지 조건 발견, 수정 후 재검증

## 한계·위험

- 데드타임 최소값(클럭 1틱)이 실제 MOSFET/IGBT 요구보다 짧을 수 있음 — 내 판단: 100MHz 클럭 기준 1틱=10ns이므로 IGBT용 500ns는 50틱 이상 설정 필요
- Pynq-Z2 전용 프로젝트라 Basys3 직접 사용 불가; XDC·클럭 교체 필요
- 라이선스 미명시 — 코드 복사 전 확인 필요

## 재사용 메모

Basys3 Artix-7에 옮길 때: 클럭 100MHz 기준 데드타임 비트 폭을 늘리고(4비트로는 최대 150ns, 500ns 보장하려면 6비트 이상), XDC 핀을 Pmod 출력으로 바꾼다. 비동기 리셋 버그 패턴은 Basys3 RTL에서도 주의해야 한다.
개조: 이 모듈의 보완 PWM 생성 FSM은 MicroBlaze V SoC의 AXI4-Lite 슬레이브 IP로 감쌀 수 있다. 레지스터: PWM_PERIOD, DEAD_TIME_TICKS, ENABLE. 동결 맵 free_slots 중 1개 64KB 블록 배정 제안. 슛스루 경고 로직(두 출력 AND 체크)을 별도 assertion으로 tb에 추가하면 CI에서 검출 가능.
