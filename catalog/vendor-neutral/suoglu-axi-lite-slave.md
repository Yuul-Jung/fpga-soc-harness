---
name: suoglu-axi-lite-slave
url: https://github.com/suoglu/AXI-lite-slave
source_type: repo
vendor: amd
board: [Basys3, Arty A7, Nexys Video]
fit_basys3: yes
cpu: none(AXI 슬레이브 IP)
language: Verilog
tools: [Vivado Simulator (버전 미표기)]
bus: AXI4-Lite
peripherals: [GPIO, 7seg, 버튼 카운터]
stage: T2
license: CERN-OHL-W-2.0 (README 표기, 참고 전용 취급)
stats: {commits: 17, stars: 3}
doc_language: en
verification: L2
checked_at: 2026-11-02
sources: [https://GitHub.com/suoglu/AXI-lite-slave]
unverified: 커밋 SHA(source_rev), 소스·테스트벤치 본문(디렉터리 목록과 README만 봄), Vivado 버전, 최신 갱신일, 레지스터별 접근 속성
---

## 요약
AXI4-Lite 슬레이브용 Verilog 모음. Basys3·Arty A7·Nexys Video의 GPIO(스위치·LED·버튼·7세그)를 레지스터로 노출하는 IP 3종과, 단순 읽기/쓰기 핸드셰이크로 감싼 범용 Custom 슬레이브가 있다.

## 구조
- Custom 슬레이브: 읽기·쓰기 채널이 독립이고, `write`/`read`가 `*_done`까지 유지, `*_data`/`*_addrs`/`*_error` 신호, 주소 폭은 `GP_ADDR_WIDTH` (README 서술).
- Basys3 GPIO 레지스터(README): Config 0x00, led 0x04, sw 0x08, ssd 0x0C, 버튼 합산 카운터 0x10, 버튼별(L/U/R/D) 카운터 0x14–0x20. Config bit0 "Keep Button Values".
- 합성 수치(README, Artix-7 기준): Basys3 GPIO 145 LUT / 168 FF, Custom 49 LUT / 83 FF.
- 시험: README 표에 Vivado 시뮬레이션과 보드 시험 일자(2021-10)가 있으나 Custom IP는 보드 시험 항목이 없다. `Test` 폴더 내용은 미열람.

## 검증·재현성
- 위 수치와 일자는 README 서술이며 직접 재현하지 않았다.

## 한계·위험
- 라이선스 CERN-OHL-W-2.0은 정책 허용 목록(permissive)에 없다. 코드를 가져오지 않고 사양(레지스터 배치, 핸드셰이크 개념)만 쓴다(§16.3 G0).
- Vivado 버전 미표기, 2021년 시험 기준이라 2024.2 확인 안 됨.

## 재사용 메모
- 내 판단: "AXI-Lite 슬레이브를 단순 핸드셰이크 뒤로 숨겨 레지스터 로직과 버스를 분리한다"는 구조가 IP 표준 래퍼 설계의 참고가 된다. 레지스터 맵 표기 방식(카운터 영역 분리)도 쓸 만하다.
- 개조: 코드 반입 없이 핸드셰이크 분리 개념과 Basys3 GPIO 레지스터 배치를 사양으로만 참고해 자체 RTL로 쓴다. 래퍼는 IP 표준 계약과 동결 맵 슬롯을 따르고, CI에는 AXI 마스터 모델 테스트벤치를 둔다. 라이선스 확인 필요.
