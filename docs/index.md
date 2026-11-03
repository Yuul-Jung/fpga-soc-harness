# FPGA·SoC 기술 지식 허브

> **Basys3(XC7A35T, Vivado 2024.2+)** 기준의 캡스톤 과제를 목표로,
> 7개 도메인에서 세계 최고 수준 기술 자료를 수집·구조화한 지식 허브입니다.

---

## 도메인 현황

| 도메인 | 우선순위 | 카드 | 캡스톤 | 최근 수집 |
|--------|---------|------|--------|----------|
| FPGA·SoC | ★★★★★ | — | — | [catalog](catalog/_index.md) |
| Arduino | ★★★★☆ | — | — | 수집 예정 |
| STM32 | ★★★★☆ | — | — | 수집 예정 |
| ESP32 | ★★★☆☆ | — | — | 수집 예정 |
| Raspberry Pi | ★★★☆☆ | — | — | 수집 예정 |
| 임베디드 공통 | ★★★☆☆ | — | — | 수집 예정 |
| 전자기술 | ★★☆☆☆ | — | — | 수집 예정 |

---

## 수집 스케줄

| 작업 | 주기 | 내용 |
|------|------|------|
| `/harvest` | 매시 :05 | 창의 전략으로 카드·큐·아이디어 수집 |
| `/verify` | 3시간마다 :35 | 재열람·수정·통합 문서 갱신·아이디어 심사 |
| `/capstone` | 6시간마다 :50 | `ready` 아이디어 → 캡스톤 패키지 |
| 전수 감사 | 매시 :20 UTC (CI) | 카드·명세·소스 대조 (읽기 전용) |

---

## FPGA·SoC 기술 트리

```
T0 ISA·도구 → T1 단일 사이클 코어 + MMIO → T2 SoC 접착
→ T3 프레임워크 기반 SoC → T4 가속기·영상/신호처리 → T5 OS 구동
```

- [카탈로그 색인](catalog/_index.md) — 검증된 카드 전체 목록
- [아이디어 큐](inbox/ideas.md) — raw → vetted → ready → used
- [수집 로그](inbox/log.md) — 자동 수집 실행 이력

---

## 바로가기

- **[HARNESS.md](HARNESS.md)** — 수집·검증·캡스톤 운영 지침
- **[GitHub](https://github.com/Yuul-Jung/fpga-soc-harness)** — 저장소
- **[이슈 등록](https://github.com/Yuul-Jung/fpga-soc-harness/issues)** — 오류 신고·제안
