#!/usr/bin/env python3
"""capstones/*/ 의 lint, sim, synth를 실행하고 build/status.json에 결과를 기록한다.
도구가 없으면 'skipped'로 남긴다(통과로 취급하지 않는다). 표준 라이브러리만 사용."""
import json
import re
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STEPS = [("lint", "verilator"), ("sim", "iverilog"), ("synth", "yosys")]


def parse_cells(text):
    """yosys stat의 두 출력 형식('LUT2  12' 또는 '12  LUT2')을 모두 읽는다. 마지막 stat 블록만 쓴다."""
    block = text.rsplit("Printing statistics", 1)[-1]
    counts = {}
    for line in block.splitlines():
        m = re.match(r"^\s*([A-Z][A-Z0-9_]+)\s+(\d+)\s*$", line) or None
        if m:
            counts[m.group(1)] = int(m.group(2))
            continue
        m = re.match(r"^\s*(\d+)\s+([A-Z][A-Z0-9_]+)\s*$", line)
        if m:
            counts[m.group(2)] = int(m.group(1))
    return counts


def run_step(cap, step, tool):
    if shutil.which(tool) is None:
        return {"result": "skipped", "detail": f"{tool} 없음"}
    if step == "sim" and shutil.which("vvp") is None:
        return {"result": "skipped", "detail": "vvp 없음"}
    p = subprocess.run(["make", "-C", str(cap), step], capture_output=True, text=True)
    out = (p.stdout or "") + (p.stderr or "")
    detail = ""
    if step == "lint":
        warns = len(re.findall(r"%Warning", out))
        detail = f"경고 {warns}건"
    elif step == "sim":
        detail = "PASS" if re.search(r"^PASS", out, re.M) else (re.findall(r"^FAIL.*$", out, re.M) or ["PASS 없음"])[0]
    elif step == "synth":
        log = cap / "build" / "synth.log"
        counts = parse_cells(log.read_text(encoding="utf-8", errors="replace")) if log.exists() else {}
        luts = sum(v for k, v in counts.items() if k.startswith("LUT"))
        ffs = sum(v for k, v in counts.items() if k.startswith("FD"))
        detail = f"LUT {luts}, FF {ffs} (yosys 추정)" if counts else "stat 파싱 실패"
    if p.returncode != 0:
        # GitHub Actions 주석으로 남겨 로그인 없이도 실패 원인을 볼 수 있게 한다
        tail = "%0A".join(l.replace("%", "%25") for l in out.strip().splitlines()[-12:])
        print(f"::error title={cap.name} {step} 실패::{tail}")
    return {"result": "pass" if p.returncode == 0 else "fail", "detail": detail}


def main():
    rc = 0
    for spec in sorted((ROOT / "capstones").glob("*/capstone.json")):
        cap = spec.parent
        (cap / "build").mkdir(exist_ok=True)
        status = {"date": date.today().isoformat()}
        for step, tool in STEPS:
            status[step] = run_step(cap, step, tool)
            print(f"{cap.name}: {step} -> {status[step]['result']} ({status[step]['detail']})")
            if status[step]["result"] == "fail":
                rc = 1
        (cap / "build" / "status.json").write_text(json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
    return rc


if __name__ == "__main__":
    sys.exit(main())
