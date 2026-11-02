#!/usr/bin/env python3
"""capstones/<slug>/capstone.json 하나에서 세 산출물을 만든다. 표준 라이브러리만 사용.
  1) docs/<slug>/index.html   문서 (계통도, 메모리맵, 기술 트리, 소스, 검증 상태 포함)
  2) docs/<slug>/diagram.svg  계통도 (블록 다이어그램)
  3) 실행 소스는 capstones/<slug>/ 그대로 (명세의 sources 목록과 대조해 존재만 검증)
  4) docs/index.html          메인 허브 (캡스톤 목록, 기술 트리, 수집 현황, 아이디어, 최근 활동)
  5) docs/<repo 경로>.html    catalog, atlas, soc-map, inbox/ideas, HARNESS.md를 HTML로 옮긴 사본 (경로 구조 동일)
사용법: python3 tools/build.py [--strict]
"""
import html
import json
import os
import re
import sys
import zipfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import capcheck  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
CAPS = ROOT / "capstones"
DOCS = ROOT / "docs"
KIND_COL = {"cpu": 0, "clock": 0, "bus": 1, "periph": 2, "memory": 2, "external": 3}
KIND_LABEL = {"cpu": "마스터", "clock": "클럭", "bus": "버스", "periph": "주변장치", "memory": "메모리", "external": "외부"}
STATE_LABEL = {"pass": "통과", "fail": "실패", "skipped": "건너뜀", "not-run": "미실행"}
esc = html.escape
REPO_URL = "https://github.com/Yuul-Jung/fpga-soc-harness"


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
    for fn in (capcheck.check_integration, capcheck.check_external_parts):
        e, w = fn(spec)
        errs += e
        warns += w
    e, w = capcheck.check_code_names(spec, cap_dir)
    errs += e
    warns += w
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
header.top{display:flex;flex-wrap:wrap;gap:6px 18px;align-items:baseline;max-width:980px;margin:0 auto;padding:14px 16px 0;font-size:.92rem}
header.top .brand{font-weight:700;color:var(--text);text-decoration:none}
.cards{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px;margin:10px 0}
.cap{background:var(--panel);border:1px solid var(--bd);border-radius:10px;padding:14px 16px;display:flex;flex-direction:column;gap:8px}
.cap h3{margin:0;font-size:1.05rem}.cap img{width:100%;height:auto;border:1px solid var(--bd);border-radius:8px;background:var(--bg)}
.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:10px;margin:14px 0}
.stat{background:var(--panel);border:1px solid var(--bd);border-radius:10px;padding:10px 14px}.stat b{display:block;font-size:1.5rem;line-height:1.2}
.stages{display:grid;grid-template-columns:repeat(auto-fit,minmax(125px,1fr));gap:10px}
.stage{border:1px solid var(--bd);border-radius:10px;padding:10px 12px;background:var(--panel);font-size:.9rem}.stage h4{margin:0 0 6px;font-size:.95rem}
.stage .plan{color:var(--muted);border-top:1px dashed var(--bd);margin-top:6px;padding-top:6px}
.md td.nw,.md th:first-child{white-space:nowrap}.md h1{font-size:1.5rem}.md table{margin:.8em 0}.md li>ul{margin:.2em 0}
.fm{font-size:.85rem}.fm td:first-child{color:var(--muted);white-space:nowrap}
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
    (out_dir / "connections.json").write_text(json.dumps(capcheck.connections_json(spec), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (out_dir / "bom.csv").write_text(capcheck.bom_csv(spec), encoding="utf-8")
    (out_dir / "source_manifest.json").write_text(json.dumps(capcheck.source_manifest(spec, cap_dir), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (out_dir / "verification.json").write_text(json.dumps({
        "schema_version": 1, "slug": spec["slug"], "stage": spec["stage"],
        "lint": ver["lint"], "sim": ver["sim"], "synth": ver["synth"],
        "board": {"result": spec["verification"].get("board", "not-run"), "detail": "사람이 확인한 항목만 pass. 에이전트는 pass로 쓰지 않는다(HARNESS §13.4)"},
        "synth_note": "yosys 추정이다. Vivado의 LUT/FF/WNS와 다를 수 있다.",
        "recorded": ver.get("_date", "")}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    zip_path = out_dir / f'{spec["slug"]}.zip'
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(cap_dir.rglob("*")):
            if f.is_file() and "build" not in f.relative_to(cap_dir).parts:
                z.write(f, f"{spec['slug']}/{f.relative_to(cap_dir).as_posix()}")
    clink = lambda c: (f'<a href="../{esc(cards[c][:-3])}.html"><code>{esc(c)}</code></a>' if c in cards else f'<code>{esc(c)}</code>')
    ref_li = lambda c, why="": f'<li>{clink(c)}' + (f' — {esc(why)}' if why else "") + ("" if c in cards else ' <span class="muted">(카드 미작성)</span>') + "</li>"

    blocks_by_id = {b["id"]: b for b in spec["architecture"]["blocks"]}
    mm = ""
    for m in spec["memory_map"]:
        b = blocks_by_id[m["block"]]
        mm += f'<h3>{esc(b["name"])} <code>{esc(m["base"])}</code> <span class="muted">크기 {esc(m["size"])}</span></h3><div class="panel"><table><tr><th>오프셋</th><th>이름</th><th>접근</th><th>설명</th></tr>'
        mm += "".join(f'<tr><td><code>{esc(r["off"])}</code></td><td>{esc(r["name"])}</td><td>{esc(r["access"])}</td><td>{esc(r["desc"])}</td></tr>' for r in m["regs"]) + "</table></div>"

    integ = spec.get("integration", {})
    amap = capcheck.address_map()
    compat_label = {"compatible": "적합", "partial": "부분 적합", "incompatible": "적합하지 않음"}.get(integ.get("compat"), "미선언")
    integ_html = (f'<div class="panel"><table><tr><th style="white-space:nowrap">버스</th><td><code>{esc(integ.get("bus", ""))}</code></td></tr>'
                  f'<tr><th style="white-space:nowrap">주소맵</th><td><code>{esc(integ.get("address_map", ""))}</code> → 동결 맵 <code>{esc(amap["name"])}</code> 적합 여부: <b>{esc(compat_label)}</b></td></tr>'
                  f'<tr><th style="white-space:nowrap">이식 계획</th><td>{esc(integ.get("plan", ""))}</td></tr></table></div>')
    if integ.get("compat") != "compatible":
        integ_html = '<p class="badge b-fail">이 패키지는 MicroBlaze V 동결 주소맵과 호환되지 않는다 (파일럿). 아래 이식 계획을 따라야 SoC에 합칠 수 있다.</p>' + integ_html
    ext_rows = "".join(
        f'<tr><td><code>{esc(p["id"])}</code></td><td>{esc(p["name"])}</td><td>{esc(p["interface"])}</td><td style="white-space:nowrap">{esc(str(p["io_voltage"]))} V</td>'
        f'<td style="white-space:nowrap">{"보드 내장" if p["board_resident"] else "외부 모듈"}</td><td>{esc(p.get("level_shift", "") or "불필요 (3.3V)")}</td><td>{esc(p.get("notes", ""))}</td></tr>'
        for p in spec.get("external_parts", []))
    sch = spec.get("schematic", {"state": "not-written", "note": ""})
    sch_html = (f'<p class="badge b-{"pass" if sch["state"] != "not-written" else "skipped"}">전기 회로도: {"미작성" if sch["state"] == "not-written" else esc(sch["state"])}</p>'
                f'<p class="muted">{esc(sch.get("note", ""))}</p>')
    sig = "".join(f'<tr><td><code>{esc(s["name"])}</code></td><td>{esc(s["dir"])}</td><td>{esc(s["desc"])}</td></tr>' for s in spec["bus_protocol"]["signals"])
    road = "".join(
        f'<li class="step"><span class="tag s-{esc(r["state"])}">{esc(r["stage"])}</span><span>{esc(r["title"])}'
        + (" <span class='muted'>참고: " + ", ".join(clink(c) for c in r["refs"]) + "</span>" if r["refs"] else "") + "</span></li>"
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
<title>{esc(spec["title"])}</title><style>{PAGE_CSS}{SVG_CSS}</style></head><body>{topnav("../")}<main>
<p class="muted">캡스톤 패키지 · {esc(spec["board"])} · 단계 {esc(spec["stage"])}</p>
<h1>{esc(spec["title"])}</h1><p>{esc(spec["summary"])}</p>
<div class="badges">{badge("린트", "lint")}{badge("시뮬레이션", "sim")}{badge("합성", "synth")}{badge("보드", "board")}</div>
{'<p class="badge b-fail">이 패키지는 CI에서 실패한 상태(broken)다. 다음 사이클이 먼저 고친다.</p>' if spec.get("status") == "broken" else ""}<p class="muted">검증 상태는 실행 기록이 있을 때만 표시한다{ver_date}. 기록이 없으면 '미실행'이다.</p>
<nav><a href="#goal">목표</a><a href="#arch">계통도</a><a href="#hier">모듈 계층</a><a href="#map">메모리맵</a><a href="#ext">외부 부품·전기</a><a href="#road">기술 트리</a><a href="#src">실행 소스</a><a href="#verify">검증</a><a href="#ref">참고·위험</a></nav>
<h2 id="goal">1. 목표와 범위</h2><h3>목표</h3>{ul(spec["goals"])}<h3>범위 밖</h3>{ul(spec["non_goals"])}<p class="muted">{esc(spec["author_note"])}</p>
<h2 id="arch">2. 계통도</h2><p>클럭: {esc(spec["architecture"]["clock"])}</p><div class="panel">{svg}</div>
<p class="muted"><a href="diagram.svg">diagram.svg</a>로 따로 받을 수 있다.</p>
<h3>버스 규약: {esc(spec["bus_protocol"]["name"])}</h3><div class="panel"><table><tr><th>신호</th><th>방향</th><th>설명</th></tr>{sig}</table></div><p>{esc(spec["bus_protocol"]["note"])}</p>
<h3>통합 선언 (SoC 적합성)</h3>{integ_html}
<h2 id="hier">3. 모듈 계층</h2><div class="panel"><ul class="tree">{hier_html(spec["hierarchy"])}</ul></div>
<h2 id="map">4. 메모리맵</h2>{mm}
<h2 id="ext">5. 외부 부품과 전기 회로도</h2><p class="muted">2절의 계통도는 <b>디지털 모듈 연결도</b>다. 전압, 풀업, 커넥터 배선 같은 전기 사항은 이 절에서 따로 다룬다. 기계가 읽는 사본: <a href="bom.csv">bom.csv</a> · <a href="connections.json">connections.json</a></p>{sch_html}<div class="panel"><table><tr><th>id</th><th>부품</th><th>인터페이스</th><th>신호 전압</th><th>구분</th><th>레벨 변환</th><th>비고</th></tr>{ext_rows}</table></div><p class="muted">Basys3 FPGA 핀은 3.3V 신호만 직접 받는다. 5V·12V·모터·릴레이는 직결하지 않는다.</p>
<h2 id="road">6. 기술 트리 (이 캡스톤의 확장 경로)</h2><div class="panel"><ul style="list-style:none;padding:0">{road}</ul></div>
<h2 id="src">7. 실행 소스</h2><p>저장소의 <code>capstones/{esc(spec["slug"])}/</code>에 있는 파일 그대로다. 이 문서는 파일에서 읽어 넣은 것이므로 항상 일치한다. <a href="{esc(spec["slug"])}.zip">소스 전체 내려받기 (.zip)</a> · <a href="{REPO_URL}/tree/main/capstones/{esc(spec["slug"])}">GitHub에서 보기</a></p>{src_html}{howto}
<h2 id="verify">8. 검증</h2><div class="panel"><table><tr><th>단계</th><th>결과</th><th>내용</th></tr>
{"".join(f'<tr><td>{n}</td><td>{esc(STATE_LABEL.get(ver[k]["result"], ver[k]["result"]))}</td><td>{esc(ver[k]["detail"])}</td></tr>' for n, k in (("린트(verilator)", "lint"), ("시뮬레이션(iverilog)", "sim"), ("합성 추정(yosys)", "synth"), ("보드 동작", "board")))}
</table></div><p>{esc(spec["verification"]["notes"])}</p>
<h2 id="ref">9. 참고 카드와 위험</h2><h3>참고 카드</h3><ul>{"".join(ref_li(r["card"], r["why"]) for r in spec["references"])}</ul><h3>위험·한계</h3>{ul(spec["risks"])}
</main></body></html>"""
    (out_dir / "index.html").write_text(page, encoding="utf-8")
    return spec, errs, warns, ver


SVG_CSS_STANDALONE = (":root{--muted:#6a6a64;--line:#8a8a82;--text:#1d1d1b;--c-cpu:#e6edfc;--c-cpu-s:#2a5bd7;--c-bus:#f3ecd9;--c-bus-s:#a7791a;--c-per:#e3f2e6;--c-per-s:#2f7d46;--c-ext:#f4f4f1;--c-ext-s:#8a8a82;--c-clk:#f6e6ee;--c-clk-s:#b03a6b}"
                      "@media (prefers-color-scheme: dark){:root{--muted:#a3a29b;--line:#8d8c85;--text:#ecebe6;--c-cpu:#1d2740;--c-cpu-s:#7ea2ff;--c-bus:#35301f;--c-bus-s:#d3a640;--c-per:#1c3223;--c-per-s:#6ac389;--c-ext:#262624;--c-ext-s:#8d8c85;--c-clk:#3a2230;--c-clk-s:#e17aa6}}" + SVG_CSS)


# ---------- 사이트 공통 ----------
def topnav(root):
    links = [("메인", f"{root}index.html"), ("캡스톤", f"{root}index.html#capstones"), ("기술 트리", f"{root}soc-map/tech-tree.html"),
             ("카탈로그", f"{root}catalog/index.html"), ("아이디어", f"{root}inbox/ideas.html"), ("지침", f"{root}harness.html"), ("GitHub", REPO_URL)]
    return '<header class="top"><a class="brand" href="%sindex.html">FPGA SoC 하네스</a>%s</header>' % (
        root, "".join(f'<a href="{h}">{esc(t)}</a>' for t, h in links))


def kst_now():
    return datetime.now(timezone(timedelta(hours=9))).strftime("%Y-%m-%d %H:%M KST")


def split_frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}, text
    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith((" ", "#")):
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()
    return fm, text[m.end():]


CARD_PATHS = {}   # 카드 name -> 저장소 상대 경로(.md)


def md_inline(text, page_rel):
    """page_rel: 이 페이지의 저장소 상대 경로(.md). 링크는 같은 구조의 .html로 바꾼다."""
    page_dir = os.path.dirname(page_rel)
    t = esc(text)

    def to_html_link(href):
        if re.match(r"^(https?:|#|mailto:)", href):
            return href
        h = href[:-3] + ".html" if href.endswith(".md") else href
        return h.replace("_index.html", "index.html")

    def code(m):
        c = m.group(1)
        name = html.unescape(c)
        if name in CARD_PATHS:
            rel = os.path.relpath(CARD_PATHS[name][:-3] + ".html", page_dir or ".").replace(os.sep, "/")
            return f'<a href="{rel}"><code>{c}</code></a>'
        return f"<code>{c}</code>"
    t = re.sub(r"`([^`]+)`", code, t)
    t = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", lambda m: f'<a href="{to_html_link(html.unescape(m.group(2)))}">{m.group(1)}</a>', t)
    return autolink_cards(t, page_dir)


def autolink_cards(t, page_dir):
    """링크·코드 밖의 텍스트에 나오는 카드 name을 카드 페이지로 연결한다."""
    if not CARD_PATHS:
        return t
    names = sorted(CARD_PATHS, key=len, reverse=True)
    pat = re.compile(r"(?<![\w-])(" + "|".join(re.escape(n) for n in names) + r")(?![\w-])")
    parts = re.split(r"(<[^>]+>)", t)
    depth = 0
    out = []
    for part in parts:
        if part.startswith("<"):
            if re.match(r"<(a|code)\b", part):
                depth += 1
            elif re.match(r"</(a|code)>", part):
                depth -= 1
            out.append(part)
        elif depth == 0:
            out.append(pat.sub(lambda m: '<a href="%s">%s</a>' % (os.path.relpath(CARD_PATHS[m.group(1)][:-3] + ".html", page_dir or ".").replace(os.sep, "/"), m.group(1)), part))
        else:
            out.append(part)
    return "".join(out)


def md_to_html(text, page_rel):
    lines = text.splitlines()
    out, i = [], 0
    while i < len(lines):
        ln = lines[i]
        if ln.strip().startswith("```"):
            buf = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                buf.append(lines[i])
                i += 1
            i += 1
            out.append("<pre>" + esc("\n".join(buf)) + "</pre>")
            continue
        m = re.match(r"^(#{1,4})\s+(.*)$", ln)
        if m:
            lvl = len(m.group(1))
            out.append(f"<h{lvl}>{md_inline(m.group(2), page_rel)}</h{lvl}>")
            i += 1
            continue
        if ln.lstrip().startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|[\s:|-]+\|\s*$", lines[i + 1]):
            cells = lambda r: [c.strip() for c in r.strip().strip("|").split("|")]
            head = cells(ln)
            i += 2
            rows = []
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                rows.append(cells(lines[i]))
                i += 1
            short_first = all(len(r[0]) <= 8 for r in rows if r)
            out.append('<div class="panel"><table><tr>' + "".join(f"<th>{md_inline(c, page_rel)}</th>" for c in head) + "</tr>" +
                       "".join("<tr>" + "".join(f'<td class="nw">{md_inline(c, page_rel)}</td>' if (j == 0 and short_first) else f"<td>{md_inline(c, page_rel)}</td>" for j, c in enumerate(r)) + "</tr>" for r in rows) + "</table></div>")
            continue
        if re.match(r"^\s*([-*]|\d+\.)\s+", ln):
            ordered = bool(re.match(r"^\s*\d+\.\s+", ln))
            items = []
            while i < len(lines) and (re.match(r"^\s*([-*]|\d+\.)\s+", lines[i]) or (lines[i].startswith("  ") and lines[i].strip() and items)):
                if re.match(r"^\s*([-*]|\d+\.)\s+", lines[i]):
                    indent = len(lines[i]) - len(lines[i].lstrip())
                    items.append([indent, re.sub(r"^\s*([-*]|\d+\.)\s+", "", lines[i])])
                else:
                    items[-1][1] += " " + lines[i].strip()
                i += 1
            tag = "ol" if ordered else "ul"
            html_items = "".join(f'<li style="margin-left:{ind * 0.6}em">{md_inline(t, page_rel)}</li>' for ind, t in items)
            out.append(f"<{tag}>{html_items}</{tag}>")
            continue
        if re.match(r"^---+\s*$", ln):
            out.append("<hr>")
            i += 1
            continue
        if not ln.strip():
            i += 1
            continue
        buf = [ln]
        i += 1
        while i < len(lines) and lines[i].strip() and not re.match(r"^(#{1,4}\s|```|\s*\|)|^\s*([-*]|\d+\.)\s+", lines[i]):
            buf.append(lines[i])
            i += 1
        out.append("<p>" + md_inline(" ".join(b.strip() for b in buf), page_rel) + "</p>")
    return "\n".join(out)


def write_page(out_path, title, body, root):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        f'<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
        f'<title>{esc(title)}</title><style>{PAGE_CSS}</style></head><body>{topnav(root)}<main class="md">{body}</main></body></html>', encoding="utf-8")


def render_markdown_site():
    """저장소의 md 문서를 같은 경로 구조의 html로 옮긴다."""
    targets = []
    for d in ("catalog", "atlas", "soc-map", "devices"):
        targets += sorted((ROOT / d).rglob("*.md"))
    targets += [ROOT / "inbox" / "ideas.md", ROOT / "inbox" / "queue.md", ROOT / "HARNESS.md"]
    count = 0
    for src in targets:
        if not src.exists():
            continue
        rel = src.relative_to(ROOT).as_posix()
        if rel == "HARNESS.md":
            out = DOCS / "harness.html"
            root = ""
        else:
            stem = "index" if src.name == "_index.md" else src.stem
            out = DOCS / Path(rel).parent / f"{stem}.html"
            root = "../" * len(Path(rel).parent.parts)
        fm, body = split_frontmatter(src.read_text(encoding="utf-8"))
        title = (re.search(r"^#\s+(.+)$", body, re.M).group(1) if re.search(r"^#\s+(.+)$", body, re.M) else fm.get("name", src.stem))
        fm_html = ""
        if fm:
            fm_html = '<div class="panel fm"><table>' + "".join(f"<tr><td>{esc(k)}</td><td>{md_inline(v, rel)}</td></tr>" for k, v in fm.items()) + "</table></div>"
            title = fm.get("name", title)
        page_body = f'<p class="muted"><a href="{REPO_URL}/blob/main/{esc(rel)}">GitHub 원본: {esc(rel)}</a></p>' + (f"<h1>{esc(title)}</h1>" + fm_html if fm else "") + md_to_html(body, rel)
        write_page(out, title, page_body, root)
        count += 1
    return count


# ---------- 메인 허브 ----------
def read_cards():
    cards = []
    for p in sorted((ROOT / "catalog").rglob("*.md")):
        if p.name == "_index.md":
            continue
        fm, _ = split_frontmatter(p.read_text(encoding="utf-8"))
        fm["_path"] = p.relative_to(ROOT).as_posix()
        fm.setdefault("name", p.stem)
        cards.append(fm)
    return cards


def read_ideas():
    path = ROOT / "inbox" / "ideas.md"
    ideas = []
    if not path.exists():
        return ideas
    cur = None
    for ln in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^##\s+(I-\d+)\s+(.*)$", ln)
        if m:
            cur = {"id": m.group(1), "title": m.group(2), "state": "?", "stage": ""}
            ideas.append(cur)
        elif cur and (m := re.match(r"^- 상태:\s*(\w+)", ln)):
            cur["state"] = m.group(1)
        elif cur and (m := re.match(r"^- 난이도:.*단계:\s*(T[0-5][^\s]*)", ln)):
            cur["stage"] = m.group(1)
    return ideas


def stage_range(st):
    nums = [int(x) for x in re.findall(r"T?([0-5])", st or "")]
    return range(nums[0], nums[-1] + 1) if nums else range(0)


def build_main(specs):
    cards, ideas = read_cards(), read_ideas()
    log = [l for l in (ROOT / "inbox" / "log.md").read_text(encoding="utf-8").splitlines() if re.match(r"^\d{4}-\d{2}-\d{2}", l)] if (ROOT / "inbox" / "log.md").exists() else []
    states = {}
    for i in ideas:
        states[i["state"]] = states.get(i["state"], 0) + 1
    l3 = sum(1 for c in cards if c.get("verification") == "L3")
    rechecked = sum(1 for c in cards if c.get("rechecked_at"))
    stat = lambda n, label: f'<div class="stat"><b>{n}</b><span class="muted">{esc(label)}</span></div>'
    stats = "".join([stat(len(specs), "캡스톤 패키지"), stat(len(cards), "수집 카드"), stat(l3, "L3 카드"), stat(rechecked, "재검증된 카드"),
                     stat(len(ideas), "아이디어"), stat(states.get("ready", 0) + states.get("used", 0), "ready·used")])

    cap_cards = ""
    for spec, ver in specs:
        badge = lambda label, k: f'<span class="badge b-{ver[k]["result"]}">{label} {STATE_LABEL.get(ver[k]["result"], ver[k]["result"])}</span>'
        broken = '<span class="badge b-fail">broken</span>' if spec.get("status") == "broken" else ""
        cap_cards += (f'<div class="cap"><h3><a href="{esc(spec["slug"])}/index.html">{esc(spec["title"])}</a></h3>'
                      f'<div class="muted">{esc(spec["board"])} · 단계 {esc(spec["stage"])}</div>{broken}'
                      f'<a href="{esc(spec["slug"])}/index.html"><img src="{esc(spec["slug"])}/diagram.svg" alt="{esc(spec["title"])} 계통도" loading="lazy"></a>'
                      f'<p>{esc(spec["summary"])}</p><div class="badges">{badge("린트", "lint")}{badge("시뮬", "sim")}{badge("합성", "synth")}{badge("보드", "board")}</div>'
                      f'<div><a href="{esc(spec["slug"])}/index.html">문서·계통도·소스</a> · <a href="{esc(spec["slug"])}/{esc(spec["slug"])}.zip">소스 .zip</a></div></div>')
    if not cap_cards:
        cap_cards = '<p class="muted">아직 패키지가 없다.</p>'

    stage_html = ""
    for n in range(6):
        t = f"T{n}"
        pk = [s for s, _ in specs if n in stage_range(s["stage"])]
        cs = [c for c in cards if n in stage_range(c.get("stage", ""))]
        plans = []
        for s, _ in specs:
            for r in s.get("roadmap", []):
                if r["state"] == "planned" and r["stage"] == t and r["title"] not in plans:
                    plans.append(r["title"])
        items = "".join(f'<li><a href="{esc(s["slug"])}/index.html">{esc(s["slug"])}</a></li>' for s in pk) or '<li class="muted">패키지 없음</li>'
        stage_html += (f'<div class="stage"><h4>{t}</h4><ul style="margin:0;padding-left:1.1em">{items}</ul>'
                       f'<div class="muted">카드 {len(cs)}건</div>' + (f'<div class="plan">계획: {esc("; ".join(plans[:2]))}</div>' if plans else "") + "</div>")

    card_rows = "".join(
        f'<tr><td><a href="{esc(c["_path"][:-3])}.html">{esc(c["name"])}</a></td><td>{esc(c.get("vendor", ""))}</td><td>{esc(c.get("stage", ""))}</td>'
        f'<td>{esc(c.get("fit_basys3", ""))}</td><td>{esc(c.get("verification", ""))}</td><td>{esc(c.get("rechecked_at", "-"))}</td></tr>' for c in cards)
    idea_rows = "".join(f'<tr><td>{esc(i["id"])}</td><td>{esc(i["title"])}</td><td>{esc(i["stage"])}</td><td>{esc(i["state"])}</td></tr>' for i in ideas)
    log_html = "".join(f"<li><code>{esc(l)}</code></li>" for l in reversed(log[-8:]))
    docs_links = " · ".join(f'<a href="{esc(p.relative_to(ROOT).as_posix()[:-3])}.html">{esc(p.stem)}</a>' for p in sorted((ROOT / "atlas").glob("*.md"))) or "없음"

    body = f"""<p class="muted">생성 {esc(kst_now())} · <a href="{REPO_URL}">{REPO_URL.split("github.com/")[1]}</a></p>
<h1>FPGA SoC 캡스톤 하네스</h1>
<p>FPGA로 만든 SoC 자료를 모으고 검증해, Basys3에서 실행할 수 있는 캡스톤 패키지(문서, 계통도, 실행 소스)로 만든다. 수집은 1시간마다, 검증은 3시간마다, 과제화는 6시간마다 자동으로 돈다.</p>
<div class="stats">{stats}</div>
<h2 id="capstones">캡스톤 패키지</h2><div class="cards">{cap_cards}</div>
<h2 id="tree">기술 트리 (단계별 패키지와 카드)</h2><div class="stages">{stage_html}</div>
<p class="muted">단계 정의와 카드 연결은 <a href="soc-map/tech-tree.html">기술 트리 문서</a>에 있다. 점선 아래는 계획 중인 확장이다.</p>
<h2 id="atlas">주제별 종합 (atlas)</h2><p>{docs_links}</p>
<h2 id="cards">수집 카드</h2><div class="panel"><table><tr><th>카드</th><th>벤더</th><th>단계</th><th>Basys3</th><th>등급</th><th>재검증</th></tr>{card_rows or '<tr><td colspan="6" class="muted">카드가 없다</td></tr>'}</table></div>
<p class="muted"><a href="catalog/index.html">카탈로그 목록</a> · 재검증이 비어 있는 카드는 다음 검증 사이클의 대상이다.</p>
<h2 id="ideas">아이디어 파이프라인</h2><p class="muted">상태별: {esc(", ".join(f"{k} {v}" for k, v in sorted(states.items())) or "없음")}</p>
<div class="panel"><table><tr><th>id</th><th>제목</th><th>단계</th><th>상태</th></tr>{idea_rows or '<tr><td colspan="4" class="muted">아이디어가 없다</td></tr>'}</table></div>
<p class="muted"><a href="inbox/ideas.html">전체 보기</a></p>
<h2 id="log">최근 활동</h2><ul>{log_html or '<li class="muted">기록 없음</li>'}</ul>"""
    write_page(DOCS / "index.html", "FPGA SoC 캡스톤 하네스", body, "")


def main():
    strict = "--strict" in sys.argv
    DOCS.mkdir(exist_ok=True)
    for c in read_cards():
        CARD_PATHS[c["name"]] = c["_path"]
    specs = []
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
        specs.append((spec, ver))
        print(f"docs/{spec['slug']}/index.html, diagram.svg, .zip 생성")
    n = render_markdown_site()
    build_main(specs)
    print(f"docs/index.html 생성, 문서 {n}건을 HTML로 변환")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
