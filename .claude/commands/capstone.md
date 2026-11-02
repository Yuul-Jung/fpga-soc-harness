---
description: 캡스톤 패키지(문서 HTML + 계통도 + 실행 소스) 한 건 작성. 6시간마다 자동, 수동도 가능
argument-hint: "[아이디어 id 또는 slug]"
---

HARNESS.md §13을 따라 캡스톤 패키지를 한 건 만든다. 지정: $ARGUMENTS (비어 있으면 §13.7 자동 과제화).

0. `git pull --rebase origin main`. §13.7의 게이트 네 가지를 확인한다. 자동 실행에서 하나라도 못 채우면 `inbox/log.md`에 `skip: <사유>`를 남기고 끝낸다. 만들지 않는다.
1. 대상 아이디어(`ready`)와 근거 카드를 읽는다. 아이디어를 `used`로 바꾸고 slug를 적는다.
2. `capstones/<slug>/capstone.json`을 먼저 쓴다. 기준 예시는 `capstones/mmio-uart-gpio-skeleton/`.
3. 명세대로 rtl, tb, constr, Makefile을 직접 쓴다. 외부 코드는 복사하지 않는다. RTL은 약 400줄 이내.
4. `python3 tools/build.py`, `python3 tools/check.py`를 실행하고 `docs/<slug>/index.html`을 열어 계통도와 표를 눈으로 확인한다. (이 환경에 시뮬레이터가 없으면 `tools/run_verify.py`는 건너뛴다.)
5. 커밋(`capstone: add <slug>`), `git pull --rebase origin main`, 푸시.
6. CI 결과를 공개 API로 기다린다(최대 10분). 실패하면 주석에서 원인을 읽고 고쳐 다시 푸시한다(최대 3회). 계속 실패하면 명세에 `"status": "broken"`을 쓰고 로그에 남긴다.
7. 로그 한 줄(시각은 `TZ=Asia/Seoul date '+%Y-%m-%d %H:%M'`으로 읽는다). 보고에 검증 등급(S0~S3)을 쓴다. CI 통과는 S2, 미통과는 S0. S3는 올리지 않는다.

질문하지 않는다. §2, §6, §7, §9는 예외 없이 적용한다.
