---
description: 수집 결과 검증·개선 한 사이클 (3시간마다)
---

HARNESS.md §14를 한 사이클 실행한다. 수집 세션의 결론을 믿지 않고 원문을 다시 읽는다.

1. `git pull --rebase origin main`, `python3 tools/check.py`, `python3 tools/audit.py`(오류는 이번 사이클에 고친다), 최신 CI 상태 확인.
2. 대상 선정(최대 10건): 마지막 검증 이후 새 카드 전부, `rechecked_at`이 오래된 카드 2건, L2에서 L3로 올릴 카드 3건.
3. 각 카드의 `sources`를 다시 열어 카드의 보드·CPU·버스·주변장치·수치·라이선스를 대조한다. 불일치는 고치고 `변경:` 한 줄을 남긴다. 삭제하지 않는다.
4. 중복은 `duplicate_of`로 표시하고, `_index.md`를 카드와 일치시킨다.
5. 카드가 3건 이상 늘거나 바뀌었으면 `atlas/`, `soc-map/`를 다시 쓴다(§12.5).
6. `inbox/ideas.md`의 `raw` 아이디어를 §14.2로 심사한다. 한 사이클에 `ready`는 최대 2건.
7. `python3 tools/check.py` 통과 후 로그 한 줄(시각은 `TZ=Asia/Seoul date '+%Y-%m-%d %H:%M'`으로 읽는다), 커밋(`verify: ...`), `git pull --rebase origin main`, 푸시. force push 금지.
8. §8.3 형식으로 보고한다. 불일치와 수정한 항목을 먼저 쓴다.

질문하지 않는다. §2, §6, §7, §9는 예외 없이 적용한다.
