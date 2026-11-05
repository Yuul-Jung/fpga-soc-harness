---
name: amoghvarsh-axi4-lite-timer-wdt
url: https://github.com/AmoghvarshBhasme-11/axi4-lite-timer
source_type: repo
vendor: neutral
board: []
fit_basys3: needs-port
cpu: none(IP 단독)
language: Verilog
tools: [Vivado]
bus: AXI4-Lite
peripherals: [timer, WDT-mode, compare-match]
stage: T2
license: unknown
stats: {stars: 0, commits: 0, last_update: 2024-01}
doc_language: en
verification: L2
checked_at: 2026-11-05
sources: [https://github.com/AmoghvarshBhasme-11/axi4-lite-timer]
---

## 요약 (3줄 이내, 내 표현으로)

AXI4-Lite 슬레이브 타이머 IP — Verilog로 구현되고 Vivado로 검증됨. WDT 모드를 선택할 수 있으며, 비교 매치(compare-match) 출력도 지원한다. 셀프-체킹 테스트벤치가 포함되어 OKAY/SLVERR/DECERR 응답을 자동으로 확인한다.

## 구조

- **버스**: AXI4-Lite 슬레이브
- **기능**: 범용 타이머 + WDT 모드 선택 가능 (1개 IP에서 두 역할 겸용)
- **출력**: 비교 매치(compare-match) 인터럽트/출력 신호
- **검증**: 셀프-체킹 테스트벤치 — OKAY(정상), SLVERR(슬레이브 오류), DECERR(디코드 오류) 케이스 커버
- unverified: 레지스터 목록(오프셋, 비트 정의), 최대 카운터 비트폭, 프리스케일러 여부 — GitHub 직접 열람 차단

## 검증·재현성

- Vivado에서 검증됨 (GitHub 설명 기준)
- 셀프-체킹 TB: OKAY/SLVERR/DECERR 응답 자동 판정 (harnessCI iverilog 호환 여부 미확인)
- unverified: 합성 자원(LUT/FF), WNS, 타이밍 클로저 조건

## 한계·위험

- 라이선스 미확인: GitHub 직접 열람 차단으로 LICENSE 파일 확인 불가 → 코드 반입 시 반드시 확인 필요
- WDT 모드가 기본인지 윈도우인지 불명확 (검색 요약에서 모드 구분 미확인)
- unverified: Basys3 xdc 제공 여부, 절대경로 의존성

## 재사용 메모

- `mij001-axil-timer`(T2, L3)가 이미 카탈로그에 있으므로 중복 주의. 차별점은 WDT 모드 겸용과 셀프-체킹 TB의 SLVERR/DECERR 케이스 커버 — 새 IP 작성 시 TB 패턴 참고용으로 가치 있음.
- 개조: AXI4-Lite 슬레이브 구조를 그대로 MicroBlaze V 동결 맵의 `free_slots` 1개에 연결 가능. 비교 매치 출력을 MicroBlaze 인터럽트 컨트롤러(INTC) 입력으로 연결하면 소프트웨어 타임아웃 알림으로 활용 가능. CPU 종속 부분(인터럽트 핸들러 등록)은 `cpu_irq_mbv.c`에 격리.
- S2 조합 아이디어: AXI4-Lite 타이머(WDT 모드) + 7세그 카운트다운 표시 → I-108(VGA텍스트+7세그 IP) 패턴과 결합하면 T2 복합 주변장치 실습 패키지 가능.
