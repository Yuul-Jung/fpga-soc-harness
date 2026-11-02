---
name: hakan-demirli-pid-fpga
url: https://github.com/hakan-demirli/PID-FPGA
status: 저장소 아카이브됨(소유자, 2025-11-07, 읽기 전용)
source_type: repo
vendor: intel
board: [Altera DE2 (EP2C35F672C6)]
fit_basys3: needs-port
cpu: none(FSM)
language: unknown
tools: [Quartus, MATLAB, HTerm]
bus: none
peripherals: [sensor, actuator, comm-uart, quadrature-encoder, dc-motor]
stage: T4
license: unknown
stats: {}
doc_language: en
verification: L3
checked_at: 2026-11-02
sources: [https://github.com/hakan-demirli/PID-FPGA/blob/main/README.md]
unverified: HDL 언어, 커밋 SHA(source_rev), 라이선스, 자원 사용, 샘플 주기, 모듈 전체 목록(README에 이름만 언급)
---

## 요약
DE2 보드의 FPGA에서 엔코더 되먹임으로 DC 모터 속도(목표 14 RPS)를 PID 제어한 학생 프로젝트. 이득 KP/KD/KI는 PC에서 UART로 실시간 변경하고 응답은 MATLAB으로 그렸다. 이득 조정을 시리얼 레지스터 쓰기로 분리한 점이 특징이다.

## 구조
- 수 형식(README 서술): 36비트 부호 고정소수점, 소수부 9비트(예: 2.5가 0x500). 엔코더 500 PPR를 500 대신 512로 나눠 나눗셈기를 피했고, 측정 속도는 14.15708 RPS(목표 14).
- 직렬 프로토콜: 115200 8N1, 64비트 프레임을 AA/BB 바이트로 감싼다. 주소 0은 전역 리셋, 1~3은 KP/KD/KI 쓰기.
- 목표 속도는 스위치로 입력. 모터 드라이버는 자작.

## 검증·재현성
- 테스트벤치와 오실로스코프 측정(엔코더 주파수)로 검증했다고 서술. 코드는 열람하지 않았고 실행하지 않았다.

## 한계·위험
- README가 밝힌 한계: 곱셈기 0.8% 오차, 적분 와인드업 보호 없음, 이득이 낮아 정착에 수 초, 축 정렬 불량 시 속도 잡음. 저자가 제어 배경 없이 만들었다고 적음.
- 라이선스 미확인 → 코드 가져오기 불가, 사양만 사용. 아카이브 저장소.

## 재사용 메모
- 내 판단: 이득을 UART/레지스터로 런타임 변경하는 구조는 MicroBlaze V에서 AXI4-Lite 레지스터(KP/KI/KD) 쓰기로 그대로 대응되고, 계단 응답 측정·조정 실습의 기반이 된다.
- 개조: 고정소수점 Q 형식은 자체 설계로 새로 정하고(와인드업 보호 포함), 직렬 프레임 대신 IP 표준 레지스터 맵으로 옮긴다. 코어 의존이 없어 CPU 중립이다.
