---
name: andreicito2-inverted-pendulum
url: https://github.com/andreicito2/Inverted-Pendulum
source_type: repo
vendor: amd
board: [Spartan-3 (보드 모델 미명시)]
fit_basys3: needs-port
cpu: none(호스트 PC가 제어)
language: Octave
tools: [Octave control 패키지]
bus: none
peripherals: [sensor, actuator-servo, comm-uart]
stage: T3
license: unknown
stats: {commits: 58}
doc_language: en
verification: L2
checked_at: 2026-11-03
status: README 요약 수준만 열람, 소스 파일 미열람
sources: [https://github.com/andreicito2/Inverted-Pendulum]
unverified: FPGA 쪽 RTL 포함 여부, 통신 방식 세부, 라이선스, 최종 커밋 날짜와 SHA, 제어 성공 여부
---

## 요약
대학 제어 과목(ENGR 454) 프로젝트. 이중 도립진자를 DC 모터 + 줄로 움직이는 카트 위에 두고, 호스트 PC의 Octave가 LQR 상태 되먹임과 전상태 Luenberger 관측기를 계산한다. FPGA는 모터·센서 입출력 담당.

## 구조
- 센서: 엔코더 4개 중 3개 사용(진자 각도 2 + 카트 위치), 홀 센서 2개로 트랙 끝 차단.
- 폴더: Control Code, Derivations, Photos, Simulations, Milestones.md. 핵심 스크립트 두 개(제어법, FPGA·모터 인터페이스).
- 관측기 극점은 수동 조정(README 서술).

## 검증·재현성
- 빌드 절차 없음. Octave 스크립트를 FPGA 연결 상태로 실행하는 방식.

## 한계·위험
- FPGA RTL이 저장소에 있는지, 어떻게 PC와 통신하는지 확인하지 못함. 제어 루프가 PC 소켓 경유라 지연이 크다는 점은 구조상 추정(내 판단).
- 라이선스 미기재 - 코드 반입 불가, 사실만 기록.

## 재사용 메모
- 내 판단: FPGA를 "엔코더 3채널 + PWM + 리밋 차단" 인터페이스로만 쓰고 제어는 외부에서 하는 구성은 UART 메모리 브리지(I-012) 같은 IP로 PC 제어기를 시험하는 중간 단계로 쓸 수 있다. 상태 벡터가 6개(각도 2, 각속도 2, 위치, 속도)로 늘어나는 이중 진자는 난이도가 높다.
- 개조: Spartan-3 보드 자료이므로 핀·클럭 포팅 필요. 엔코더 카운터·홀센서 차단·PWM을 IP 표준 래퍼로, PC 연동은 UART 브리지로 옮길 수 있다. 호스트 Octave 계산부는 옮기지 않는다.
- 라이선스 확인 필요: 라이선스 미기재(unknown)이므로 코드 반입 없이 사양만 참고한다(§6.3, §16.3 G0).
