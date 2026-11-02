#!/usr/bin/env python3
"""capstones/<slug>/capstone.json 하나에서 세 산출물을 만든다. 표준 라이브러리만 사용.
  1) docs/<slug>/index.html   문서 (계통도, 메모리맵, 기술 트리, 소스, 검증 상태 포함)
  2) docs/<slug>/diagram.svg  계통도 (블록 다이어그램)
  3) 실행 소스는 capstones/<slug>/ 그대로 (명세의 sources 목록과 대조해 존재만 검증)
사용법: python3 tools/build.py [--strict]
"""
import html
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CAPS = ROOT / "capstones"
DOCS = ROOT / "docs"
KIND_COL = {"cpu": 0, "clock": 0, "bus": 1, "periph": 2, "memory": 2, "external": 3}
KIND_LABEL = {"cpu": "마스터", "clock": "클럭", "bus": "버스", "periph": "주변장치", "memory": "메모리", "external": "외부"}
STATE_LABEL = {"pass": "통과", "fail": "실패", "skipped": "건너뜀", "not-run": "미실행"}
esc = html.escape


def card_names():
    return {p.stem for p in (ROOT / "catalog").rglob("*.md") if p.name != "_index.md"}


def validate(spec, cap_dir):
    errs, warns = [], []
    ids = [b["id"] for b in spec["architecture"]["blocks"]]
    if len(ids) != len(set(ids)):
        errs.append("블록 id 중복")
    for l in spec["architecture"]["links"]:
        for end in (l["from"], l["to"]):
            if end not in ids:
                errs.append(f"링크가 없는 블록을 참조: {end}")
    for group, files in spec["sources"].items():
        for f in files:
            if not (cap_dir / f).exists():
                errs.append(f"sources.{group}: 파일 없음 {f}")
    for b in spec["architecture"]["blocks"]:
        if b.get("file") and not (cap_dir / b["file"]).exists():
            errs.append(f"블록 {b['id']}: 파일 없음 {b['file']}")
    bases = []
    for m in spec["memory_map"]:
        base = int(m["base"].replace("_", ""), 16)
        size = int(m["size"].replace("_", ""), 16)
        if m["block"] not in ids:
            errs.append(f"memory_map: 없는 블록 {m['block']}")
        for other in bases:
            if base < other[0] + other[1] and other[0] < base + size:
                errs.append(f"memory_map: 주소 겹침 {m['block']}")
        bases.append((base, size))
        for r in m["regs"]:
            if int(r["off"], 16) >= size:
                errs.append(f"memory_map: 오프셋이 영역 밖 {m['block']}.{r['name']}")
    known = card_names()
    for ref in spec.get("references", []) + [r for step in spec.get("roadmap", []) for r in ({"card": c} for c in step["refs"])]:
        if ref["card"] not in known:
            warns.append(f"카드 미작성: {ref['card']}")
    return errs, sorted(set(warns))


