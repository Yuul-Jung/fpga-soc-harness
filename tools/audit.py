#!/usr/bin/env python3
"""저장소 전수 감사 (읽기 전용). 표준 라이브러리만 사용.
수집한 카드, 캡스톤 명세, 소스, 생성 문서를 매번 처음부터 다시 대조한다.
  1) 카드 점검 (tools/check.py)
  2) 카드 정책: 라이선스 게이트, source_rev 형식, 재확인 기한
  3) 캡스톤: 명세 검증, 코드 이름 대조, 동결 주소맵, 외부 부품 전압
  4) 생성 문서: 링크, SVG, JSON, 소스 매니페스트 해시
  5) 아이디어: used 항목의 패키지 존재
결과: build/audit.json, 오류가 있으면 종료 코드 1.
사용법: python3 tools/audit.py [--no-build]   (--no-build: docs/ 를 새로 만들지 않고 있는 것만 본다)"""
import hashlib
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from datetime import date, datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build  # noqa: E402
import capcheck  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
findings = []  # (level, scope, message)


def add(level, scope, msg):
    findings.append({"level": level, "scope": scope, "message": msg})


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        key = "href" if tag == "a" else "src" if tag in ("img", "script") else None
        if key and a.get(key):
            self.refs.append(a[key])


def audit_cards(pol):
    permissive = set(pol["license"]["permissive_spdx"])
    pat = re.compile(pol["cards"]["source_rev_pattern"])
    today = date.today()
    limit = timedelta(days=pol["cards"]["recheck_days"])
    n = 0
    for p in sorted((ROOT / "catalog").rglob("*.md")):
        if p.name == "_index.md":
            continue
        n += 1
        text = p.read_text(encoding="utf-8")
        fm, body = build.split_frontmatter(text)
        name = fm.get("name", p.stem)
        lic = str(fm.get("license", "")).strip()
        memo = body.split("## 재사용 메모")[-1] if "## 재사용 메모" in body else ""
        takes_code = re.search(r"가져(와|올|온|가)|복사|포팅|그대로 (쓴|사용|재사용)|이식", memo)
        mentions_license = re.search(r"라이선스|license|GPL|MIT|BSD|Apache|자체 (RTL|설계|작성)|새로 (쓴|작성)", memo, re.I)
        if lic not in permissive and takes_code and not mentions_license:
            add("warn", f"card:{name}", f"라이선스 {lic or '미기재'}인데 재사용 메모가 코드 가져오기를 말하면서 라이선스를 언급하지 않음 (HARNESS §6.3)")
        rev = fm.get("source_rev")
        if rev and not pat.match(str(rev)):
            add("error", f"card:{name}", f"source_rev 형식 오류: {rev}")
        if fm.get("source_type") == "repo" and not rev:
            add("info", f"card:{name}", "source_rev 없음 (읽은 시점의 커밋 SHA를 기록하면 재확인이 쉬워진다)")
        for key in ("rechecked_at", "checked_at"):
            v = fm.get(key)
            if v and re.match(r"^\d{4}-\d{2}-\d{2}$", str(v)):
                last = date.fromisoformat(str(v))
        base = str(fm.get("rechecked_at") or fm.get("checked_at") or "")
        if re.match(r"^\d{4}-\d{2}-\d{2}$", base) and today - date.fromisoformat(base) > limit:
            add("warn", f"card:{name}", f"{base} 이후 {pol['cards']['recheck_days']}일 넘음: 재확인 후보")
    return n


def audit_capstones():
    names = []
    for sp in sorted((ROOT / "capstones").glob("*/capstone.json")):
        if sp.parent.name.startswith("_"):
            continue
        spec = json.loads(sp.read_text(encoding="utf-8"))
        names.append(spec["slug"])
        errs, warns = build.validate(spec, sp.parent)
        for e in errs:
            add("error", f"capstone:{spec['slug']}", e)
        for w in warns:
            add("warn", f"capstone:{spec['slug']}", w)
        if spec.get("status") == "broken":
            add("error", f"capstone:{spec['slug']}", "status: broken")
        rtl_lines = sum(len((sp.parent / f).read_text(encoding="utf-8").splitlines()) for f in spec["sources"].get("rtl", []))
        if rtl_lines > capcheck.policy()["capstone"]["max_rtl_lines"] * 3:
            add("warn", f"capstone:{spec['slug']}", f"RTL {rtl_lines}줄: 권장 400줄(한 패키지)의 3배를 넘음")
        if spec["verification"].get("board") == "pass" and not re.search(r"\d{4}-\d{2}-\d{2}", spec["verification"].get("notes", "")):
            add("error", f"capstone:{spec['slug']}", "board: pass인데 notes에 확인 날짜가 없음 (S3는 사람이 날짜와 함께 기록)")
    return names


