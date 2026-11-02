---
description: 캡스톤 패키지(문서 HTML + 계통도 + 실행 소스) 한 건 작성
argument-hint: "<주제 또는 slug>"
---

HARNESS.md §13에 따라 캡스톤 패키지를 작성한다. 주제: $ARGUMENTS

1. `catalog/_index.md`에서 근거 카드를 고른다. 카드가 부족하면 어떤 카드가 필요한지 보고하고, 가능한 범위에서만 진행한다.
2. `capstones/<slug>/capstone.json`을 먼저 쓴다 (블록, 링크, 메모리맵). 기준 예시는 `capstones/mmio-uart-gpio-skeleton/`.
3. 명세대로 rtl, tb, constr, Makefile을 직접 쓴다. 외부 코드는 복사하지 않는다.
4. `python3 tools/run_verify.py`, `python3 tools/build.py`, `python3 tools/check.py`를 실행한다. 건너뛴 단계는 통과로 쓰지 않는다.
5. `docs/<slug>/index.html`을 열어 계통도와 표를 눈으로 확인한다.
6. 커밋하고 `main`에 푸시한다. 메시지는 `capstone: add <slug>`.
7. 보고에 검증 등급(S0~S3)을 반드시 쓴다. S3는 올리지 않는다.
