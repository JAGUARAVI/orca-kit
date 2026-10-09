# 15 — Dividing work & delegating to agents

## 15.1 The unit of work
```
Feature card (board)  →  worktree  →  agent  →  PR  →  merge-agent  →  done
     1 card                1 wt        1 agent    PR        auto
```
**One card = one worktree = one agent = one PR.** Keep the mapping 1:1 or you lose the ability to
see what is happening.

## 15.2 Splitting among people
Split **vertically along interfaces** (doc 14.6), never "everyone edit the same big file".
- Each **feature/module has an owner** — one human accountable for it.
- Each area also has a **review owner** (may differ) who reads its PRs.
- Pick features so no two people own the same file/module at the same time.
- If a file must be shared, **sequence** the work (one finishes, then the next).

A practical split for a small product: `auth`, `data model + API`, `UI shell`,
`feature A`, `feature B`, `integration/hardening`. Map each to a person.

## 15.3 The board (GitHub Project)
Cards are the shared plan. Fields: **Status** (Todo/In Progress/Done), **Owner**, **Worktree**.
Lifecycle:
1. Create a card for each slice (owner set).
2. Move to **In Progress** when a worktree exists; paste the worktree name into `Worktree`.
3. Link the PR number on the card and in Orca (`worktree set --pr <n>`).
4. Move to **Done** on merge.
Put **decisions** on the board too — one card per architectural decision, referencing its ADR.

## 15.4 Delegating to an agent
Every delegation is a **self-contained task spec** — the agent may not share your context:
- **Target** — the files/component in scope.
- **Change** — the concrete result to produce.
- **Constraints** — invariants, compatibility, do-not-touch boundaries.
- **Ownership** — what this worker may edit.
- **Observable acceptance** — the test/output that proves completion.

Then:
```bash
echo <Name> > .orca-owner                      # route credentials (do this in the worktree)
orca-ide worktree create --name feat-x --agent opencode2 --prompt "<TASK-BRIEF>" --no-parent --json
```
Use `templates/TASK-BRIEF.md`. Put the spec section + acceptance criteria in the brief; point the
agent at `SPEC.md`/`AGENTS.md` rather than restating everything.

**Choosing an agent:** match the model to the task — a strong reasoning model for design/auth/data,
a fast cheap model for mechanical edits/tests. Different people can use different agents; the
`.orca-owner` router keeps each person's credentials separate.

## 15.5 Coordination patterns
| Pattern | When | How |
|---|---|---|
| **Parallel wave** | independent slices | `worker-start` several workers, then one `check --wait` |
| **Dependency DAG** | B needs A's interface | `task-create` + `worker-start --task`, keep depth ≤ 3–4 |
| **Decision gate** | a choice blocks work | coordinator asks; block until answered |
| **Escalation** | worker is stuck/unsafe | worker sends `escalation`/`question`; coordinator replies |
| **Review** | large/risky PR | a second agent/human reviews before `merge-ready` |
| **Handoff** | transfer, then stop | `worktree create --no-parent --agent --prompt`; do **not** supervise |

**Handoff vs supervision:** handoff = give ownership and stop (use `orca-cli`). Supervision =
monitor, wait, coordinate a DAG (use orchestration: `run-create`, `worker-start`, `check --wait`).

## 15.6 Anti-collision rules
- Never run two agents that edit the **same file** in parallel.
- Define shared types/contracts in a tiny first PR; then everyone imports, nobody edits it.
- One agent per worktree. New task → new worktree.
- Keep PRs small; rebase early and often (the merge agent handles conflicts, but prevention is free).
- Freeze public interfaces during a parallel wave.

## 15.7 Review ownership & merge
- Author runs the acceptance criteria and updates comment/status.
- For non-trivial PRs, a **review owner** (human or a review agent) checks the diff against the spec.
- Label `merge-ready` → the merge agent rebases, arms auto-merge, and either lands it or escalates a
  question to the author agent. If a resolution combined people, the merge commit is co-authored
  (doc 06).

## 15.8 Worked example — 5 people, one product
| Person | Board cards (owner) | Delegates to |
|---|---|---|
| Avi | architecture, `auth`, integration | opencode2 (design), codex (tests) |
| Parth | `data model + API` | claude, codex |
| Ekansh | `UI shell` | opencode2 |
| Dan | `feature A` | codex |
| Shaurya | `feature B` | claude |
Week shape: Day 1 = spec + interfaces + ADRs (all hands, one small PR). Day 2–4 = parallel waves,
one worktree per card. Day 5 = integration/hardening + review owners. Daily: 15-min sync on the
board only (what moved, what is blocked).
