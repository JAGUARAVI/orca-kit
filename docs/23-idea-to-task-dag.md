# 23 — Idea → product plan → technical plan → parallel task DAG (the whole pipeline)

This is the end-to-end path we ran for the megathon, made repeatable. **Five artefacts, four
derivations** — each stage is a different altitude, and each is *reviewed by a human* before the
next begins.

```
 ① idea                       rough notes, a brief, a pitch            (human writes)
        │   orca-plan product <idea-file>
        ▼
 ② docs/product-plan.md       PRODUCT altitude: users, outcomes, scope by phase, gates
        │   orca-plan plan
        ▼
 ③ docs/technical-implementation-plan.md   ENGINEERING altitude: components, interfaces, stack
        │   orca-plan tasks
        ▼
 ④ docs/tasks/README.md  +  docs/tasks/<PHASE>/<ID>-<slug>.md
        │   orca-plan verify  →  deps-from-index.py  →  setup-issues.sh
        ▼
 ⑤ GitHub issues (ready/blocked) → board → worktree+agent (orca-dispatch / task) → PRs → merge agent
```

Run it all in one go (review after each stage — they are drafts until a human accepts them):

```bash
orca-plan init "Life of Rupee"          # scaffold templates (product plan, SPEC, AGENTS, docs/tasks)
orca-plan all docs/idea.md             # ② ③ ④ ⑤ in order, then verify
```

…or stage by stage (recommended the first time):

```bash
orca-plan product docs/idea.md        # ① → ②
orca-plan plan                        # ② → ③  (reads docs/product-plan.md)
orca-plan tasks --phases P0 P1 P2     # ③ → ④
orca-plan verify                      # validates ④
```

---

## Stage ① — capture the idea (human)
The only purely human-authored input. Rough is fine: a paragraph, a pitch, a customer conversation,
a competition brief. Write it to `docs/idea.md` (or paste it as the argument).

> Do **not** jump from a rough idea straight to a technical plan. You will optimise the wrong thing.
> The product stage is what forces the *what and why* to be settled before the *how*.

## Stage ② — the product plan (product altitude)
Written in **product language — problems, users, outcomes, scope — never code.** Template:
`templates/PRODUCT-PLAN.md`. Sections: one-line summary · problem & why now · users & jobs ·
goals/non-goals · **scope by phase with gates** · experience & flow · product-level requirements
(prioritised, verifiable, technology-free) · constraints/dependencies/assumptions · risks ·
milestones · **open questions for named deciders** · handoff links.

Why it matters for an agent fleet: the product plan is where **non-goals** and **phase gates**
are fixed. Those become the guardrails that stop agents expanding scope (doc 14). The
"open questions" become the `⛩` human gates in the task DAG.

## Stage ③ — the technical implementation plan (engineering altitude)
`docs/technical-implementation-plan.md`. The engineering answer to stage ②: system overview and
stack with rationale, **workstreams**, the **interface/contract task that must land first**,
phases with entry/exit gates (matching the product plan's), and a first cut of the task list with
disjoint owned paths and dependency depth ≤ 3.

Rule of thumb: if stage ② changed, stage ③ is stale — regenerate or reconcile it.

## Stage ④ — the parallel task DAG (index + briefs)
`docs/tasks/README.md` (the **index**) plus one brief per task under `docs/tasks/<PHASE>/`.
The index carries the four things that make parallel work safe:
1. **Rules** — interfaces first, frozen deps, disjoint ownership, single-writer registries,
   per-task files, human gates ⛩, shallow runs.
2. **Mermaid graph** — the DAG at a glance.
3. **Table** — `ID | Task | Depends on | Owns (may edit) | Agent fit`.
4. **Parallel runs** — tasks grouped into the shallowest waves where no two share a path.

Briefs follow `templates/TASK-BRIEF.md` and each starts with a machine-readable
`Card: <ID>` line (what `create-task-issues.py` parses). Detail: doc 19.

Validate before you scatter work across agents:
```bash
orca-plan verify
# - rebuilds docs/tasks/deps.json from the index table (single source of truth)
# - counts briefs per phase
# - flags any path owned by more than one task (these must not share a wave)
```

## Stage ⑤ — issues, board, dispatch
```bash
github/deps-from-index.py docs/tasks/README.md -o docs/tasks/deps.json
github/setup-issues.sh <owner/repo> --deps docs/tasks/deps.json --phases P0 P1 P2 --gh <Owner>-gh
```
Creates labels, milestones, one issue per brief (`[ID] title`), dependency blocks, and the
auto-unblock Action. Then, day to day:

```bash
task status / task next --phase P0 --n 5 / task start P0-04 --agent claude / task done P0-04
```

One task = one worktree = one agent = one PR (doc 15). The merge agent lands PRs;
`task-reconcile` closes issues and flips dependents `blocked → ready`. See `github/README.md`.

---

## How the artefacts relate
| Artefact | Altitude | Answers | Owner | Template |
|---|---|---|---|---|
| `docs/idea.md` | raw | "what if…" | anyone | — |
| `docs/product-plan.md` | product | who, what, why, scope, gates | product lead | `templates/PRODUCT-PLAN.md` |
| `docs/technical-implementation-plan.md` | engineering | how, components, interfaces, stack | tech lead | — |
| `SPEC.md` | behaviour | exact rules/acceptance the code must meet | tech lead | `templates/SPEC.md` |
| `docs/adr/NNNN-*.md` | decisions | why a consequential choice was made | author | `templates/ADR.md` |
| `docs/tasks/README.md` + briefs | execution | who does what, in what order | coordinator | `templates/TASKS-README.md`, `TASK-BRIEF.md` |

`SPEC.md` is the *behavioural* contract the implementation is judged against; the technical plan is
the *structural* plan. Both derive from the product plan.

## Why this shape works (evidence)
On the megathon run this pipeline produced **64 tasks / 104 dependency edges**, and the discipline
is visible in the data: only **8 of 101 PRs** hit a conflict and only **3** needed a human
escalation. The dependency-first, disjoint-ownership split — decided in stages ② and ③ — is what
kept 4–5 agents landing PRs onto one `main` without grinding to a halt.

## Notes
- `orca-plan` runs a real agent (`--agent claude|codex|opencode2`). **Plans and briefs are drafts**;
  a human accepts them before the next stage.
- Human gates (⛩) are genuine tasks: model them as `blocked` until the named decider signs off.
- The index table is the **single source of truth** for dependencies — regenerate `deps.json`,
  never hand-edit it.
- If a stage's input changes (idea → product plan → tech plan), treat everything downstream as
  stale and re-derive.
- See also: doc 14 (specs & guardrails), doc 15 (dividing work), doc 19 (tasks→issues→board).