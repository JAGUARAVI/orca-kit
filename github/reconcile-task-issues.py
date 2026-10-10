#!/usr/bin/env python3
"""
Reconcile task-issue state after work lands.

Actions:
 1. A merged PR whose head branch matches a task -> ensure that task's issue is CLOSED.
    (Match order: `Closes/Fixes/Resolves [#]N` in the PR body, then any `[ID]` tag in the
    PR title, then an `ID` token in the branch name.)
 2. For every OPEN task issue labeled `blocked`, remove `blocked` and add `ready`
    when all of its `Blocked by: [#n — ID](...)` dependencies are closed.

Dependency edges are read from each issue's `## Dependencies` block (the format written by
create-task-issues.py). Idempotent: safe (and intended) to run on every PR merge.

Usage (via the GitHub Action .github/workflows/task-reconcile.yml, or manually):
  reconcile-task-issues.py --repo <owner/repo> [--gh <cmd>] [--dry-run] [--pr <n>]
"""
import argparse, json, re, subprocess, sys

WORKFLOW_LABELS = ("blocked", "ready", "in-progress", "review")


def run(args, dry):
    if dry:
        print("DRY:", " ".join(args)); return ""
    p = subprocess.run(args, text=True, capture_output=True)
    if p.returncode:
        print(p.stderr or p.stdout, file=sys.stderr); raise SystemExit(p.returncode)
    return p.stdout.strip()


def issue_key(title):
    m = re.search(r"\[([A-Za-z0-9]+-\d+)\]", title or "")
    return m.group(1) if m else None


def pr_key(pr):
    m = re.search(r"\b([A-Za-z0-9]+-\d+)\b", pr.get("title", ""))
    if m: return m.group(1)
    m = re.search(r"([a-z0-9]+-\d+)", (pr.get("headRefName") or "").lower())
    return m.group(1).upper() if m else None


def merged_prs(G, dry, only_pr=None):
    """Only ever return PRs that are actually merged (state MERGED).

    Guards against being run from a non-merge event (e.g. a label being added to an
    open PR) where a naive `pr list` would surface the PR and look like a merge.
    """
    out = run(G + ["pr", "list", "--state", "merged", "--limit", "500",
                   "--json", "number,title,body,headRefName,mergedAt"], dry)
    prs = json.loads(out or "[]")
    # Defensive: require a non-null mergedAt.
    prs = [p for p in prs if p.get("mergedAt")]
    if only_pr is not None:
        prs = [p for p in prs if p["number"] == only_pr]
    return prs


def close_issue(G, dry, number, dry_skip_labels):
    """Close an issue, then strip workflow labels with `gh issue edit` (close has no --remove-label)."""
    run(G + ["issue", "close", str(number), "--reason", "completed"], dry)
    if dry_skip_labels:
        return
    run(G + ["issue", "edit", str(number)] + sum((["--remove-label", l] for l in dry_skip_labels), []))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gh", default="gh")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--pr", type=int, help="only consider this PR (still reconciles all issues)")
    a = ap.parse_args()
    G = [a.gh, "-R", a.repo]

    merged = merged_prs(G, a.dry_run, a.pr)
    pr_keys = {}
    for p in merged:
        k = pr_key(p)
        ids = []
        for n in re.findall(r"(?:clos(?:e|es|ed)|fix(?:e|es|ed)|resolve[sd]?)\s+#(\d+)",
                            p.get("body", ""), re.I):
            ids.append(int(n))
        if k: pr_keys.setdefault(k, set()).update(ids)

    if not merged:
        print("no merged PRs to consider; checking for unblockable issues only")

    issues = json.loads(run(G + ["issue", "list", "--state", "all", "--limit", "1000",
        "--json", "number,title,state,labels,body"], a.dry_run) or "[]")
    by_num = {i["number"]: i for i in issues}
    by_key = {issue_key(i["title"]): i for i in issues if issue_key(i["title"])}

    # 2a) close issues completed by a merged PR
    for k, nums in pr_keys.items():
        iss = by_key.get(k)
        if not iss or iss["state"] == "CLOSED": continue
        print(f"close: #{iss['number']} [{k}] (merged PR)")
        strip = [l["name"] for l in iss["labels"] if l["name"] in WORKFLOW_LABELS]
        close_issue(G, a.dry_run, iss["number"], strip)
        iss["state"] = "CLOSED"
    for num in {n for nums in pr_keys.values() for n in nums}:
        iss = by_num.get(num)
        if iss and iss["state"] == "OPEN" and issue_key(iss["title"]):
            print(f"close: #{num} (referenced by merged PR)")
            strip = [l["name"] for l in iss["labels"] if l["name"] in WORKFLOW_LABELS]
            close_issue(G, a.dry_run, num, strip)
            iss["state"] = "CLOSED"

    # 2a-bis) strip stale workflow labels from closed task issues
    for iss in issues:
        if iss["state"] != "CLOSED" or not issue_key(iss["title"]): continue
        stale = [l["name"] for l in iss["labels"] if l["name"] in WORKFLOW_LABELS]
        if stale:
            print(f"strip: #{iss['number']} [{issue_key(iss['title'])}] closed cleanup {stale}")
            run(G + ["issue", "edit", str(iss["number"])]
                + sum((["--remove-label", l] for l in stale), []), a.dry_run)

    # 2b) unblock issues whose dependencies are all closed
    for iss in issues:
        if iss["state"] != "OPEN": continue
        labels = [l["name"] for l in iss["labels"]]
        if "blocked" not in labels: continue
        deps = re.findall(r"#(\d+)\s*—\s*([A-Za-z0-9]+-\d+)", iss.get("body", ""))
        if not deps: continue                      # no machine-readable deps -> leave alone
        open_deps = [n for n, _ in deps
                     if (by_num.get(int(n)) or {}).get("state") == "OPEN"]
        if not open_deps:
            print(f"unblock: #{iss['number']} [{issue_key(iss['title'])}] -> ready")
            run(G + ["issue", "edit", str(iss["number"]),
                     "--remove-label", "blocked", "--add-label", "ready"], a.dry_run)
    if not a.dry_run:
        print("reconcile complete")


if __name__ == "__main__":
    main()