---
description: 자동 수집 한 사이클 실행 (주제 인자 선택)
argument-hint: "[주제]"
---

HARNESS.md §12 자동 수집 모드를 한 사이클 실행한다. 주제: $ARGUMENTS (비어 있으면 `inbox/topics.md`의 첫 `[ ]` 항목).

1. `catalog/_index.md`, `inbox/queue.md`, `inbox/topics.md`, `inbox/log.md`를 읽는다.
2. §12.3의 순서(발견 → 선별 → 열람 → 변환 → 통합 → 점검 → 기록)를 따른다. 질문하지 않는다.
3. 커밋 전에 `python3 tools/check.py`가 통과해야 한다.
4. 주제별로 커밋하고 `main`에 푸시한다. 커밋 메시지는 §8.2 형식을 쓴다.
5. 마지막에 §8.3 형식으로 보고한다. 첫 줄에 택한 해석(주제, 범위)을 쓴다.

§2, §6, §7, §9와 §12.6의 상한은 예외 없이 적용한다.
