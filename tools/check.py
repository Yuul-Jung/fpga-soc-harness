#!/usr/bin/env python3
"""catalog/ 카드와 _index.md를 HARNESS.md 규칙에 맞게 점검한다. 표준 라이브러리만 사용."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "catalog"
REQUIRED = ["name", "url", "source_type", "vendor", "board", "fit_basys3", "cpu",
            "language", "bus", "peripherals", "stage", "license", "doc_language",
            "verification", "checked_at", "sources"]
ENUMS = {
    "source_type": {"repo", "paper", "course", "report", "article"},
    "vendor": {"amd", "intel", "lattice", "neutral"},
    "fit_basys3": {"yes", "needs-port", "no", "unknown"},
    "doc_language": {"ko", "en"},
    "verification": {"L2", "L3"},  # L1/L0는 카드 금지
}
EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
QUOTE = re.compile(r'"([^"\n]+)"|“([^”\n]+)”')

errors, warnings = [], []


def parse_frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None, text
    fields = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith((" ", "#")):
            k, v = line.split(":", 1)
            fields[k.strip()] = v.split("#")[0].strip()
    return fields, text[m.end():]


def main():
    cards = [p for p in CATALOG.rglob("*.md") if p.name != "_index.md"]
    index_text = (CATALOG / "_index.md").read_text(encoding="utf-8") if (CATALOG / "_index.md").exists() else ""
    if not index_text:
        errors.append("catalog/_index.md 없음")
    seen_urls = {}
    for p in sorted(cards):
        rel = p.relative_to(ROOT)
        text = p.read_text(encoding="utf-8")
        fm, body = parse_frontmatter(text)
        if fm is None:
            errors.append(f"{rel}: frontmatter 없음")
            continue
        for k in REQUIRED:
            if not fm.get(k):
                errors.append(f"{rel}: 필수 필드 누락 '{k}' (모르면 unverified: 사유)")
        for k, allowed in ENUMS.items():
            if fm.get(k) and fm[k] not in allowed:
                errors.append(f"{rel}: {k}='{fm[k]}' 허용값 아님 {sorted(allowed)}")
        if fm.get("stage") and not re.fullmatch(r"T[0-5](-T?[0-5])?", fm["stage"]):
            errors.append(f"{rel}: stage='{fm['stage']}' 형식 오류 (T0~T5)")
        if fm.get("checked_at") and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", fm["checked_at"]):
            errors.append(f"{rel}: checked_at 날짜 형식 오류")
        if fm.get("verification") == "L3" and fm.get("sources") in (None, "", "[]"):
            errors.append(f"{rel}: L3인데 sources 비어 있음")
        if fm.get("name") and fm["name"] != p.stem:
            errors.append(f"{rel}: name과 파일명 불일치")
        if fm.get("name") and fm["name"] not in index_text:
            errors.append(f"{rel}: _index.md에 반영되지 않음")
        url = fm.get("url")
        if url:
            if url in seen_urls:
                errors.append(f"{rel}: url 중복 ({seen_urls[url]})")
            seen_urls[url] = rel
        if EMAIL.search(text):
            errors.append(f"{rel}: 이메일 주소 포함 (개인정보 최소화 원칙)")
        for m in QUOTE.finditer(body):
            q = m.group(1) or m.group(2)
            if len(q.split()) >= 15:
                warnings.append(f"{rel}: 15단어 이상 인용 의심: {q[:30]}…")
    for name in ("atlas", "soc-map", "devices"):
        for p in (ROOT / name).rglob("*.md"):
            if EMAIL.search(p.read_text(encoding="utf-8")):
                errors.append(f"{p.relative_to(ROOT)}: 이메일 주소 포함")
    print(f"카드 {len(cards)}건 점검")
    for w in warnings:
        print("경고:", w)
    for e in errors:
        print("오류:", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
