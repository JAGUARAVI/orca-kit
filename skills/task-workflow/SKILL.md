---
name: task-workflow
description: >-
  Operate the Orca task system on GitHub — task issues, workflow labels, the project board, and
  dispatching work to a worktree+agent. Use when asked to "pick up a task", "what's ready",
  "start a task", "dispatch P0-12", "close the task", "update the board", "create issues", or
  "sync task labels". Do not use for landing/merging PRs (that is `merge-agent`).
---

# Task workflow

One task = one issue = one worktree = one agent = one PR. This skill drives that loop.

## Read the plan
- Index: `docs/tasks/README.md` (table: `ID | Task | Depends on | Owns (may edit) | Agent fit`).
- Brief: `docs/tasks/<PHASE>/<ID>-<slug>.md` (follows `templates/TASK-BRIEF.md`).

The **Owns** column is the contract: only edit the listed paths. If two tasks share a path, they
must not run in the same wave.

## Lifecycle
```
ready ──start──► in-progress ──PR open──► review ──merge──► closed (Done)
  ▲
  └─ blocked ──(all dependency issues closed)──► ready
```

## Commands
```bash
task status                       # ready / in-progress / review / blocked
task next --phase P1 --n 3        # the next unblocked tasks
task start P1-08 --agent claude   # worktree + agent + issue, label in-progress
task done  P1-08                  # close after the PR merges
task sync                         # reconcile labels from issue/PR state now
```

Dispatch without the CLI:
```bash
orca-dispatch P1-08 --agent claude   # brief -> Orca worktree + agent prompt
```

## Creating the issues (once per repo / when the plan changes)
```bash
github/deps-from-index.py docs/tasks/README.md -o docs/tasks/deps.json
github/setup-issues.sh <owner/repo> --deps docs/tasks/deps.json --phases P0 P1 P2 --gh <Name>-gh
```

## Rules an agent must follow
- **Do not merge your own PR.** Implement, label `merge-ready`, stop.
- **Respect `Owned paths`.** No opportunistic edits elsewhere; a shared path change needs its own PR.
- **Freeze interfaces.** After the contracts task lands, a change to it is its own small PR.
- **Human gates (⛩) block.** Do not start a gated task until the sign-off lands on the issue/PR.
- **Keep dependencies honest.** The index table is the single source of truth; never hand-edit
  `deps.json` — regenerate it.

## Definition of Done before `merge-ready`
acceptance criteria pass · tests added · docs/ADR updated · linters + CI green · scope matches the
brief · no frozen paths touched · linked issue updated.