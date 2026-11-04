---
name: polito-upm-2023-cartpole-fpga-lqr-pid-rl
url: https://webthesis.biblio.polito.it/27644/1/tesi.pdf
source_type: paper
vendor: amd
board: [PYNQ-Z1 (Zynq XC7Z020)]
fit_basys3: needs-port
cpu: ARM Cortex-A9 (PS) + PL IP
language: VHDL, C, Python
tools: [Vivado, Vitis, MATLAB/Simulink, OpenAI Gym, Stable-Baselines3]
bus: AXI (Zynq PS-PL, 세부 unverified)
peripherals: [sensor, actuator-servo, debug]
stage: T4
license: unknown
stats: {published: 2023}
doc_language: en
verification: L3
checked_at: 2026-11-03
status: 본문 약 111k자 중 앞 100k자 이상 열람, 8장(물리 시험)·자원·고정소수점 절은 잘려 못 읽음
sources: [https://webthesis.biblio.polito.it/27644/1/tesi.pdf]
unverified: 물리 시스템 결과(8장), 자원 사용, 고정소수점 형식, 라이선스
---

## 요약
토리노 공대/마드리드 공대 석사 논문(2023). 벨트 구동 카트-폴(스텝모터)을 Zynq 기반 PYNQ-Z1로 제어한다. LQR(적분 증강), 2중 루프 PID(Ziegler-Nichols), PPO 강화학습(시뮬레이션만)을 비교한다.

## 구조
- 플랜트(원문 수치): 카트 0.455 kg, 진자 0.044 kg, 길이 0.353 m, 트랙 0.96 m. 스텝모터 57BYGH420-2를 DRV8825로 1/32 마이크로스텝 구동.
- 센서: 600펄스/회전 2채널 직교 엔코더, 광 인터럽터(진자 아래 기준), 리밋 스위치 4개.
- PL 쪽 IP: 엔코더·리밋 스위치 디바운스 필터(엔코더 250 µs, 리밋 1 ms), 스텝 신호를 하드웨어에서 생성(타이머 방식은 루프 지연 때문에 회피). 가속도는 100 µs마다 갱신, 제어 주기 25 ms(본문의 "40 KHz"는 25 ms와 모순이라 40 Hz로 보임 - 내 판단).
- 리밋 스위치가 끊기면 모터를 비활성(보안 모드)으로 두는 안전 설계.

## 검증·재현성
- IP별 시뮬레이션 결과는 본문에 있음. 물리 시험 결과는 열람 범위에 없음.

## 한계·위험
- 본문 서술 한계: 저속에서 엔코더 바운스가 직립 근처 위치 추정을 해침, 마찰 무시, 실제 LQR에서 카트 위치 오프셋(적분 증강으로 대응), 고속에서 스텝모터 토크 저하로 가속도 한계.
- 라이선스 미기재, 코드 공개 여부 unverified.

## 재사용 메모
- 내 판단: 스텝모터 STEP 펄스를 PL에서 만들고 PS는 25 ms 주기로 가속도만 지시하는 분업은 프로젝트의 IP + C 분담과 같다. 앞서 카드화한 스텝모터 가감속 자료(I-018)와 이어지는 도립진자 응용이다.
- 개조: Zynq PS의 Cortex-A9는 MicroBlaze V로 대체. 엔코더 디바운스·STEP 생성·리밋 스위치 안전 차단은 IP 표준 AXI4-Lite 래퍼로 옮길 수 있다. 못 옮기는 부분은 Zynq PS 의존(PYNQ 오버레이, Python) 및 강화학습 실행부. Basys3는 Pmod 핀으로 엔코더 2 + 리밋 4 + STEP/DIR/EN을 수용 가능하다고 추정(내 추정).
