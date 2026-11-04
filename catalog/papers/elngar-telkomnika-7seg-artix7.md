---
name: elngar-telkomnika-7seg-artix7
url: https://telkomnika.uad.ac.id/index.php/TELKOMNIKA/article/view/27610
source_type: paper
vendor: amd
board: [Nexys-4 DDR]
fit_basys3: needs-port
cpu: none(FSM)
language: VHDL
tools: [Vivado]
bus: none
peripherals: [7seg-mux]
stage: T1
license: open-access
stats: {stars: 0, commits: 0, last_update: 2026-04}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://telkomnika.uad.ac.id/index.php/TELKOMNIKA/article/view/27610]
---

## 요약

TELKOMNIKA Telecommunication Computing Electronics and Control 2026년 4월 게재 논문. Artix-7 FPGA(Nexys-4 DDR, XC7A100T)에서 카운터 중심(counter-centric) 구조로 BCD 변환 + 7세그먼트 멀티플렉스 드라이버를 VHDL로 구현한다. 고스팅(ghosting) 제거가 핵심 기여로, 분주기 너비·자리 수·갱신률의 조합으로 타이밍을 스케일할 수 있는 모델을 제시한다.

DOI: 10.12928/telkomnika.v24i2.27610 (검색 요약 기준이므로 DOI 미직접 확인).

## 구조

- 3블록 구성 (논문 블록 다이어그램 기준):
  1. BCD 변환기: 이진수 → BCD (binary-to-BCD 알고리즘, 세부 미확인)
  2. 7세그먼트 디코더: BCD → cathode 패턴, active-low 공통 애노드 출력
  3. 카운터 기반 클럭 인에이블 멀티플렉서: 분주 카운터가 `anode` 선택과 `cathode` 패턴 타이밍을 직접 제어 → 고스팅 원인(blank 간격 없는 MUX 전환)을 구조적으로 제거
- 타이밍 모델: `divider_width × digit_count × update_rate` 파라미터 조합으로 스케일, Nexys-4 DDR 100 MHz 기준 설계
- 보드: Nexys-4 DDR (XC7A100T-CSG324). Basys3(XC7A35T) 대비 FPGA 패밀리 동일(Artix-7)하나 패키지·핀맵 상이

## 검증·재현성

- 논문 내 Vivado 합성 및 보드 구현 결과 포함 (검색 요약 기준; 자원 LUT/FF 수치 미확인)
- open-access 저널 게재 → 논문 PDF 열람 가능 (열람 범위: 초록·메타데이터)
- 소스 코드 별도 공개 링크 미확인 (논문 본문 미열람)

## 한계·위험

- 단일 카운터 구조는 고스팅 제거에 효과적이나, 개별 자리 blank 제어 포트가 있는지 논문 미확인
- Nexys-4 DDR(8자리 7세그먼트)과 Basys3(4자리)의 자리 수 차이 → 디지트 선택 로직 수정 필요
- VHDL 코드 직접 미열람 → 포트 목록·신호 이름 미확인 (unverified)
- 소수점(dp) 개별 제어 포트 존재 여부 미확인

## 재사용 메모

- 카운터 중심 고스팅 제거 기법은 VHDL 세부에 무관하게 Verilog/SystemVerilog로 이식 가능. 핵심: MUX 전환 직전 모든 cathode를 `1'b1`(소등)으로 세팅 후 1~2 클럭 지연 후 다음 애노드 활성화.
- Basys3 포팅: 8자리 → 4자리, `anode[7:0]` → `anode[3:0]`, 분주 카운터 너비 2비트로 축소, 100 MHz 그대로 사용.
- 개조: MicroBlaze V AXI4-Lite 슬레이브로 감쌀 때 카운터 분주비를 `SCAN_RATE_DIV` 레지스터(오프셋 0x08)로 소프트웨어 조정 가능하게 구성하면 갱신률 런타임 변경 지원. 옮길 수 없는 부분: Nexys-4 DDR 전용 xdc 핀맵 — Basys3 xdc 재작성 필요(패밀리 동일하므로 타이밍 제약은 재활용 가능).
- 라이선스 확인 필요: open-access 저널 게재이나 VHDL 소스 코드의 라이선스는 별도 확인이 필요하다. 기법·구조만 참고하고 코드를 저장소에 반입하지 않는다.
