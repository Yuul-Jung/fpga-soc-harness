#!/usr/bin/env python3
"""사용자 RTL 검증 다리 (HARNESS §17.3). ipcheck/<이름>/ 마다 린트·시뮬레이션·합성을 돌린다.

ipcheck/<이름>/ 구성:
  ipcheck.json   {"top": "...", "tb_top": "...", "rtl": [...], "tb": [...], "license": "MIT", "approved_by_user": "YYYY-MM-DD"}
  LICENSE        라이선스 전문 (필수)
  rtl/ tb/       사용자가 직접 쓴 RTL과 자체 점검형 테스트벤치 (PASS/FAIL 줄 출력)

게이트 (§16.3 G4): license 가 config/policy.json 의 permissive 목록, LICENSE 파일 존재,
approved_by_user 날짜가 있어야 한다. 하나라도 없으면 그 IP는 'gated'로 건너뛴다(통과로 세지 않는다).
도구가 없으면 해당 단계는 'skipped'이며 통과로 세지 않는다(§13.4). 결과는 build/ipcheck.json.
종료 코드: 실패(fail)가 있으면 1, 아니면 0.
표준 라이브러리만 사용한다.
"""
import json, os, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run(cmd, cwd):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=300)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def check_ip(d, permissive):
    name = os.path.basename(d)
    res = {"ip": name, "lint": "skipped", "sim": "skipped", "synth": "skipped", "gate": "ok", "notes": []}
    try:
        m = json.load(open(os.path.join(d, "ipcheck.json"), encoding="utf-8"))
    except (OSError, ValueError) as e:
        res["gate"] = "invalid"; res["notes"].append(f"ipcheck.json 읽기 실패: {e}"); return res
    if m.get("license") not in permissive:
        res["gate"] = "gated"; res["notes"].append("license 가 permissive 목록에 없음")
    if not os.path.isfile(os.path.join(d, "LICENSE")):
        res["gate"] = "gated"; res["notes"].append("LICENSE 파일 없음")
    if not m.get("approved_by_user"):
        res["gate"] = "gated"; res["notes"].append("approved_by_user 날짜 없음 (사용자 승인 필요)")
    missing = [f for f in m.get("rtl", []) + m.get("tb", []) if not os.path.isfile(os.path.join(d, f))]
    if missing:
        res["gate"] = "invalid"; res["notes"].append(f"없는 파일: {missing}")
    if res["gate"] != "ok":
        return res
    bd = os.path.join(d, "build"); os.makedirs(bd, exist_ok=True)
    rtl, tb, top = m["rtl"], m.get("tb", []), m["top"]
    if shutil.which("verilator"):
        rc, out = run(["verilator", "--lint-only", "-Wall", "-Wno-fatal", "--top-module", top] + rtl, d)
        res["lint"] = "pass" if rc == 0 and "%Error" not in out else "fail"
        if res["lint"] == "fail": res["notes"].append("lint: " + out[-300:])
    if tb and shutil.which("iverilog") and shutil.which("vvp"):
        rc, out = run(["iverilog", "-g2005", "-o", "build/sim.vvp"] + tb + rtl, d)
        if rc == 0:
            rc, out = run(["vvp", "build/sim.vvp"], d)
        ok = rc == 0 and any(l.startswith("PASS") for l in out.splitlines()) and not any(l.startswith("FAIL") for l in out.splitlines())
        res["sim"] = "pass" if ok else "fail"
        if not ok: res["notes"].append("sim: " + out[-300:])
    if shutil.which("yosys"):
        rc, out = run(["yosys", "-q", "-p", f"read_verilog {' '.join(rtl)}; synth -top {top} -flatten; stat"], d)
        res["synth"] = "pass" if rc == 0 else "fail"
        if rc != 0: res["notes"].append("synth: " + out[-300:])
    return res


def main(argv):
    root = argv[1] if len(argv) > 1 else os.path.join(ROOT, "ipcheck")
    pol = json.load(open(os.path.join(ROOT, "config", "policy.json"), encoding="utf-8"))
    permissive = pol["license"]["permissive_spdx"]
    dirs = sorted(os.path.join(root, x) for x in os.listdir(root) if os.path.isdir(os.path.join(root, x))) if os.path.isdir(root) else []
    results = [check_ip(d, permissive) for d in dirs]
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    json.dump(results, open(os.path.join(ROOT, "build", "ipcheck.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    for r in results:
        print(f'{r["ip"]}: gate={r["gate"]} lint={r["lint"]} sim={r["sim"]} synth={r["synth"]}', *r["notes"][:2])
    if not results:
        print("ipcheck: 검증할 IP 없음 (ipcheck/<이름>/ 에 사용자 승인 후 추가)")
    return 1 if any("fail" in (r["lint"], r["sim"], r["synth"]) or r["gate"] == "invalid" for r in results) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
