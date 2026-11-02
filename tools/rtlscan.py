#!/usr/bin/env python3
"""Verilog-2001 소스에서 모듈 선언, 포트, 인스턴스를 뽑는 가벼운 스캐너. 표준 라이브러리만 사용.
완전한 파서가 아니다. 이 저장소의 소스 규칙(§13.3: 순수 Verilog-2001, ANSI 포트 선언)을 전제로 한다.
용도: 명세(capstone.json)의 이름이 실제 코드와 맞는지 대조한다."""
import re
from pathlib import Path

KEYWORDS = {"module", "endmodule", "input", "output", "inout", "wire", "reg", "assign", "always",
            "initial", "begin", "end", "if", "else", "case", "endcase", "for", "function", "endfunction",
            "task", "endtask", "generate", "endgenerate", "parameter", "localparam", "integer", "genvar",
            "posedge", "negedge", "default", "while", "repeat", "forever", "fork", "join", "signed"}


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", " ", text)


def scan_text(text):
    """반환: [{name, ports:[{name,dir,width}], instances:[{module,name}]}]"""
    src = strip_comments(text)
    mods = []
    for m in re.finditer(r"\bmodule\s+(\w+)\s*(#\s*\(.*?\))?\s*(?:\((.*?)\))?\s*;(.*?)\bendmodule\b", src, flags=re.S):
        name, _params, header, body = m.group(1), m.group(2), m.group(3) or "", m.group(4)
        ports = []
        for part in re.split(r",(?![^\[]*\])", header):
            pm = re.search(r"\b(input|output|inout)\b\s*(?:wire|reg|logic)?\s*(?:signed)?\s*(\[[^\]]+\])?\s*(\w+)\s*$", part.strip(), flags=re.S)
            if pm:
                ports.append({"name": pm.group(3), "dir": pm.group(1), "width": (pm.group(2) or "").replace(" ", "")})
        mods.append({"name": name, "ports": ports, "body": body})
    names = {m["name"] for m in mods}
    return mods, names


def instances_in(body, known):
    found = []
    for m in re.finditer(r"^\s*(\w+)\s*(?:#\s*\(.*?\))?\s+(\w+)\s*\(", body, flags=re.S | re.M):
        mod, inst = m.group(1), m.group(2)
        if mod in KEYWORDS or inst in KEYWORDS:
            continue
        if mod in known:
            found.append({"module": mod, "name": inst})
    return found


def scan_files(paths):
    """여러 파일을 읽어 {modules:{name:{file,ports,instances}}, errors:[...]} 를 만든다."""
    modules, errors, raw = {}, [], []
    for p in paths:
        p = Path(p)
        if not p.suffix == ".v":
            continue
        mods, _ = scan_text(p.read_text(encoding="utf-8"))
        if not mods:
            errors.append(f"{p.name}: module 선언을 찾지 못함")
        for m in mods:
            if m["name"] in modules:
                errors.append(f"모듈 중복 선언: {m['name']} ({modules[m['name']]['file']}, {p.name})")
            modules[m["name"]] = {"file": p.as_posix(), "ports": m["ports"], "body": m["body"]}
            raw.append(m["name"])
    known = set(modules)
    for name, info in modules.items():
        info["instances"] = instances_in(info.pop("body"), known)
    return {"modules": modules, "errors": errors}


if __name__ == "__main__":
    import json, sys
    out = scan_files(sys.argv[1:])
    print(json.dumps(out, ensure_ascii=False, indent=1))
