---
description: 자동 수집 한 사이클 (창의 전략 사용, 1시간마다)
argument-hint: "[주제]"
---

HARNESS.md §12 자동 수집 모드를 한 사이클 실행한다. 주제: $ARGUMENTS (비어 있으면 `inbox/topics.md`의 첫 `[ ]` 항목, 그것도 비면 §12.2의 3번).

1. `git pull --rebase origin main` 후 `catalog/_index.md`, `inbox/queue.md`, `inbox/topics.md`, `inbox/ideas.md`, `inbox/log.md`를 읽는다.
2. §12.8에서 주 전략 하나와 보조 전략 하나를 고른다. 최근 로그 5건에서 쓰지 않은 전략을 우선한다.
3. §12.3 순서(발견 → 선별 → 열람 → 변환 → 기록)를 따른다. 상한: 검색 15, 열람 20, 카드 3, 큐 10, 아이디어 3.
4. 새 아이디어는 `inbox/ideas.md`에 `raw`로 쓴다. 근거 URL 또는 카드 2건 이상이 있어야 한다.
5. 통합 문서(`atlas/`, `soc-map/`)는 이 사이클에서 쓰지 않는다. `/verify`가 맡는다.
6. `python3 tools/check.py`가 통과해야 한다. 질문하지 않는다.
7. 로그 한 줄, 커밋(§8.2), `git pull --rebase origin main`, 푸시. force push 금지.
8. §8.3 형식으로 보고한다. 첫 줄에 택한 전략과 해석을 쓴다.

§2, §6, §7, §9는 예외 없이 적용한다.
