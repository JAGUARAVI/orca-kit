# 14 — Specs, architecture & guardrails (stopping agents from doing random things)

An agent with no constraints will invent scope. **The spec is the contract; the architecture is
the fence.** Write both before parallel work starts.

## 14.0 How the documents relate (read this first)
The spec does not appear from nowhere — it sits in a chain of artefacts, each at a different
altitude. Write them in order; each constrains the next (full detail in `23-idea-to-task-dag.md`):
```
idea.md                              raw notes
  └─ product plan                    who / what / why / scope by phase / gates   (product language)
       └─ technical implementation plan   components, interfaces, stack, workstreams (engineering)
            └─ SPEC.md                the exact behaviour the code must meet (the contract)
                 ├─ docs/adr/*.md     why each consequential choice was made
                 └─ docs/tasks/*      who does what, in what order (the DAG)
```
- The **product plan** fixes *scope and non-goals*; the **spec** fixes *behaviour*; the **technical
  plan** fixes *structure*. When they disagree, the product plan wins on *what*, the spec wins on
  *how it must behave*.
- Agents are held to the **spec** (verifiable) and the **owned paths** (the fence), not to prose.

## 14.1 Repository documentation layout
Keep these in the repo so every agent and human reads the same truth:
```
docs/PRODUCT-PLAN.md    # product: users, outcomes, scope by phase, gates (doc 23)
docs/technical-implementation-plan.md  # engineering: components, interfaces, stack (doc 23)
SPEC.md                 # what we are building (behavioural contract)
docs/architecture.md    # how the system is shaped (diagrams + invariants)
docs/adr/0001-*.md      # Architecture Decision Records (one per real decision)
docs/tasks/             # task index + one brief per task (the DAG, doc 19)
AGENTS.md               # rules for agents working in this repo (doc 16)
CONTRIBUTING.md         # human process: branches, PRs, review, board
docs/features/<name>.md # per-feature spec when a feature is big
```
`AGENTS.md` is auto-read by most agent CLIs at the repo root — put the non-negotiables there.

## 14.2 Writing SPEC.md
A good spec is short, testable, and leaves nothing to the imagination. Structure:
1. **Problem & goal** — one paragraph, in user terms.
2. **Non-goals** — explicitly out of scope (kills 80% of cruft).
3. **Users & user stories** — "As a ___, I want ___ so that ___."
4. **Scope: in / out** — bullet the boundaries.
5. **Interfaces & contracts** — function signatures, API shapes, data models, events, file formats.
   Define these **first**; they are the seams along which parallel work is split.
6. **Behavior & edge cases** — empty/error/offline/permission states.
7. **Constraints** — performance, compatibility, security, dependency allowlist, do-not-touch paths.
8. **Acceptance criteria** — the verifiable checklist that decides "done".
9. **Open questions** — decide or defer explicitly; never leave implicit.
10. **Milestones** — the smallest releasable slices.

See `templates/SPEC.md`.

## 14.3 Acceptance criteria must be verifiable
Each criterion is a test, command, or observable:
- ✅ "`POST /login` with bad creds returns 401 with `{error:'invalid'}`"
- ✅ "`pytest tests/test_login.py` passes"
- ❌ "login works well"
If you cannot write the check, the requirement is not ready.

## 14.4 Architecture Decision Records (ADRs)
An ADR records **one** decision and why. They are immutable; to change a decision write a new ADR
that supersedes the old one.
```markdown
# ADR 0007 — Use Postgres for the job queue
Status: accepted (2026-10-10) · Supersedes: 0003
Context: …
Decision: …
Consequences: … (good and bad)
Alternatives: … and why rejected
```
See `templates/ADR.md`. Write an ADR for: frameworks, databases, auth, external services,
cross-cutting patterns, and **any new dependency**.

## 14.5 Guardrails that prevent AI drift
| Guardrail | How |
|---|---|
| Freeze the interfaces | Land types/signatures/API specs before implementation |
| Do-not-touch paths | list them in SPEC + `AGENTS.md`; enforce with CODEOWNERS |
| Dependency allowlist | no new dependency without an ADR |
| Small, scoped tasks | one task-spec = one file/component (doc 15) |
| Contract tests | tests that assert the interface, not the internals |
| Naming & style | state conventions; run linters/formatters in CI |
| No opportunistic refactors | "only change what the task names" |
| Explicit non-goals | restate in every task brief |
| Review owner per area | a human accountable for each module |
| Definition of Done | enforced checklist before `merge-ready` (doc 16) |

## 14.6 Interfaces-first, parallel-safe decomposition
Parallelism is safe only when two tasks do not edit the same file. **Split along interfaces:**
- define shared types/contracts first (one small PR),
- then assign each implementation file/module to a different agent,
- integration is a thin step at the end.
If two tasks must touch one file, run them **sequentially**.

## 14.7 Definition of Ready / Definition of Done
**Ready** (before an agent starts): spec section exists; interfaces defined; acceptance criteria
written; owner + worktree assigned; non-goals stated.
**Done** (before `merge-ready`): acceptance criteria pass; tests added; docs/ADR updated; comment +
status updated; PR is small and self-describing; no do-not-touch paths modified.

See also: `19-task-breakdown-and-issues.md` (turn a plan into tasks, issues and a board).

## 14.8 Templates
- `templates/PRODUCT-PLAN.md` — product plan (users, scope by phase, gates).
- `templates/SPEC.md` — behavioural spec (the contract).
- `templates/ADR.md` — decision record.
- `templates/AGENTS.md` — agent rules for the repo.
- `templates/TASKS-README.md` — the task index (DAG table + parallel runs).
- `templates/TASK-BRIEF.md` — the brief you paste into `worktree create --prompt`.
