#!/usr/bin/env python3
"""
deps-from-index.py — build the dependency graph JSON that create-task-issues.py consumes,
directly from the task index table in docs/tasks/README.md.

The index table is the single source of truth for dependencies, so this removes the manual step
of hand-maintaining `deps.json` (which drifts easily).

Handles the table shapes actually used in production:

  | ID | Task | Depends on | Owns (may edit) | Agent fit |
  | --- | --- | --- | --- | --- |
  | [P0-04](P0/P0-04-contracts.md) | Contracts and schemas | P0-01 | src/core/contracts/ | Strong reasoning |
  | [P0-15](...) | Level runner | P0-04, P0-06 | src/level-runner/ | Strong reasoning |
  | [P0-23](...) | Demo journey | P0-14, 18, 21, 22 | tests/... | Fast |

Notes:
  * IDs may be markdown links -> the `[ID]` text is extracted.
  * The "Depends on" cell may use a shorthand `P0-07, 08, 09` meaning `P0-07, P0-08, P0-09`
    (the phase prefix is inherited from the row's own ID).
  * `—` / `-` / empty / `none` mean "no dependencies".

Usage:
  deps-from-index.py [docs/tasks/README.md] [-o docs/tasks/deps.json] [--stdout]

Output JSON: {"P0-01": [], "P0-04": ["P0-01"], ...}
"""
import argparse, json, re, sys

NONE = {"", "-", "—", "–", "none", "n/a", "na"}
ID_RE = re.compile(r"[A-Za-z0-9]+-\d+")

def strip_row(line):
    """Split a markdown table row into stripped cells."""
    return [c.strip() for c in line.strip().strip("|").split("|")]

def cell_id(cell):
    """Extract a task id from a cell that may be a markdown link or a bare id."""
    m = ID_RE.search(cell)
    return m.group(0) if m else None

def normalise_dep(token, phase):
    """`P0-08` -> P0-08 ; `08` -> <phase>-08 (phase = P0)."""
    token = token.strip().strip("*` ")
    if not token:
        return None
    m = ID_RE.fullmatch(token)
    if m:
        return token
    if re.fullmatch(r"\d+", token):
        return f"{phase}-{token}"
    return None

def parse_table(text):
    rows = [l for l in text.splitlines() if l.strip().startswith("|")]
    if not rows:
        return []
    header_idx = None
    for i, line in enumerate(rows):
        low = [c.strip().lower() for c in strip_row(line)]
        if any(("id" == c or "card" in c or c.endswith(" id")) for c in low) and any("depend" in c for c in low):
            header_idx = i
            break
    if header_idx is None:
        return []
    low = [c.strip().lower() for c in strip_row(rows[header_idx])]
    id_col = next((j for j, c in enumerate(low) if "id" == c or "card" in c or c.endswith(" id")), 0)
    dep_col = next((j for j, c in enumerate(low) if "depend" in c), 2)

    out = []
    for line in rows[header_idx + 1:]:
        cells = strip_row(line)
        if all(set(c) <= set("-: ") for c in cells):
            continue  # separator
        if id_col >= len(cells):
            continue
        key = cell_id(cells[id_col])
        if not key:
            continue
        phase = key.split("-")[0]
        dep_cell = cells[dep_col] if dep_col < len(cells) else ""
        deps = []
        if dep_cell.lower() not in NONE:
            for tok in re.split(r"[,\s]+", dep_cell):
                d = normalise_dep(tok, phase)
                if d and d != key:
                    deps.append(d)
        # de-dupe, keep order
        seen, dd = set(), []
        for d in deps:
            if d not in seen:
                seen.add(d); dd.append(d)
        out.append((key, dd))
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("index", nargs="?", default="docs/tasks/README.md")
    ap.add_argument("-o", "--out", default="docs/tasks/deps.json")
    ap.add_argument("--stdout", action="store_true")
    a = ap.parse_args()
    pairs = parse_table(open(a.index).read())
    if not pairs:
        sys.exit(f"no task rows found in {a.index} (expected a | ID | ... | Depends on | ... | table)")
    graph = dict(pairs)
    unknown = sorted({d for _, deps in pairs for d in deps if d not in graph})
    if unknown:
        print(f"warning: deps referenced but not listed as tasks: {unknown}", file=sys.stderr)
    out = json.dumps(graph, indent=2, sort_keys=True)
    if a.stdout:
        print(out)
    else:
        open(a.out, "w").write(out + "\n")
        print(f"wrote {a.out}: {len(graph)} tasks, {sum(len(v) for v in graph.values())} edges")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())