def audit_docs(slugs):
    if not DOCS.is_dir():
        add("error", "docs", "docs/ 없음 (build.py 먼저)")
        return 0
    n = 0
    root = DOCS.resolve()
    for f in DOCS.rglob("*.html"):
        n += 1
        parser = Links()
        parser.feed(f.read_text(encoding="utf-8"))
        for ref in parser.refs:
            u = urlsplit(ref)
            if u.scheme or u.netloc or not u.path:
                continue
            target = (f.parent / unquote(u.path)).resolve()
            if not target.is_relative_to(root) or not target.exists():
                add("error", f"docs:{f.relative_to(DOCS)}", f"깨진 링크 {ref}")
    for f in DOCS.rglob("*.svg"):
        n += 1
        try:
            ET.parse(f)
        except ET.ParseError as e:
            add("error", f"docs:{f.relative_to(DOCS)}", f"SVG 파싱 실패 {e}")
    for f in DOCS.rglob("*.json"):
        n += 1
        try:
            json.loads(f.read_text(encoding="utf-8"))
        except ValueError as e:
            add("error", f"docs:{f.relative_to(DOCS)}", f"JSON 파싱 실패 {e}")
    for slug in slugs:
        man = DOCS / slug / "source_manifest.json"
        if not man.exists():
            add("error", f"docs:{slug}", "source_manifest.json 없음")
            continue
        for item in json.loads(man.read_text(encoding="utf-8"))["files"]:
            src = ROOT / "capstones" / slug / item["path"]
            if not src.exists() or hashlib.sha256(src.read_bytes()).hexdigest() != item["sha256"]:
                add("error", f"docs:{slug}", f"매니페스트 해시 불일치 {item['path']} (문서가 낡았다: build.py 다시 실행)")
        conn = DOCS / slug / "connections.json"
        if conn.exists():
            c = json.loads(conn.read_text(encoding="utf-8"))
            ids = {b["id"] for b in c["blocks"]}
            for l in c["links"]:
                if l["from"] not in ids or l["to"] not in ids:
                    add("error", f"docs:{slug}", f"connections.json 끝점 오류 {l['from']}→{l['to']}")
    return n


def audit_ideas(slugs):
    path = ROOT / "inbox" / "ideas.md"
    if not path.exists():
        return 0
    cur, count = None, 0
    for ln in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^##\s+(I-\d+)\s", ln)
        if m:
            cur, count = m.group(1), count + 1
        elif cur and (m := re.match(r"^- 상태:\s*used\s*\(패키지:\s*([\w-]+)", ln)):
            if m.group(1) not in slugs:
                add("error", f"idea:{cur}", f"used인데 패키지 {m.group(1)} 없음")
    return count


def main():
    pol = capcheck.policy()
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "check.py")], capture_output=True, text=True)
    if r.returncode != 0:
        add("error", "cards", "tools/check.py 실패: " + (r.stdout + r.stderr).strip().splitlines()[-1][:200] if (r.stdout + r.stderr).strip() else "tools/check.py 실패")
    ncards = audit_cards(pol)
    slugs = audit_capstones()
    if "--no-build" not in sys.argv:
        b = subprocess.run([sys.executable, str(ROOT / "tools" / "build.py")], capture_output=True, text=True)
        if b.returncode != 0:
            add("error", "build", "tools/build.py 실패")
    ndocs = audit_docs(slugs)
    nideas = audit_ideas(set(slugs))
    summary = {"checked": {"cards": ncards, "capstones": len(slugs), "docs_files": ndocs, "ideas": nideas},
               "errors": sum(f["level"] == "error" for f in findings),
               "warnings": sum(f["level"] == "warn" for f in findings),
               "infos": sum(f["level"] == "info" for f in findings)}
    out = {"schema_version": 1, "time_kst": datetime.now(timezone(timedelta(hours=9))).strftime("%Y-%m-%d %H:%M"),
           "summary": summary, "findings": findings}
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "build" / "audit.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for f in findings:
        tag = {"error": "error", "warn": "warning", "info": "notice"}[f["level"]]
        if f["level"] != "info":
            print(f"::{tag}::{f['scope']}: {f['message']}")
    print(f"감사 완료: 카드 {ncards}, 캡스톤 {len(slugs)}, 문서 파일 {ndocs}, 아이디어 {nideas} | 오류 {summary['errors']}, 경고 {summary['warnings']}, 정보 {summary['infos']}")
    return 1 if summary["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
