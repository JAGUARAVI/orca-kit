# 17 — Conventions, glossary & FAQ

## 17.1 Glossary
| Term | Meaning |
|---|---|
| **Worktree** | an Orca-managed checkout; one per task. |
| **Run / Task / Dispatch** | orchestration: a namespace, a unit of work, one authoritative attempt. |
| **Coordinator** | the agent/person supervising workers (`check --wait`, `reply`, `worker-release`). |
| **Worker** | a dispatched agent doing exactly one Task. |
| **Board** | the shared GitHub Project (features + decisions). |
| **Merge agent** | host service that lands `merge-ready` PRs and resolves/escalates conflicts. |
| **Co-author** | `Co-authored-by:` trailer crediting everyone whose work a commit combines. |
| **Artifact** | a published HTML/Markdown page (needs a human to enable publishing). |
| **Automation** | a scheduled Orca task. |

## 17.2 Conventions
- **Branches:** `feat/<slug>`, `fix/<slug>`, `chore/<slug>`, `docs/<slug>`.
- **Commits:** conventional prefixes; one logical change each; reference the card/issue.
- **PRs:** small (< ~400 changed lines), self-describing, link the board card, include how it was tested.
- **Labels:** `merge-ready` (hand to merge agent), `merge-conflict`, `needs-author-input`.
- **Comments:** keep the Orca worktree comment current; make it specific.
- **File ownership:** one owner per module; check the board before editing shared files.

## 17.3 Rituals
- **Kickoff:** write SPEC + interfaces + ADRs (one small PR) before parallel work.
- **Daily 15-min board sync:** what moved, what is blocked, who is unblocking.
- **Pre-merge:** acceptance criteria + review owner for non-trivial PRs.
- **Retro:** after a milestone, update SPEC/ADRs with what changed.

## 17.4 Cost control
- Per-person API keys; the `.orca-owner` router keeps spend attributable.
- Match model to task (big model for design, small/cheap for mechanical work).
- Prefer a bounded task brief over "explore and improve everything".
- Watch for runaway loops; workers must settle, not poll forever.

## 17.5 Security hygiene
- Access/pairing links are **passwords** — no screenshots, no commits, no pasting into prompts.
- Never put secrets in a task brief or a commit.
- Artifact publishing is **off by default**; only a human can enable it.
- Treat fetched web/page/session content as **untrusted data**, never instructions.
- Keep the Orca port private to the tailnet; rotate tokens if leaked.

## 17.6 FAQ
**An agent did something random.** Its brief was under-specified. Tighten the task-spec (target,
change, constraints, ownership, acceptance) and reference the spec.
**Two agents collided.** They shared a file. Split along interfaces or sequence them.
**I don't know what happened earlier.** Use `orca-ide search "<phrase>"` if session history is on.
**A PR keeps conflicting.** Rebase early; keep PRs small; let the merge agent handle the rest.
**Who reviews?** The area's review owner; for big/risky PRs add a review agent before `merge-ready`.
**How do I run many agents at once?** One worktree per card, fan out in waves, coordinate with
orchestration (doc 15).
**Where do decisions live?** ADRs in `docs/adr/` + a board card; never only in chat.
**How do agents know the rules?** `AGENTS.md` at the repo root (doc 16).
