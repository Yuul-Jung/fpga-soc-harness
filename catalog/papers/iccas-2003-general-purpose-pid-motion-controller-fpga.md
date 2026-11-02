---
name: iccas-2003-general-purpose-pid-motion-controller-fpga
url: https://koreascience.kr/article/CFKO200333239336497.pdf
source_type: paper
vendor: intel
board: [Altera APEX II EP20K300EQC240 (보드명 미명시)]
fit_basys3: needs-port
cpu: none(FSM) + 외부 80196KC 마이크로프로세서(명령 중계)
language: VHDL
tools: [Quartus II 2.0]
bus: native
peripherals: [actuator-servo, sensor, comm-uart, debug]
stage: T4
license: unknown
stats: {pages: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-02
status: 본문 PDF를 열람함. 그림 속 수치는 텍스트로 확인하지 못함
source_rev: n/a
sources: [https://koreascience.kr/article/CFKO200333239336497.pdf]
---

## 요약
ICCAS 2003(경주)에 실린 논문으로, 한 FPGA 안에 여러 개의 독립 PID 모션 제어기를 넣어 3손가락 로봇 손과 카트형 도립진자를 제어한 사례다. 한국 학회 발표지만 본문은 영어다.

## 구조
- 제어기 하나 = 16비트 엔코더 카운터(디지털 필터 포함) + PID 연산 블록 + PWM 생성기(약 12 kHz) + 통신 블록. 1 kHz 트리거로 제어 루프를 동기시킨다(본문 서술).
- PC의 GUI가 이득과 궤적을 정하고, 80196KC 마이크로프로세서가 FPGA에 명령을 중계한다(본문 서술).
- 적용: 손가락 3개(각 관절 2개)와 카트 위 도립진자.
- 소자: Altera APEX II EP20K300EQC240, 약 30만 게이트. 설계 도구 Quartus II 2.0, 언어 VHDL.

## 검증·재현성
- 결과(본문 서술): 손가락 1 Hz 정현 궤적 추종과 잡기 성공, 도립진자 각도 ±0.4도 이내 유지, 카트 위치는 ±0.02 m로 진동하며 한 방향으로 흘러가는 현상이 있었고 저자는 비선형성 탓으로 봤다.
- 자원 사용량: unverified: 그림으로만 제시된 것으로 보이며 텍스트 수치를 얻지 못함. 소스 공개 여부: unverified.

## 한계·위험
- 상용 제어기 LM629 대비 이점을 주장하지만 정량 비교는 없다(본문 서술).
- 라이선스 정보 없음 → 코드 반입 대상 아님, 구조만 참고.

## 재사용 메모
- 내 판단: "채널마다 엔코더 카운터·PID·PWM 한 벌, 공통 1 kHz 트리거로 동기"라는 구성은 다축 확장과 도립진자 단계(전문)의 구조 근거로 쓸 수 있다. 도립진자 카드가 아직 없어 이 논문이 해당 주제의 첫 근거다.
- 개조: 채널 한 벌을 AXI4-Lite IP 한 개(TRIGGER_PERIOD, KP/KI/KD, SETPOINT, POS_COUNT, DUTY)로 만들고, 외부 마이크로프로세서 중계부는 MicroBlaze V의 AXI 쓰기로 대체한다. APEX II 전용 부분과 80196KC 중계는 옮길 수 없다.
