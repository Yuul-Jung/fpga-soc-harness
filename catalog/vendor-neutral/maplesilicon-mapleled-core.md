---
name: maplesilicon-mapleled-core
url: https://github.com/MapleSilicon/mapleled-core
source_type: repo
vendor: neutral
board: [iCEBreaker, iCE40 UP5K]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Icarus Verilog, GTKWave]
bus: none
peripherals: [pwm-rgb, led-breathing]
stage: T1
license: MIT
stats: {stars: 0, commits: unknown, last_update: unknown}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/MapleSilicon/mapleled-core]
---

## 요약

오픈소스 파라메트릭 PWM + LED 호흡 엔진. 8비트 듀티 사이클, 선택적 감마 보정 LUT 내장.
iCE40 UP5K / iCEBreaker 용으로 개발되었으며, Icarus Verilog + GTKWave로 검증.

## 구조
- 단일 모듈 `mapleled.v` (추정, srcs 디렉터리 확인 불가).
- 파라미터: PWM 폭 기본 8비트, 클럭 주파수 선택.
- 선택적 감마 보정: 인지 밝기에 맞추는 선택 옵션으로 제공.
- 출력 1비트 → 채널별로 복제해 RGB 사용.
- 시뮬레이션: `mapleled-core/sim/` 폴더, `make run` 후 `make view` (GTKWave).

## 검증·재현성
- Icarus Verilog로 동작 확인 보고.
- Lattice iCE40 타겟. Artix-7 Basys3 합성 여부는 미확인.
- open issue 1건이 존재하나 내용 미열람.
unverified: 감마 보정의 구현 방식(LUT 크기·수식)은 소스 직접 열람 불가로 미확인

## 한계·위험
- stars 0, 커밋 수 미확인. 검증 커버리지 범위 불명.
- RGB 채널 조합 방법은 README에 명시되지 않음.
- HSV→RGB 변환 없음.

## 재사용 메모
- 감마 보정 LUT 아이디어를 Basys3 AXI4-Lite RGB PWM IP의 감마 테이블 구조로 참고 가능.
개조: MIT 라이선스이므로 LUT 테이블 구조와 모듈 인터페이스를 착안해 Basys3 AXI4-Lite 슬레이브 감마-PWM IP로 자체 RTL 재작성 가능. CPU 종속 없음(순수 FSM+LUT). 클럭 도메인은 Basys3 100 MHz 맞게 분주비 조정만 필요. 감마 LUT는 BRAM 초기화 블록(`$readmemh`)으로 구성하면 Artix-7에서 1개 BRAM36으로 처리 가능(256×8b). 내 판단: 아이디어 참고용으로 적합, 직접 포팅보다 착안 재작성 권장.