def diagram_svg(spec):
    blocks = spec["architecture"]["blocks"]
    W, H, GX, GY, X0, Y0 = 176, 58, 250, 82, 24, 34
    rows = {}
    pos = {}
    for b in blocks:
        col = 0 if b.get("side") == "in" else KIND_COL.get(b["kind"], 2)
        row = rows.get(col, 0)
        rows[col] = row + 1
        pos[b["id"]] = (X0 + col * GX, Y0 + row * GY, col)
    width = X0 * 2 + 3 * GX + W
    height = Y0 + max(rows.values()) * GY + 10
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img" aria-label="블록 다이어그램">',
           '<defs><marker id="ar" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="arrow"/></marker></defs>']
    for col, label in ((0, "클럭·입력·마스터"), (1, "버스"), (2, "주변장치"), (3, "외부")):
        out.append(f'<text x="{X0 + col * GX}" y="16" class="colhead">{label}</text>')
    for l in spec["architecture"]["links"]:
        x1, y1, c1 = pos[l["from"]]
        x2, y2, c2 = pos[l["to"]]
        if c1 < c2:
            sx, sy, ex, ey = x1 + W, y1 + H / 2, x2, y2 + H / 2
            mx = (sx + ex) / 2
            d = f"M{sx},{sy} C{mx},{sy} {mx},{ey} {ex},{ey}"
            lx, ly = mx, (sy + ey) / 2 - 7
        elif c1 > c2:
            sx, sy, ex, ey = x1, y1 + H / 2, x2 + W, y2 + H / 2
            ctrl = min(y1, y2) - 26
            d = f"M{sx},{sy} C{sx - 60},{ctrl} {ex + 60},{ctrl} {ex},{ey}"
            lx, ly = (sx + ex) / 2, ctrl + 8
        else:
            sx, sy, ex, ey = x1 + W / 2, y1 + H, x2 + W / 2, y2
            d = f"M{sx},{sy} L{ex},{ey}"
            lx, ly = sx + 6, (sy + ey) / 2
        out.append(f'<path d="{d}" class="link" marker-end="url(#ar)"/>')
        out.append(f'<text x="{lx}" y="{ly}" class="lbl" text-anchor="middle">{esc(l["label"])}</text>')
    for b in blocks:
        x, y, _ = pos[b["id"]]
        out.append(f'<g class="k-{esc(b["kind"])}"><rect x="{x}" y="{y}" width="{W}" height="{H}" rx="8"/>'
                   f'<text x="{x + W / 2}" y="{y + 24}" text-anchor="middle" class="bname">{esc(b["name"])}</text>'
                   f'<text x="{x + W / 2}" y="{y + 42}" text-anchor="middle" class="bdesc">{esc(b.get("short") or b.get("desc", ""))[:24]}</text></g>')
    out.append("</svg>")
    return "\n".join(out)


SVG_CSS = """
.colhead{font:600 11px sans-serif;fill:var(--muted)}
.link{fill:none;stroke:var(--line);stroke-width:1.5}.arrow{fill:var(--line)}
.lbl{font:11px sans-serif;fill:var(--muted)}
.bname{font:600 13px sans-serif;fill:var(--text)}.bdesc{font:11px sans-serif;fill:var(--muted)}
.k-cpu rect{fill:var(--c-cpu);stroke:var(--c-cpu-s)}.k-bus rect{fill:var(--c-bus);stroke:var(--c-bus-s)}
.k-periph rect,.k-memory rect{fill:var(--c-per);stroke:var(--c-per-s)}
.k-external rect{fill:var(--c-ext);stroke:var(--c-ext-s);stroke-dasharray:4 3}
.k-clock rect{fill:var(--c-clk);stroke:var(--c-clk-s)}
"""

