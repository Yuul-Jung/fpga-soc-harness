---
name: adityapusalkar-fpga-neural-network
url: https://github.com/AdityaPusalkar/fpga_neural_network
source_type: repo
vendor: amd
board: [Basys3]
fit_basys3: yes
cpu: none(MLP 추론 FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [accelerator]
stage: T4
license: unknown
stats: {stars: unverified, commits: unverified, last_update: unverified}
doc_language: en
verification: L3
checked_at: 2026-11-06
sources: [https://github.com/AdityaPusalkar/fpga_neural_network]
---

## 요약

Basys3 대상 Verilog MLP 추론 가속기. 3층 완전연결 신경망으로 MNIST 숫자 인식을 하드웨어에서 직접 수행한다. 활성화 함수는 ReLU만 사용하며, 가중치를 정수 ×100 스케일링해 고정소수점 연산 없이 정수 덧셈·곱셈만으로 추론한다.

## 구조

- 보드: Basys3 (XC7A35T), 클럭: unverified (Vivado 기본 설정 추정)
- 아키텍처: 3층 완전연결(FC) MLP (입력층 → 은닉층 → 출력층)
- 활성화 함수: ReLU (하드웨어 조건 연산 — if(x < 0) 0 else x)
- 가중치 저장: BRAM 9비트 폭 (가중치를 100배 스케일링한 정수값)
- 가중치 스케일링: 소수점 가중치 × 100 → 정수 저장, 연산 후 /100 보정
- Vivado 프로젝트 파일(.xpr) 제공
- xsim 시뮬레이션 4M ns 실행

## 검증·재현성

- 검증: Vivado xsim 시뮬레이션 (시뮬레이션 길이 4M ns 확인)
- Vivado 프로젝트(.xpr) 포함 → Basys3에서 직접 오픈·빌드 가능
- 테스트벤치 자체 PASS/FAIL 판정 여부: unverified (xsim 시뮬레이션은 확인, 자동 판정 여부 미확인)
- 훈련 정확도·자원(LUT/FF/BRAM/DSP) 기록: unverified

## 한계·위험

- 라이선스: LICENSE 파일 미확인 → unknown, 코드 반입 전 확인 필요
- 활성화 함수 ReLU 단일 — sigmoid/tanh/LeakyReLU 없음
- 가중치 ×100 스케일링: 오버플로 위험을 수반할 수 있음 (내 판단: 비트폭 대비 수치 범위 확인 권장)
- README 기재 외 훈련 정확도·자원 사용: unverified
- 동기 리셋/클럭 도메인 세부 사항: unverified

## 재사용 메모

- Basys3 직접 적용 가능(fit_basys3: yes): Vivado 프로젝트 그대로 사용 가능
- ReLU 하드웨어 구현(조건 연산 방식)을 우리 MLP 추론 모듈의 활성화 함수 슬롯 기초로 삼을 수 있음
- 가중치 ×100 정수화 기법: 고정소수점 연산 없이 정수 덧셈·곱셈만으로 추론하는 간단한 접근
- 개조: MicroBlaze V AXI4-Lite 슬레이브로 감쌀 때는 ① AXI 레지스터로 입력 픽셀·제어 ② 완료 인터럽트를 동결 IRQ 슬롯에 배선 ③ 가중치를 AXI를 통해 BRAM에 쓰는 초기화 로직 추가 필요. 활성화 함수 모듈(ReLU)은 독립 모듈로 분리해 재사용 가능. 옮길 수 없는 것: Basys3 보드 래퍼(pinmap.xdc), xsim 프로젝트 설정.
- S4 제약 역전: BRAM 9비트 폭 가중치 패킹은 Basys3 BRAM-bound 제약을 오히려 활용한 사례로 볼 수 있음
