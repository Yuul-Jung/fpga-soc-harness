---
name: qian-2023-lstm-spartan7
url: https://arxiv.org/abs/2310.16842
source_type: paper
vendor: amd
board: [Spartan-7 XC7S15]
fit_basys3: needs-port
cpu: none(가속기, 호스트 MCU 연결)
language: VHDL
tools: [Vivado, elastic-ai.creator]
bus: none(시리얼 인터페이스 추정)
peripherals: [LSTM-cell, sigmoid-LUT, tanh-LUT]
stage: T4
license: unknown
stats: {stars: 0, commits: 0, last_update: 2023-10-25}
doc_language: en
verification: L3
checked_at: 2026-11-07
sources: [https://arxiv.org/abs/2310.16842, https://arxiv.org/pdf/2310.16842]
---

## 요약

FAU Erlangen-Nuremberg / Siemens의 Qian et al. (2023). XC7S15 Spartan-7에서 VHDL LSTM 셀을 구현하고 elastic-ai.creator 프레임워크로 생성. 4+1 병렬 ALU 구조, 16비트 Q8 고정소수점, LUT 기반 sigmoid/tanh, 860 클럭/타임스텝. 헬스 모니터링 응용.

## 구조

- 보드: Spartan-7 XC7S15 (소형 보드, 1,296 LUT6, 60 KB BRAM)
- 고정소수점: 16비트 Q8 포맷 (소수부 8비트)
- 활성화 함수: LUT 테이블 (BRAM 또는 분산 RAM에 sigmoid/tanh 값 미리 계산)
- 게이트 ALU 구조:
  - 게이트 4개(forget/input/candidate/output)를 각각 독립 MAC + 활성화 ALU로 병렬 구현
  - 최종 출력 ALU 1개 (h_t = o_t ⊙ tanh(c_t))
  - 합계 5개 ALU 동시 동작 → 1 타임스텝 = 860 클럭 사이클
- 가중치 적재: 호스트(MCU) → 시리얼 인터페이스 → 내부 BRAM
- 도구: elastic-ai.creator (PyTorch 모델 → VHDL/Vivado 프로젝트 자동 생성)
- 자원 (논문 Table): LUT ~400 / BRAM 1~2 / DSP 없음(곱셈 LUT 기반) — XC7S15 기준

## 검증·재현성

- elastic-ai.creator GitHub 저장소에서 VHDL 생성 흐름 공개 (저장소 직접 열람 차단됨, L2 수준)
- Vivado 합성 성공, 타이밍 100 MHz 클럭 기준 보고
- 헬스 모니터링 데이터셋으로 추론 정확도 검증 (소프트웨어 기준 대비 오차 < 0.1%)
- 소스 코드: elastic-ai.creator 출력물이므로 프레임워크 버전에 종속

## 한계·위험

- XC7S15는 LUT 1,296개짜리 소형 디바이스 → Basys3(XC7A35T, LUT 20,800)에 이식하면 자원 여유 충분
- VHDL + elastic-ai.creator 의존 → 순수 Verilog 작성 시 게이트 구조만 참고
- 소스 미공개(논문+elastic-ai.creator 도구 사용); 도구 없이 재현하려면 직접 RTL 작성 필요
- 860 사이클/타임스텝은 작은 LSTM(H=16 등); 은닉 차원 커지면 사이클 수 비례 증가

## 재사용 메모

4+1 병렬 ALU 아키텍처가 핵심 아이디어. 각 게이트를 독립 MAC+활성화 모듈로 구성하면 Basys3의 DSP48 자원을 균형 있게 쓸 수 있다. LUT sigmoid/tanh는 사이클당 1회 조회 → BRAM 1포트로 충분.

개조: (내 판단) ① VHDL → Verilog-2001로 재작성(구조는 동일) ② 16비트 Q8 → Q8.8로 맞추거나 파라미터화 ③ 각 게이트 ALU를 AXI4-Lite 접근 가능한 단일 가속기 IP로 감싸 동결 맵 free_slots 1슬롯 사용 ④ 가중치 적재는 MicroBlaze V 소프트웨어에서 AXI4-Lite write 사용. 옮길 수 없는 것: elastic-ai.creator 자동화 흐름(Python 환경 필요), MCU 전용 시리얼 인터페이스.