PAGE_CSS = """
:root{--bg:#fafaf8;--panel:#fff;--text:#1d1d1b;--muted:#6a6a64;--line:#8a8a82;--bd:#e2e1dc;--accent:#2a5bd7;
--c-cpu:#e6edfc;--c-cpu-s:#2a5bd7;--c-bus:#f3ecd9;--c-bus-s:#a7791a;--c-per:#e3f2e6;--c-per-s:#2f7d46;--c-ext:#f4f4f1;--c-ext-s:#8a8a82;--c-clk:#f6e6ee;--c-clk-s:#b03a6b;
--ok:#1f7a3d;--bad:#b3261e;--warn:#946200;--code:#f1f0ec}
@media (prefers-color-scheme: dark){:root:not([data-theme="light"]){--bg:#161615;--panel:#1f1f1d;--text:#ecebe6;--muted:#a3a29b;--line:#8d8c85;--bd:#34332f;--accent:#7ea2ff;
--c-cpu:#1d2740;--c-cpu-s:#7ea2ff;--c-bus:#35301f;--c-bus-s:#d3a640;--c-per:#1c3223;--c-per-s:#6ac389;--c-ext:#262624;--c-ext-s:#8d8c85;--c-clk:#3a2230;--c-clk-s:#e17aa6;
--ok:#6ac389;--bad:#ff8a80;--warn:#e6b84d;--code:#262624}}
*{box-sizing:border-box}a{color:var(--accent)}body{margin:0;background:var(--bg);color:var(--text);font:16px/1.65 system-ui,-apple-system,"Noto Sans KR",sans-serif}
main{max-width:980px;margin:0 auto;padding:28px 16px 64px}
h1{font-size:1.7rem;line-height:1.3;margin:.2em 0}h2{font-size:1.2rem;margin:2.2em 0 .6em;padding-top:.6em;border-top:1px solid var(--bd)}
h3{font-size:1rem;margin:1.4em 0 .4em}p{margin:.5em 0}.muted{color:var(--muted)}
nav{display:flex;flex-wrap:wrap;gap:6px 14px;margin:14px 0 0;font-size:.9rem}nav a{text-decoration:none}
.panel{background:var(--panel);border:1px solid var(--bd);border-radius:10px;padding:14px 16px;overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:.92rem}th,td{border-bottom:1px solid var(--bd);padding:7px 10px;text-align:left;vertical-align:top}th{font-weight:600;color:var(--muted)}
code,pre{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.85rem}pre{background:var(--code);border-radius:8px;padding:12px 14px;overflow:auto;margin:.4em 0}
code{background:var(--code);padding:1px 5px;border-radius:4px}
.badges{display:flex;flex-wrap:wrap;gap:8px;margin:10px 0}.badge{border:1px solid var(--bd);border-radius:999px;padding:3px 12px;font-size:.85rem;background:var(--panel)}
.b-pass{color:var(--ok);border-color:var(--ok)}.b-fail{color:var(--bad);border-color:var(--bad)}.b-skipped,.b-not-run{color:var(--warn);border-color:var(--warn)}
ul{padding-left:1.25em}li{margin:.2em 0}details{margin:.5em 0}summary{cursor:pointer;font-weight:600}
.tree,.tree ul{list-style:none;padding-left:1.1em;border-left:1px dashed var(--bd)}.tree{border-left:0;padding-left:0}
.step{display:flex;gap:10px;align-items:baseline}.tag{font:600 .75rem ui-monospace,monospace;border:1px solid var(--bd);border-radius:4px;padding:1px 6px}
.s-current{color:var(--accent);border-color:var(--accent)}.s-done{color:var(--ok);border-color:var(--ok)}
svg{width:100%;height:auto;min-width:640px}
@media (max-width:640px){main{padding:18px 16px 48px}}
"""


def hier_html(node):
    f = f' <span class="muted">({esc(node["file"])})</span>' if node.get("file") else ""
    kids = "".join(hier_html(c) for c in node.get("children", []))
    return f'<li><code>{esc(node["module"])}</code>{f}' + (f"<ul>{kids}</ul>" if kids else "") + "</li>"


def merged_verification(spec, cap_dir):
    v = {k: {"result": spec["verification"].get(k, "not-run"), "detail": ""} for k in ("lint", "sim", "synth", "board")}
    st = cap_dir / "build" / "status.json"
    if st.exists():
        data = json.loads(st.read_text(encoding="utf-8"))
        for k in ("lint", "sim", "synth"):
            if k in data:
                v[k] = data[k]
        v["_date"] = data.get("date", "")
    return v


