#!/usr/bin/env python3
"""
Turn per-task brief files into GitHub issues with workflow labels and dependency links.

Intended workflow (see docs/19-task-breakdown-and-issues.md):
  1. Break the plan into task briefs under docs/tasks/<PHASE>/<ID>-<slug>.md
     (each follows templates/TASK-BRIEF.md and carries a `Card: <ID>` header line).
  2. Keep a task index (docs/tasks/README.md) with a table of ID -> Depends on.
  3. Put the dependency graph in the DEPS dict below (or a JSON file) and run this script.

Usage:
  ./create-task-issues.py --repo <owner/repo> [--root <repo-path>] [--deps deps.json]
                          [--phases P0 P1] [--gh <cmd>] [--dry-run]

Design notes:
  * Issues are created FIRST, then a clickable "## Dependencies" block is appended,
    so dependency links can reference real issue numbers.
  * Re-running is safe: existing issues are matched by the `[ID]` tag in the title,
    so it only creates what is missing and refreshes the dependency block.
  * Status label: `ready` when the task has no prerequisites, else `blocked`.
"""
import argparse, glob, json, os, re, subprocess, sys

DEFAULT_DEPS = {}  # e.g. {"P0-01": [], "P0-04": ["P0-01"], "P0-05": ["P0-04"]}

def run(args, dry):
    if dry:
        print("DRY:", " ".join(args)); return ""
    p = subprocess.run(args, text=True, capture_output=True)
    if p.returncode:
        print(p.stderr or p.stdout, file=sys.stderr); raise SystemExit(p.returncode)
    return p.stdout.strip()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, help="owner/repo")
    ap.add_argument("--root", default=".", help="repo checkout path")
    ap.add_argument("--deps", help="JSON file: {ID: [prereq IDs]}")
    ap.add_argument("--phases", nargs="*", default=["P0", "P1"], help="subdirs under docs/tasks/")
    ap.add_argument("--gh", default="gh", help="gh command (e.g. Avi-gh wrapper)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    os.chdir(a.root)

    deps = json.load(open(a.deps)) if a.deps else DEFAULT_DEPS
    if not deps:
        raise SystemExit("No dependency graph: pass --deps deps.json or edit DEFAULT_DEPS.")

    # discover briefs
    items = []
    for phase in a.phases:
        for path in sorted(glob.glob(f"docs/tasks/{phase}/*.md")):
            text = open(path).read()
            m = re.search(r"Card:\s*([A-Za-z0-9]+-\d+)", text)
            if not m: continue
            key = m.group(1)
            title = re.search(r"^#\s*Task brief:\s*(.+)$", text, re.M).group(1).strip()
            items.append((key, title, path, text))
    if not items:
        raise SystemExit("No task briefs found under docs/tasks/.")
    items.sort(key=lambda x: (x[0][:2], int(x[0].split("-")[1])))
    missing = set(x[0] for x in items) - set(deps)
    if missing:
        print(f"warning: briefs without a dependency entry: {sorted(missing)}", file=sys.stderr)

    G = [a.gh, "-R", a.repo]

    # labels (idempotent)
    for name, color, desc in [
        ("ready","0E8A16","Unblocked and available to start"),
        ("blocked","B60205","Waiting on dependencies or a gate"),
        ("in-progress","FBCA04","Work has started"),
        ("review","5319E7","Implementation is awaiting review"),
        ("task","1D76DB","Implementation task brief"),
    ]:
        run(G + ["label","create",name,"--color",color,"--description",desc,"--force"], a.dry_run)

    existing = json.loads(run(G + ["issue","list","--state","all","--limit","1000",
                                   "--json","number,title,body,url"], a.dry_run) or "[]")
    bykey = {}
    for iss in existing:
        m = re.search(r"\[([A-Za-z0-9]+-\d+)\]", iss["title"])
        if m: bykey[m.group(1)] = iss

    for key, title, path, body in items:
        if key in bykey: continue
        status = "ready" if not deps.get(key) else "blocked"
        prio = key.split("-")[0]
        url = run(G + ["issue","create","--title",f"[{key}] {title}","--body",body,
                       "--label",status,"--label","task","--label",prio], a.dry_run)
        n = int(url.rstrip("/").split("/")[-1]) if url else 0
        bykey[key] = {"number":n,"url":url,"body":body}
        print(f"created {key} #{n}")

    for key, title, path, brief in items:
        iss = bykey[key]; depkeys = deps.get(key, [])
        lines = ["## Dependencies"]
        if depkeys:
            links = ", ".join(f"[#{bykey[d]['number']} — {d}]({bykey[d]['url']})"
                              for d in depkeys if d in bykey)
            lines.append("Blocked by: " + links + ".")
        else:
            lines.append("None. This task has no prerequisite task issues.")
        body = brief.rstrip() + "\n\n" + "\n".join(lines) + "\n"
        if iss.get("body","").rstrip() == body.rstrip(): continue
        run(G + ["issue","edit",str(iss["number"]),"--body",body], a.dry_run)
    print(f"Complete: {len(items)} task issues indexed.")

if __name__ == "__main__":
    main()
