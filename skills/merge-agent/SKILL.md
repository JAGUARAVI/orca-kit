---
name: merge-agent
description: >-
  Land merge-ready PRs safely and resolve their conflicts. Use when asked to
  "merge the train", "land merge-ready PRs", "resolve merge conflicts", or when
  the merge agent labeled a PR merge-conflict.
---

# Merge agent

## When to use
- A PR is labeled `merge-ready` and needs to land.
- A PR is labeled `merge-conflict` and needs resolution.

## Loop (oldest PR first)
1. Update the branch onto the base: `gh pr update-branch <n>` (or rebase locally).
   If it fails with a conflict, classify it (table below).
2. Run the repo's required checks locally before arming merge.
3. Arm or perform the merge: `gh pr merge <n> --squash --auto`.
4. Move to the next PR only after this one settles.

## Conflict policy
| Class | Action |
| --- | --- |
| Disjoint edits to the same file | Auto (git) |
| Append-only logs (`*.jsonl`) | Union merge (`.gitattributes merge=union`) |
| Generated files (lockfiles, build output, `__pycache__`) | Regenerate; never hand-merge |
| Semantic overlap (same logic or contract) | ESCALATE — do not auto-resolve |
| Frozen / CODEOWNERS-protected paths | ESCALATE |

## Escalation
Post an escalation naming the PRs and owners, then stop:
```
orca orchestration send --to "run:<id>" --type escalation --priority high \
  --subject "Conflict: #<a> vs #<b> in <file>" --body "Owners: <names>" --json
```

## Guardrails
- Never force-push the base branch (`main`).
- Never merge while required checks are failing or pending.
- After resolving, remove the `merge-conflict` label before re-running the train.