def build_one(spec_path):
    cap_dir = spec_path.parent
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    errs, warns = validate(spec, cap_dir)
    out_dir = DOCS / spec["slug"]
    out_dir.mkdir(parents=True, exist_ok=True)
    svg = diagram_svg(spec)
    (out_dir / "diagram.svg").write_text(
        svg.replace("<defs>", f"<style>{SVG_CSS_STANDALONE}</style><defs>", 1), encoding="utf-8")
    ver = merged_verification(spec, cap_dir)
    badge = lambda label, k: f'<span class="badge b-{ver[k]["result"]}">{label}: {STATE_LABEL.get(ver[k]["result"], ver[k]["result"])}' + (f' ({esc(ver[k]["detail"])})' if ver[k]["detail"] else "") + "</span>"
    cards = {p.stem: p.relative_to(ROOT).as_posix() for p in (ROOT / "catalog").rglob("*.md") if p.name != "_index.md"}
    ref_li = lambda c, why="": f'<li><code>{esc(c)}</code>' + (f' — {esc(why)}' if why else "") + ("" if c in cards else ' <span class="muted">(카드 미작성)</span>') + "</li>"

    blocks_by_id = {b["id"]: b for b in spec["architecture"]["blocks"]}
    mm = ""
    for m in spec["memory_map"]:
        b = blocks_by_id[m["block"]]
        mm += f'<h3>{esc(b["name"])} <code>{esc(m["base"])}</code> <span class="muted">크기 {esc(m["size"])}</span></h3><div class="panel"><table><tr><th>오프셋</th><th>이름</th><th>접근</th><th>설명</th></tr>'
        mm += "".join(f'<tr><td><code>{esc(r["off"])}</code></td><td>{esc(r["name"])}</td><td>{esc(r["access"])}</td><td>{esc(r["desc"])}</td></tr>' for r in m["regs"]) + "</table></div>"

    sig = "".join(f'<tr><td><code>{esc(s["name"])}</code></td><td>{esc(s["dir"])}</td><td>{esc(s["desc"])}</td></tr>' for s in spec["bus_protocol"]["signals"])
    road = "".join(
        f'<li class="step"><span class="tag s-{esc(r["state"])}">{esc(r["stage"])}</span><span>{esc(r["title"])}'
        + (" <span class='muted'>참고: " + ", ".join(esc(c) for c in r["refs"]) + "</span>" if r["refs"] else "") + "</span></li>"
        for r in spec["roadmap"])
    src_html = ""
    for group, files in spec["sources"].items():
        for f in files:
            body = (cap_dir / f).read_text(encoding="utf-8")
            src_html += f'<details><summary><code>{esc(f)}</code> <span class="muted">{len(body.splitlines())}줄</span></summary><pre>{esc(body)}</pre></details>'
    howto = "".join(f'<h3>{esc(h["title"])}</h3><ol>' + "".join(f"<li>{esc(s)}</li>" for s in h["steps"]) + "</ol>" for h in spec["howto"])
    ul = lambda xs: "<ul>" + "".join(f"<li>{esc(x)}</li>" for x in xs) + "</ul>"
    ver_date = f' · 기준 {esc(ver["_date"])}' if ver.get("_date") else ""

    page = f"""<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(spec["title"])}</title><style>{PAGE_CSS}{SVG_CSS}</style></head><body><main>
<p class="muted">캡스톤 패키지 · {esc(spec["board"])} · 단계 {esc(spec["stage"])}</p>
<h1>{esc(spec["title"])}</h1><p>{esc(spec["summary"])}</p>
<div class="badges">{badge("린트", "lint")}{badge("시뮬레이션", "sim")}{badge("합성", "synth")}{badge("보드", "board")}</div>
<p class="muted">검증 상태는 실행 기록이 있을 때만 표시한다{ver_date}. 기록이 없으면 '미실행'이다.</p>
<nav><a href="#goal">목표</a><a href="#arch">계통도</a><a href="#hier">모듈 계층</a><a href="#map">메모리맵</a><a href="#road">기술 트리</a><a href="#src">실행 소스</a><a href="#verify">검증</a><a href="#ref">참고·위험</a></nav>
<h2 id="goal">1. 목표와 범위</h2><h3>목표</h3>{ul(spec["goals"])}<h3>범위 밖</h3>{ul(spec["non_goals"])}<p class="muted">{esc(spec["author_note"])}</p>
<h2 id="arch">2. 계통도</h2><p>클럭: {esc(spec["architecture"]["clock"])}</p><div class="panel">{svg}</div>
<p class="muted"><a href="diagram.svg">diagram.svg</a>로 따로 받을 수 있다.</p>
<h3>버스 규약: {esc(spec["bus_protocol"]["name"])}</h3><div class="panel"><table><tr><th>신호</th><th>방향</th><th>설명</th></tr>{sig}</table></div><p>{esc(spec["bus_protocol"]["note"])}</p>
<h2 id="hier">3. 모듈 계층</h2><div class="panel"><ul class="tree">{hier_html(spec["hierarchy"])}</ul></div>
<h2 id="map">4. 메모리맵</h2>{mm}
<h2 id="road">5. 기술 트리 (이 캡스톤의 확장 경로)</h2><div class="panel"><ul style="list-style:none;padding:0">{road}</ul></div>
<h2 id="src">6. 실행 소스</h2><p>저장소의 <code>capstones/{esc(spec["slug"])}/</code>에 있는 파일 그대로다. 이 문서는 파일에서 읽어 넣은 것이므로 항상 일치한다.</p>{src_html}{howto}
<h2 id="verify">7. 검증</h2><div class="panel"><table><tr><th>단계</th><th>결과</th><th>내용</th></tr>
{"".join(f'<tr><td>{n}</td><td>{esc(STATE_LABEL.get(ver[k]["result"], ver[k]["result"]))}</td><td>{esc(ver[k]["detail"])}</td></tr>' for n, k in (("린트(verilator)", "lint"), ("시뮬레이션(iverilog)", "sim"), ("합성 추정(yosys)", "synth"), ("보드 동작", "board")))}
</table></div><p>{esc(spec["verification"]["notes"])}</p>
<h2 id="ref">8. 참고 카드와 위험</h2><h3>참고 카드</h3><ul>{"".join(ref_li(r["card"], r["why"]) for r in spec["references"])}</ul><h3>위험·한계</h3>{ul(spec["risks"])}
</main></body></html>"""
    (out_dir / "index.html").write_text(page, encoding="utf-8")
    return spec, errs, warns, ver


