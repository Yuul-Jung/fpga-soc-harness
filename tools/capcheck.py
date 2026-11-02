#!/usr/bin/env python3
"""캡스톤 명세(capstone.json)의 v0.6 검증과 산출물(연결/BOM/매니페스트) 생성. 표준 라이브러리만 사용.
build.py(문서 생성)와 audit.py(전수 감사)가 함께 쓴다."""
import csv
import hashlib
import io
import json
from pathlib import Path

import rtlscan

ROOT = Path(__file__).resolve().parent.parent


def load_json(rel):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def hexint(s):
    return int(str(s).replace("_", ""), 16)


def policy():
    return load_json("config/policy.json")


def address_map():
    return load_json("config/soc_address_map.json")


def check_integration(spec):
    """통합 선언(버스, 동결 주소맵 적합 여부)을 검사한다. 반환: errs, warns"""
    errs, warns = [], []
    pol, amap = policy(), address_map()
    integ = spec.get("integration")
    if not integ:
        (errs if pol["capstone"]["require_integration"] else warns).append("integration 섹션 없음 (버스와 동결 주소맵 적합 여부를 밝혀야 한다)")
        return errs, warns
    for key in ("bus", "address_map", "compat", "plan"):
        if key not in integ:
            errs.append(f"integration.{key} 없음")
    if errs:
        return errs, warns
    if integ["compat"] not in ("compatible", "partial", "incompatible"):
        errs.append("integration.compat는 compatible|partial|incompatible")
    if integ["address_map"] == amap["name"]:
        regions = {r["name"]: r for r in amap["regions"]}
        mapping = integ.get("frozen_mapping", [])
        mapped = {m["block"] for m in mapping}
        for m in mapping:
            r = regions.get(m["frozen"])
            if not r:
                errs.append(f"integration.frozen_mapping: 동결 맵에 없는 영역 {m['frozen']}")
                continue
            entry = next((e for e in spec["memory_map"] if e["block"] == m["block"]), None)
            if not entry:
                errs.append(f"integration.frozen_mapping: memory_map에 없는 블록 {m['block']}")
            elif hexint(entry["base"]) != hexint(r["base"]):
                errs.append(f"{m['block']}: 기준 주소 {entry['base']}가 동결 맵 {r['name']}={r['base']}과 다름")
        for e in spec["memory_map"]:
            if e["block"] not in mapped:
                errs.append(f"memory_map 블록 {e['block']}가 frozen_mapping에 없음 (동결 맵을 쓴다고 선언했다)")
        if integ["compat"] == "incompatible":
            errs.append("동결 맵을 쓴다고 선언했으면서 compat가 incompatible")
    else:
        if integ["compat"] == "compatible":
            errs.append("address_map이 동결 맵이 아닌데 compat를 compatible로 선언함")
        warns.append(f"동결 주소맵({amap['name']})과 다른 맵을 쓴다: 파일럿용. 이식 계획을 integration.plan에 둔다")
    # 동결 슬롯과 겹치는지 (custom이어도 CPU 교체 시 충돌할 수 있다)
    frozen = [(hexint(r["base"]), hexint(r["size"]), r["name"]) for r in amap["regions"]]
    for e in spec["memory_map"]:
        b, s = hexint(e["base"]), hexint(e["size"])
        for fb, fs, fn in frozen:
            if integ["address_map"] != amap["name"] and b < fb + fs and fb < b + s:
                warns.append(f"memory_map {e['block']}가 동결 영역 {fn}과 주소가 겹침")
    return errs, warns


def check_external_parts(spec):
    errs, warns = [], []
    pol = policy()
    allowed = set(pol["board"]["allowed_io_voltages"])
    parts = spec.get("external_parts")
    blocks = {b["id"]: b for b in spec["architecture"]["blocks"]}
    if parts is None:
        warns.append("external_parts 섹션 없음 (외부 부품의 전압을 선언해야 한다)")
        return errs, warns
    seen = set()
    for p in parts:
        pid = p.get("id", "?")
        if pid in seen:
            errs.append(f"external_parts id 중복: {pid}")
        seen.add(pid)
        for key in ("id", "name", "block", "interface", "io_voltage", "qty", "board_resident"):
            if key not in p:
                errs.append(f"external_parts[{pid}].{key} 없음")
        if p.get("block") and (p["block"] not in blocks or blocks[p["block"]]["kind"] != "external"):
            errs.append(f"external_parts[{pid}].block={p.get('block')}: external 블록이 아님")
        v = p.get("io_voltage")
        if isinstance(v, (int, float)) and v not in allowed and not p.get("level_shift"):
            errs.append(f"external_parts[{pid}]: 신호 전압 {v}V는 Basys3 직결 불가. level_shift에 변환 방법이 필요")
        if p.get("supply_voltage") and p["supply_voltage"] not in allowed and not p.get("power_note"):
            errs.append(f"external_parts[{pid}]: 전원 {p['supply_voltage']}V는 FPGA 핀과 분리해야 한다. power_note 필요")
    for b in blocks.values():
        if b["kind"] == "external" and not any(p.get("block") == b["id"] for p in parts):
            warns.append(f"외부 블록 {b['id']}에 external_parts 항목이 없음")
    return errs, warns


