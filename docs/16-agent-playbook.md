# 16 — Agent playbook (how agents should behave in this repo)

This is the guidance behind the repo's `AGENTS.md`. Drop `templates/AGENTS.md` into the repo so
every agent reads it automatically. Agents: follow this unless a human overrides it.

## 16.0 Read before coding
1. `SPEC.md` — the contract for what you are building.
2. `docs/adr/` — decisions already made; do not relitigate them.
3. `AGENTS.md` / `CONTRIBUTING.md` — rules and process.
4. Your **task brief** — the only scope you may act on.

## 16.1 Scope discipline
- Implement **only** what the task brief names. No opportunistic refactors, renames, or "while I'm
  here" changes.
- Honor the **non-goals** and **do-not-touch paths**.
- **No new dependency** without an ADR. Prefer the standard library and what is already used.
- If the task is ambiguous or contradicts the spec, **stop and ask** (see 16.4) — do not guess.

## 16.2 Working agreement
- Small, frequent commits with clear messages: `feat(scope): …`, `fix(scope): …`, `test(scope): …`,
  `docs(scope): …`.
- Branch per feature: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`.
- Never force-push a shared branch (only the merge agent force-pushes its resolution branch).
- Never commit secrets, tokens, keys, or `.env` files.

## 16.3 Definition of Done (before you label `merge-ready`)
- [ ] Every acceptance criterion in the brief passes (show the command/output).
- [ ] Tests added or updated for the change.
- [ ] `SPEC.md` / ADR / docs updated if behavior or decisions changed.
- [ ] Linters/formatters clean; CI `checks` green.
- [ ] PR is small and self-describing; scope matches the brief.
- [ ] Worktree comment + status updated (`in-review`).
- [ ] No do-not-touch paths modified.

## 16.4 When to ask vs proceed
**Proceed** when the brief is unambiguous and within scope.
**Ask** (escalate to the coordinator/author) when:
- the spec is silent or conflicts with the task,
- you would need a new dependency or change a public interface,
- you would touch a frozen/do-not-touch path,
- acceptance criteria cannot be met without a decision,
- you discover a conflict with another worker's changes.
Use the Orca **blocking ask** (`orchestration reply`/preamble `ask`) — never a local TUI the
coordinator cannot answer.

## 16.5 Communication
- Update the worktree comment at each checkpoint: `orca-ide worktree set --worktree active --comment "…"`.
- Move status: `--workspace-status in-progress|in-review|completed`.
- As a dispatched worker: heartbeat only at the preamble cadence, read coordinator follow-ups at each
  natural checkpoint, send `worker_done` exactly once with a 3-sentence summary and outcome.
- Never encode failure only in prose — set the explicit outcome.

## 16.6 Orca commands you will use
```bash
orca-ide worktree set --worktree active --comment "…" --json
orca-ide worktree set --worktree active --workspace-status in-review --json
orca-ide terminal read --terminal <handle> --json
orca-ide terminal wait --terminal <handle> --for tui-idle --timeout-ms 120000 --json
orca-ide orchestration check --peek --format --json     # your unread mail
```

## 16.7 Handoff protocol
- A handoff transfers ownership; the sender stops after the send is `accepted`.
- Include: the task brief, the relevant files, acceptance criteria, and the constraint list.
- Do not monitor the receiver unless asked to supervise.

## 16.8 Merge & authorship
- Add `Co-authored-by: Name <email>` to a commit when you integrate another person's work.
- The merge agent labels/merges; do not merge your own PR directly unless asked.
- On a merge-agent question, answer concisely through the author-respond path (doc 06).
