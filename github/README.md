# `github/` — issue, label, and tracking workflows

Everything that turns the task plan into trackable GitHub work, and keeps it in step as PRs land.

## One-shot setup

```bash
github/setup-issues.sh <owner/repo> --root . --phases P0 P1 P2 --gh <Name>-gh
```

That single command runs the whole pipeline:

1. **labels** (`labels.sh`) — `ready · blocked · in-progress · review · task · P0/P1/… · merge-*`
2. **milestones** — one per phase (`P0`, `P1`, …)
3. **task issues** (`create-task-issues.py`) — one issue per brief in `docs/tasks/**`, titled
   `[<ID>] <title>`, labeled `ready`/`blocked` + `task` + phase, with a clickable
   `## Dependencies` block
4. **auto-unblock Action** — copies `task-reconcile.yml` + `reconcile-task-issues.py` into
   `.github/`, and sets Actions workflow permissions to *write*

It is **idempotent** — re-run any time; it only adds what's missing.

Point the dependency graph at your index automatically instead of hand-maintaining JSON:

```bash
github/deps-from-index.py docs/tasks/README.md -o docs/tasks/deps.json
github/setup-issues.sh <owner/repo> --deps docs/tasks/deps.json --gh <Name>-gh
```

## Files

| File | What it does |
|---|---|
| `setup-issues.sh` | **entry point** — labels → milestones → issues → Action |
| `labels.sh` | create/refresh the workflow labels |
| `create-task-issues.py` | one issue per task brief, with dependency links (idempotent) |
| `deps-from-index.py` | build `deps.json` from the `docs/tasks/README.md` table |
| `reconcile-task-issues.py` | **close** completed tasks + **unblock** dependents on merge |
| `task-reconcile.yml` | Action: run the reconciler on every merged PR |
| `task-sync.yml` | Action: PR open → `review`, PR merged → de-label, drafts ignored |
| `board-sync.sh` | mirror issue labels onto a GitHub Project board (no manual dragging) |
| `setup-board.sh` | create the shared Project board + Owner/Worktree fields |
| `configure-repo.sh` | repo settings, squash-only merge, auto-merge, branch protection |
| `issue-templates/` | GitHub issue forms: `task.yml`, `bug.yml`, `gate.yml` |
| `ci.yml` | baseline CI workflow (concurrency + cancellation) |

## Day-to-day tracking — the `task` CLI

Install `bin/task` on your PATH (or run `orca-kit/bin/task`):

```bash
task status                 # counts + lists: ready / in-progress / review / blocked
task next --phase P1 --n 3  # the next unblocked tasks (oldest ready first)
task start P1-08 --agent claude   # dispatch: worktree+agent+issue, label in-progress
task done  P1-08            # close the issue after the PR merges
task sync                   # reconcile labels from issue/PR state now
```

## The state model

```
 ready ──start──► in-progress ──PR open──► review ──merge──► (issue closed → Done)
   ▲                                │
   └──────── unblocked ─────────────┘  (dependency issue closed)
 blocked ──(all deps closed)──► ready
```

- **`create-task-issues.py`** sets the *initial* state (`ready` if no deps, else `blocked`).
- **`task-sync.yml`** moves a task to `review` when a non-draft PR opens for it.
- **`task-reconcile.yml`** closes the issue and flips dependents `blocked → ready` on merge.
- **`board-sync.sh`** reflects all of the above onto the Project board.

## Issue forms

Drop `issue-templates/*.yml` into `.github/ISSUE_TEMPLATE/` so new work entered by hand matches
the generated shape (Task / Bug / Human-gate). The **Task** form includes the same DoD checklist
and `[ID]` tag the reconciler relies on.

## Gotchas (from production)

- `gh issue close` has **no** `--remove-label`; close first, then `gh issue edit --remove-label`.
- `pull_request: [closed]` fires for unmerged closes too — always gate on
  `github.event.pull_request.merged == true`.
- **Draft PRs must not be labeled `merge-ready`** — the merge agent loops on them. `task-sync.yml`
  ignores drafts on purpose.
- Issues need `issues: write` — set Actions workflow permissions to *write* (the setup script does
  this for you).