---
name: element14-arty-s7-7seg-brightness
url: https://community.element14.com/technologies/fpga-group/b/blog/posts/seven-segment-display-controlled-by-arty-s7-board
source_type: article
vendor: amd
board: [Arty S7]
fit_basys3: needs-port
cpu: none(FSM)
language: Verilog
tools: [Vivado]
bus: none
peripherals: [7seg-mux]
stage: T1
license: unknown
stats: {stars: 0, commits: 0, last_update: unknown}
doc_language: en
verification: L3
checked_at: 2026-11-04
sources: [https://community.element14.com/technologies/fpga-group/b/blog/posts/seven-segment-display-controlled-by-arty-s7-board]
---

## 요약

element14 커뮤니티 블로그 게시글. Arty S7(XC7S50) 보드에서 Pmod JD에 연결한 단일 자리 7세그먼트 디스플레이(FJS-5161B, 공통 캐소드)를 Verilog `display` 모듈로 제어한다. 핵심 기여: `pulseDuration[3:0]` 입력으로 15단계 PWM 밝기 조절과 `dotPoint` 소수점 독립 제어.

## 구조

- 모듈 `display`: 입력 `CLK100MHZ`, `digit[3:0]`(BCD 0~9), `dotPoint`(소수점 on/off), `pulseDuration[3:0]`(0=OFF, 15=최대 밝기)
- 출력: 7개 세그먼트 신호 + 소수점 → Pmod JD 핀 직결
- 밝기 조절 메커니즘: 내부 카운터가 `pulseDuration` 값에 따라 duty cycle 결정 → 세그먼트 활성 시간 비율로 밝기 조절 (PWM 등가, 세부 카운터 비트 폭 미확인)
- 단일 자리 구조 → 멀티플렉싱 없음 (복수 자리 확장 시 MUX 레이어 추가 필요)
- FJS-5161B: 공통 캐소드 단일 자리 디스플레이, 3.3V 직구동 (Basys3의 공통 애노드 4자리와 극성 반대)

## 검증·재현성

- 블로그 게시글 직접 열람 완료 (L3): Verilog 모듈 포트 목록·동작 설명 확인
- 소스 코드 GitHub 별도 링크 미확인 (블로그 내 인라인 코드 or 첨부 가능성 있으나 미확인)
- 보드 사진과 Vivado 연결 화면 포함 (보드 구동 확인 근거)
- 라이선스 명시 없음 → unknown

## 한계·위험

- Arty S7: 공통 캐소드, Basys3: 공통 애노드 → 세그먼트 활성 극성 반대(전체 반전 필요)
- 단일 자리 → Basys3 4자리 멀티플렉싱 추가 필요
- Spartan-7 IP, Basys3는 Artix-7 → 같은 7 Series지만 디바이스 패밀리 상이 (타이밍/DSP 사양 차이)
- `pulseDuration` 카운터 비트 폭 미확인 → 실제 PWM 주파수 불명
- 라이선스 미확인 → 코드 직접 사용 시 "라이선스 확인 필요"

## 재사용 메모

- `pulseDuration[3:0]` 15단계 밝기 제어 아이디어는 Basys3에서 충분히 이식 가능. 공통 애노드 반전만 적용하면 됨.
- 소수점 독립 제어(`dotPoint`)를 `dp_in[3:0]` 비트 필드로 확장하면 BYU ECEN320(`byu-ecen320-seven-segment4`)의 blank+dp 구조와 결합 가능.
- 개조: MicroBlaze V AXI4-Lite 슬레이브 IP로 통합 시 — `BRIGHTNESS`(오프셋 0x08, bit[3:0]=pulseDuration)와 `DIGIT_DATA`(bit[15:0]=4자리 BCD, bit[19:16]=dp_in, bit[23:20]=blank) 레지스터 2개 구조 제안. 옮길 수 없는 부분: 단일 자리 공통 캐소드 출력 → 공통 애노드 4자리 MUX로 재설계, Spartan-7 전용 IO 표준은 Artix-7로 교체.
