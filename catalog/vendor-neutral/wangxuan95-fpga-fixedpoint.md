---
name: wangxuan95-fpga-fixedpoint
url: https://github.com/WangXuan95/FPGA-FixedPoint
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(DSP 라이브러리)
language: Verilog
tools: [iverilog]
bus: none
peripherals: []
stage: T4
license: GPL-3.0
stats: {stars: 241, forks: 42, commits: 23}
doc_language: en
verification: L3
checked_at: 2026-11-06
source_rev:
sources: [https://github.com/WangXuan95/FPGA-FixedPoint]
---

## 요약

WangXuan95가 작성한 Verilog 고정소수점 연산 라이브러리. WOI/WOF 파라미터로 Q포맷 비트폭을 임의 지정하고, 포화(upflow/underflow) 출력 플래그와 반올림 모드(ROUND=0/1)를 제공한다. 단일 사이클과 파이프라인 버전이 함께 있으며 float ↔ fixed 변환도 포함된다.

## 구조

- 단일 소스 파일: `RTL/fixedpoint.v`
- 모듈 목록과 파이프라인 단계 (열람 기준):

| 모듈 | 기능 | 파이프라인 단계 |
|------|------|----------------|
| `fxp_zoom` | 비트폭 변환 | 단일 사이클 |
| `fxp_addsub` | 덧셈/뺄셈 | 단일 사이클 |
| `fxp_add` | 덧셈 전용 | 단일 사이클 |
| `fxp_mul` / `fxp_mul_pipe` | 곱셈 | 단일 / 2단계 |
| `fxp_div` / `fxp_div_pipe` | 나눗셈 | 단일 / WOI+WOF+3단계 |
| `fxp_sqrt` / `fxp_sqrt_pipe` | 제곱근 | 단일 / WII/2+WIF+2단계 |
| `fxp2float` / `fxp2float_pipe` | 고정→IEEE-754 float | 단일 / WII+WIF+2단계 |
| `float2fxp` / `float2fxp_pipe` | IEEE-754 float→고정 | 단일 / WOI+WOF+4단계 |

- 파라미터 체계: 단항 연산은 WII(입력 정수 비트)/WIF(입력 소수 비트)/WOI/WOF, 이항 연산은 WIIA/WIFA/WIIB/WIFB/WOI/WOF. 값은 `2의 보수 정수값 / 2^WIF`로 해석됨.
- ROUND 파라미터: 1(기본, 반올림), 0(절사). 출력 소수 비트 수를 줄일 때 적용.
- 포화 처리: 오버플로(upflow) 시 출력을 양의 최대값(2^(WOI-1)-1)으로, 언더플로 시 음의 최소값(-2^(WOI-1))으로 고정. `overflow` 출력 포트가 1이 됨.
- 테스트벤치: `SIM/tb_add_sub_mul_div.v`, `tb_fxp_mul_div_pipe.v`, `tb_fxp_sqrt.v`, `tb_convert_fxp_float.v`. iverilog + `.bat` 스크립트.

## 검증·재현성

- iverilog 기반 시뮬레이션 (`SIM/` 디렉토리 내 .bat 실행). PASS/FAIL 출력 여부는 테스트벤치를 직접 열어 보지 않아 `unverified`.
- Basys3/Xilinx FPGA 합성 결과 미기재: DSP48E1 추론 여부 불명. `unverified: 합성 보고 없음`.
- CI 파이프라인 없음(GitHub Actions 없음).

## 한계·위험

- **GPL-3.0**: §16.3 G0에 따라 코드를 저장소에 복사할 수 없음. 포트 사양·레지스터 구조·알고리즘 패턴을 참고해 자체 RTL을 작성해야 함.
- 절사 없이 반올림 모드 2가지(ROUND=0/1)만 제공. 수렴 반올림(ConvEven) 등 편향 없는 모드는 없음.
- Basys3용 xdc·Vivado 프로젝트 없음. 합성 자원 불명.
- 중국어·영어 README이며, 모듈 동작 명세 일부가 중국어로만 적혀 있음.

## 재사용 메모

- Q포맷 연산 IP를 직접 가져오는 것은 GPL-3.0로 불가. 대신 파라미터 설계 패턴(WOI/WIF 분리, upflow 플래그, ROUND 파라미터)을 참고해 자체 Verilog를 쓸 수 있음.
- 개조: MicroBlaze V AXI4-Lite 슬레이브로 감싸려면 ① AXI-Lite 레지스터 인터페이스를 추가하고, ② 계산 결과를 상태 레지스터로 노출하며, ③ 동결 맵 `free_slots`의 64KB 슬롯 하나를 배정. 소수 비트수·정수 비트수는 AXI 파라미터가 아니라 상수(IP 표준 §17.2)로 결정하는 것이 Vivado 합성 품질에 유리.
- 내 판단: fxp_mul_pipe(2단계 파이프라인)는 Basys3 DSP48E1 추론에 적합한 구조. 단, 라이선스 때문에 반드시 자체 재작성 필요.
