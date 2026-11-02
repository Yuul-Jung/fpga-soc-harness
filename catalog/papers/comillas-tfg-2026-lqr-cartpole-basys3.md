---
name: comillas-tfg-2026-lqr-cartpole-basys3
url: https://repositorio.comillas.edu/items/72b2e00f-4d1e-4918-bdc3-489968edd616
source_type: paper
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(FSM)
language: VHDL
tools: [Vivado, MATLAB/Simulink]
bus: none
peripherals: [sensor, actuator-servo, accelerator]
stage: T4
license: CC BY-NC-ND 3.0 US (논문 페이지 표기, 코드 공개 여부 unverified)
stats: {published: 2026}
doc_language: en
verification: L2
checked_at: 2026-11-03
status: 본문은 스페인어(초록은 영문 병기). 저장소 페이지(초록·서지)만 열람. 본문 PDF는 robots 차단으로 못 읽음(우회 안 함)
sources: [https://repositorio.comillas.edu/items/72b2e00f-4d1e-4918-bdc3-489968edd616, https://repositorio.comillas.edu/items/72b2e00f-4d1e-4918-bdc3-489968edd616/full]
unverified: 본문 열람 불가 - 고정소수점 비트폭, 상태 벡터·이득 수, 센서와 구동기 종류, PWM 주파수, 자원(LUT/DSP/BRAM), 클럭, 테스트벤치 유무, 코드 공개
---

## 요약
Comillas(ICAI) 학사 졸업 논문(TFG, 2026). Basys3(Artix-7)에서 LQR을 VHDL 고정소수점으로 구현해 실험실에서 만든 카트-폴 도립진자를 제어하고, 같은 제어기의 마이크로컨트롤러 구현과 성능·자원을 비교했다(초록 기준).

## 구조
- 검증 순서: MATLAB/Simulink 모델 → Vivado 기능 시뮬레이션 → 실제 플랜트 시험(초록 서술).
- 보고된 수치(초록): 루프 지연 360 ns, 샘플링 주기 1 ms. 지연은 주기의 약 0.036%(원문 비율).
- 제어 구조: 단일 FPGA에 상태 되먹임(LQR) 한 개. 센서·구동기 구성은 unverified.

## 검증·재현성
- 물리 플랜트에서 검증했다고 초록이 서술. 정량 응답 결과, 자원 수치는 unverified(본문 미열람).

## 한계·위험
- 본문을 못 읽었으므로 이 카드의 구조 정보는 초록 수준이다. CC BY-NC-ND라 내용 변형·재배포 제한 가능, 코드 반입 불가로 취급.
- 저자 개인정보는 기록하지 않음.

## 재사용 메모
- 내 판단: Basys3에서 1 ms 주기 LQR이 가능하다는 직접 근거로는 이 사례가 지금까지 카탈로그에서 유일하다. 곱셈-누산 몇 개로 끝나는 상태 되먹임은 BRAM이 필요 없는 제약 역전 사례(S4)와도 맞는다.
- 개조: 이 설계는 CPU가 없는 순수 FSM이라 CPU 종속 부분이 없다. 제어기를 IP 표준 AXI4-Lite 래퍼(이득 K 레지스터, 상태 입력 레지스터, 출력 레지스터, 주기 트리거)로 만들고 MicroBlaze V가 이득 쓰기·모니터링을 맡는 구성으로 옮길 수 있다(내 판단). 본문 확인 후 L3로 올려 수치를 보강해야 한다.
