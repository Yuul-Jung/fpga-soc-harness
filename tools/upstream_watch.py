#!/usr/bin/env python3
"""업스트림 변경 감시 (읽기 전용).

카드 frontmatter의 url(GitHub 저장소)과 source_rev(읽은 시점 커밋 SHA)를 보고,
원본 저장소의 기본 브랜치 현재 HEAD와 비교해 build/upstream_drift.json 에 쓴다.
- 달라졌다 = 재확인 후보이지 오류가 아니다. 종료 코드는 항상 0.
- 카드를 고치지 않는다. 네트워크 실패는 해당 카드를 'unreachable'로만 기록한다.
- GITHUB_TOKEN 이 있으면 인증 호출(한도 상향), 없으면 비인증.
표준 라이브러리만 사용한다.
"""
import json, os, re, sys, glob, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = re.compile(r"^https://github\.com/([^/\s]+)/([^/\s#?]+?)(?:\.git)?/?$")


def frontmatter(path):
    t = open(path, encoding="utf-8").read()
    if not t.startswith("---"):
        return {}
    end = t.find("\n---", 3)
    fm = {}
    for ln in t[3:end].splitlines():
        m = re.match(r"^([A-Za-z_]+):\s*(.*)$", ln)
        if m:
            fm[m.group(1)] = m.group(2).strip()
    return fm


def head_sha(owner, repo):
    req = urllib.request.Request(f"https://api.github.com/repos/{owner}/{repo}/commits?per_page=1",
                                 headers={"Accept": "application/vnd.github+json", "User-Agent": "fpga-soc-harness-watch"})
    tok = os.environ.get("GITHUB_TOKEN")
    if tok:
        req.add_header("Authorization", f"Bearer {tok}")
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)[0]["sha"]


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(ROOT, "catalog", "*", "*.md"))):
        fm = frontmatter(path)
        rev = fm.get("source_rev", "").strip()
        m = REPO.match(fm.get("url", ""))
        if not (rev and m):
            continue
        row = {"card": fm.get("name") or os.path.basename(path)[:-3], "repo": f"{m.group(1)}/{m.group(2)}", "source_rev": rev}
        try:
            cur = head_sha(m.group(1), m.group(2))
            row["head"] = cur
            row["state"] = "same" if cur.startswith(rev) or rev.startswith(cur) else "changed"
        except (urllib.error.URLError, OSError, KeyError, ValueError) as e:
            row["state"] = "unreachable"
            row["error"] = str(e)[:80]
        rows.append(row)
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    out = os.path.join(ROOT, "build", "upstream_drift.json")
    json.dump({"checked": len(rows), "changed": [r["card"] for r in rows if r["state"] == "changed"], "rows": rows},
              open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    for r in rows:
        print(f'{r["state"]:11} {r["card"]}  ({r["repo"]})')
    print(f"감시 {len(rows)}건, 변경 {sum(r['state']=='changed' for r in rows)}건 → build/upstream_drift.json")
    print(f"안내: 변경은 재확인 후보이며 오류가 아니다. source_rev 가 있는 카드만 대상 ({len(rows)}건).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