def check_code_names(spec, cap_dir):
    """명세의 모듈·파일 이름이 실제 소스와 일치하는지 대조한다 (코드와 계통도·계층의 이름 일치 원칙)."""
    errs, warns = [], []
    files = [cap_dir / f for f in spec["sources"].get("rtl", [])]
    scan = rtlscan.scan_files([f for f in files if f.exists()])
    errs += scan["errors"]
    mods = scan["modules"]
    for b in spec["architecture"]["blocks"]:
        if b.get("module") and b["module"] != "-":
            m = mods.get(b["module"])
            if not m:
                errs.append(f"블록 {b['id']}: 모듈 {b['module']}이 rtl 소스에 선언되지 않음")
            elif b.get("file") and Path(m["file"]).name != Path(b["file"]).name:
                errs.append(f"블록 {b['id']}: {b['module']}은 {Path(m['file']).name}에 있는데 명세는 {b['file']}")

    declared_children = {}

    def walk(node, parent=None):
        name = node["module"]
        if name not in mods:
            errs.append(f"hierarchy: 모듈 {name}이 소스에 없음")
        elif Path(mods[name]["file"]).name != Path(node["file"]).name:
            errs.append(f"hierarchy: {name}의 파일이 소스와 다름 ({node['file']})")
        if parent:
            declared_children.setdefault(parent, set()).add(name)
        for c in node.get("children", []):
            walk(c, name)
    walk(spec["hierarchy"])
    for parent, kids in declared_children.items():
        if parent in mods:
            actual = {i["module"] for i in mods[parent]["instances"]}
            for k in kids:
                if k not in actual:
                    errs.append(f"hierarchy: {parent} 안에서 {k} 인스턴스를 찾지 못함")
    in_hier = set()

    def names(node):
        in_hier.add(node["module"])
        for c in node.get("children", []):
            names(c)
    names(spec["hierarchy"])
    for m in mods:
        if m not in in_hier:
            warns.append(f"소스에 있는 모듈 {m}이 hierarchy에 없음")
    return errs, warns


def connections_json(spec):
    blocks = [{"id": b["id"], "name": b["name"], "kind": b["kind"], "module": b.get("module", "-"), "file": b.get("file")}
              for b in spec["architecture"]["blocks"]]
    return {"schema_version": 1, "slug": spec["slug"], "kind": "digital-block-diagram",
            "note": "디지털 모듈 연결도다. 외부 부품의 전기 배선(전압, 저항, 커넥터)은 포함하지 않는다.",
            "bus": spec["bus_protocol"]["name"], "blocks": blocks, "links": spec["architecture"]["links"]}


def bom_csv(spec):
    out = io.StringIO()
    w = csv.writer(out, lineterminator="\n")
    w.writerow(["id", "name", "interface", "io_voltage_V", "supply_V", "qty", "board_resident", "arduino_compatible", "level_shift", "notes"])
    for p in spec.get("external_parts", []):
        w.writerow([p["id"], p["name"], p["interface"], p["io_voltage"], p.get("supply_voltage", ""), p["qty"],
                    str(p["board_resident"]).lower(), str(p.get("arduino_compatible", False)).lower(),
                    p.get("level_shift", ""), p.get("notes", "")])
    return out.getvalue()


def source_manifest(spec, cap_dir):
    files = []
    for group, names in spec["sources"].items():
        for f in names:
            data = (cap_dir / f).read_bytes()
            files.append({"group": group, "path": f, "sha256": hashlib.sha256(data).hexdigest(),
                          "lines": data.count(b"\n"), "origin": "first_party"})
    return {"schema_version": 1, "slug": spec["slug"], "files": files,
            "note": "소스는 하네스가 직접 쓴 원본이다. 외부 저장소 코드는 포함하지 않는다(HARNESS §13.3)."}