SVG_CSS_STANDALONE = (":root{--muted:#6a6a64;--line:#8a8a82;--text:#1d1d1b;--c-cpu:#e6edfc;--c-cpu-s:#2a5bd7;--c-bus:#f3ecd9;--c-bus-s:#a7791a;--c-per:#e3f2e6;--c-per-s:#2f7d46;--c-ext:#f4f4f1;--c-ext-s:#8a8a82;--c-clk:#f6e6ee;--c-clk-s:#b03a6b}"
                      "@media (prefers-color-scheme: dark){:root{--muted:#a3a29b;--line:#8d8c85;--text:#ecebe6;--c-cpu:#1d2740;--c-cpu-s:#7ea2ff;--c-bus:#35301f;--c-bus-s:#d3a640;--c-per:#1c3223;--c-per-s:#6ac389;--c-ext:#262624;--c-ext-s:#8d8c85;--c-clk:#3a2230;--c-clk-s:#e17aa6}}" + SVG_CSS)


def main():
    strict = "--strict" in sys.argv
    index = []
    failed = False
    for spec_path in sorted(CAPS.glob("*/capstone.json")):
        if spec_path.parent.name.startswith("_"):
            continue
        spec, errs, warns, ver = build_one(spec_path)
        for e in errs:
            print(f"오류 {spec['slug']}: {e}")
        for w in warns:
            print(f"경고 {spec['slug']}: {w}")
        failed |= bool(errs) or (strict and bool(warns))
        index.append((spec, ver))
        print(f"docs/{spec['slug']}/index.html, diagram.svg 생성")
    rows = "".join(
        f'<tr><td><a href="{esc(s["slug"])}/index.html">{esc(s["title"])}</a></td><td>{esc(s["board"])}</td><td>{esc(s["stage"])}</td>'
        f'<td>{" / ".join(STATE_LABEL.get(v[k]["result"], v[k]["result"]) for k in ("lint", "sim", "synth", "board"))}</td></tr>' for s, v in index)
    (DOCS / "index.html").write_text(
        f'<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>FPGA SoC 캡스톤 목록</title><style>{PAGE_CSS}</style></head>'
        f'<body><main><h1>FPGA SoC 캡스톤 패키지</h1><p class="muted">문서, 계통도, 실행 소스가 한 명세에서 생성된다.</p><div class="panel"><table>'
        f'<tr><th>캡스톤</th><th>보드</th><th>단계</th><th>린트 / 시뮬 / 합성 / 보드</th></tr>{rows}</table></div></main></body></html>', encoding="utf-8")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
