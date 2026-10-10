# 19 — Turning a plan into tasks, issues and a board

A repeatable pipeline that takes a product/technical plan and produces a **parallel-safe task
graph**, **one GitHub issue per task** (with workflow labels and dependency links), and the
matching **Orca runs**.

```
plan.md  ──►  docs/tasks/README.md (index: IDs, deps, ownership, runs)
         ──►  docs/tasks/<PHASE>/<ID>-<slug>.md   (one brief per task, templates/TASK-BRIEF.md)
         ──►  github/create-task-issues.py        (one issue per task + labels + dep links)
         ──►  board cards / Orca worktrees         (one card = one worktree = one agent = one PR)
```

## 1. Decompose the plan
- Read the plan and list **workstreams** (e.g. foundation, core, world, UI, content, art, quality).
- Split each into tasks that each **own a disjoint set of paths** and can be done by one agent.
- Find the **interface/schema** task(s) and place them **first** — everything else depends on them.
- Mark **human gates** (⛩): decisions/reviews a named person must sign off (art approval, factual
  accuracy, accessibility) — they block downstream tasks.
- Keep dependency **depth ≤ 3–4** so Orca runs stay shallow.

## 2. Write the index — `docs/tasks/README.md`
Use `templates/TASKS-README.md`. It contains:
- the **rules** that make the split safe (interfaces first, frozen deps, disjoint ownership,
  single-writer registries, per-task files, human gates);
- a **mermaid graph** of the dependencies;
- a **table**: `ID | Task | Depends on | Owns (may edit) | Agent fit`;
- **Orca runs**: which tasks run together, and how many parallel agents.

## 3. Write one brief per task — `docs/tasks/<PHASE>/<ID>-<slug>.md`
Follow `templates/TASK-BRIEF.md`. Every brief starts with a machine-readable header line so tools
can index it:
```
# Task brief: <title>

Repo: <repo> · Base: origin/main · Owner: <assign> · Card: P0-04 · Depends on: P0-01 · Gate: <optional>

## Target / ## Change / ## Constraints / ## Ownership / ## Observable acceptance / ## Definition of Done
```
The `Card:` token is what `create-task-issues.py` parses; the `Depends on:` line is human-readable
(the machine dependency graph lives in the script's `--deps` JSON).

## 4. Generate the issues
```bash
orca-kit/github/create-task-issues.py \
  --repo <owner/repo> --root . \
  --deps docs/tasks/deps.json --phases P0 P1 --gh <Name>-gh
```
- Creates **one issue per brief**, titled `[<ID>] <title>`, with the brief as the body.
- Labels: **`ready`** (no prerequisites) or **`blocked`**, plus **`task`** and the phase (**`P0`/`P1`**).
- Then appends a clickable **`## Dependencies`** block (`Blocked by: [#n — ID](url)`).
- **Idempotent**: re-runs match existing issues by the `[ID]` title tag and only fill in what is missing.

Create the dependency graph once as JSON (or edit `DEFAULT_DEPS`):
```json
{ "P0-01": [], "P0-04": ["P0-01"], "P0-05": ["P0-04"] }
```

Labels (`github/labels.sh <owner/repo>`):
| Label | Meaning |
|---|---|
| `ready` | unblocked, available to start |
| `blocked` | waiting on dependencies or a gate |
| `in-progress` | work has started |
| `review` | implementation awaiting review |
| `task` | implementation task brief |
| `P0` / `P1` | priority phase |
| `merge-ready` / `merge-conflict` / `needs-author-input` | merge flow (see doc 06) |

## 5. Project board
Cards mirror the tasks. Add **Owner** + **Worktree** fields (doc 10):
```bash
github/setup-board.sh <owner> "<Title>" <owner/repo>
gh project field-create <n> --owner <owner> --name Worktree --data-type TEXT
```
When a task starts, set the card's **Owner** + **Worktree**, move it to *In Progress*, and label the
task issue `in-progress`. On PR open → `review`; on merge → *Done*.

## 6. Run it
Execute the **Orca runs** from the index: `worker-start` the wave, `check --wait`, settle, next wave
(doc 15). Keep one worktree per task and honor the frozen interfaces.

## Notes / gotchas
- **Ownership is the contract.** If two tasks list the same path, they must not run in the same wave.
- **One writer per registry** (`index.ts`, locale files, `package.json`) — assign it explicitly.
- Human gates are real dependencies; model them as `blocked` until the sign-off lands in the PR.
- The generator uses the **`gh` wrapper** for the acting person (`Avi-gh`, `Ekansh-gh`, …) so issues
  are created under that identity.

## Auto-unblocking when a PR merges
Task issues are born `blocked`. When a dependency merges, its dependents must become `ready`
automatically.

**`github/reconcile-task-issues.py`** does two things (idempotent — run on every merge):
1. A merged PR completes a task → **close** that task's issue and strip its workflow label.
   Match order: `Closes/Fixes/Resolves #N` in the PR body → `[ID]` tag in the title → `ID` in the
   branch name (e.g. `feat/p0-01-scaffold` → `P0-01`).
2. For every OPEN issue labeled `blocked`, if **all** of its `Blocked by: [#n — ID](…)`
   dependencies are now closed → **remove `blocked`, add `ready`**.

Dependencies are read from each issue's `## Dependencies` block (written by `create-task-issues.py`),
so there is no separate graph to keep in sync.

**Trigger — GitHub Action** (`github/task-reconcile.yml` → `.github/workflows/task-reconcile.yml`):
```yaml
on: { pull_request: { types: [closed] } }
if: github.event.pull_request.merged == true
# runs: python3 .github/scripts/reconcile-task-issues.py --repo "$GITHUB_REPOSITORY" --gh gh
```
Requires **Settings → Actions → General → Workflow permissions = Read and write** (the job needs
`issues: write`).

**Note on `Closes`:** GitHub only auto-closes an issue when the PR links it by **`#number`**
(not by a `P0-01` token). The reconciler closes by `[ID]`/branch name regardless, so
`Closes #3` and `feat/p0-01-…` both work.

Install into a repo:
```bash
mkdir -p .github/workflows .github/scripts
cp orca-kit/github/task-reconcile.yml   .github/workflows/task-reconcile.yml
cp orca-kit/github/reconcile-task-issues.py .github/scripts/
gh api -X PUT repos/<owner>/<repo>/actions/permissions/workflow -f default_workflow_permissions=write
```
