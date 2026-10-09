# Playbook — running the day-to-day

The practical companion to `WELCOME.md`. One page you can follow for any feature.
Full detail: docs 13–17 in `~/orca-docs/`. Templates in `~/orca-docs/templates/`.

## 0. One-time setup
Join Tailscale · connect Orca with the access link · `orca-gh-add <Name> <PAT>` (your GitHub identity) ·
`<Name>-claude` once to log in. See `WELCOME.md` §4–5.

## 1. Kickoff (spec first)
- Write/update **`SPEC.md`** from `templates/SPEC.md`: goal, **non-goals**, interfaces/contracts,
  edge cases, constraints, **verifiable acceptance criteria**.
- For each real decision, add an **ADR** (`templates/ADR.md`) under `docs/adr/`.
- Land shared **interfaces + ADRs** in one small PR *before* parallel work.

## 2. Divide
- Create a **card per slice** on the board; set **Owner**.
- Split **vertically along interfaces** so no two people own the same file.
- If a file must be shared, **sequence** it.

## 3. Delegate to an agent
```bash
echo <Name> > .orca-owner
orca-ide worktree create --name feat-x --agent opencode2 --prompt "<TASK-BRIEF>" --no-parent --json
```
- Use `templates/TASK-BRIEF.md`: Target · Change · Constraints · Ownership · Observable acceptance.
- Point the agent at `SPEC.md` / `AGENTS.md`; don't restate everything.
- One agent per worktree. Put the worktree name on the board card.

## 4. While the agent works
- Keep the **comment** + **status** current:
  `orca-ide worktree set --worktree active --comment "…" --workspace-status in-progress --json`
- Read before you type: `terminal read`, then `terminal send`; wait with `terminal wait --for tui-idle`.
- Watch progress: `orca-ide worktree ps --json` · `orca-ide worktree list --json`.

## 5. Review
- Run the **acceptance criteria** yourself (or via the agent) and read the diff.
- Non-trivial PRs get a **review owner** (human or a review agent) before `merge-ready`.
- Reject scope creep: did the change stay inside the brief and the non-goals?

## 6. Ship
```bash
git add -A && git commit -m "feat(scope): …"
git push -u origin <branch>
gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready
```
- The **merge agent** rebases, arms auto-merge, resolves safe conflicts, or escalates a question to
  the author agent. Combined work is credited with co-authors (doc 06).
- Watch: `tail -f ~/.orca-merge/log/merge-agent.log`.

## 7. Coordinate several agents (when one isn't enough)
- **Independent slices → a parallel wave:** `run-create` + several `worker-start`, then one
  `check --wait`.
- **Dependencies → a shallow DAG** (`task-create` + `worker-start --task`), depth ≤ 3–4.
- **Blocked → a decision gate / escalation**; answer with `reply`.
- **Transfer ownership → a handoff** (`worktree create --no-parent --agent --prompt`), then stop.
- **Monitor & settle → supervision** (`check --wait`, `worker-release`).
See doc 15.

## 8. Close out
- Move the card to **Done**; update the ADR if a decision changed.
- `orca-ide worktree set --worktree active --comment "merged #<n>" --json`.
- Remove dead worktrees: `orca-ide worktree rm --worktree name:<wt> --json`.

## 9. Command cheatsheet
```bash
orca-ide status --json
orca-ide worktree create --name <n> --agent <a> --prompt "<brief>" --no-parent --json
orca-ide worktree list --json ; orca-ide worktree ps --json
orca-ide worktree set --worktree active --comment "…" --workspace-status in-review --json
orca-ide terminal read --terminal <h> --json
orca-ide terminal send --terminal <h> --text "…" --enter --json
orca-ide terminal wait --terminal <h> --for tui-idle --timeout-ms 120000 --json
orca-ide orchestration check --wait --types "worker_done,escalation,question" --timeout-ms 900000 --json
orca-ide search "<phrase>" --json
gh pr edit <n> --add-label merge-ready
```

## 10. Rhythm
- **Kickoff:** spec + interfaces + ADRs (all hands).
- **Daily 15-min board sync:** what moved, what is blocked.
- **Pre-merge:** acceptance + review owner.
- **Milestone retro:** fold learnings back into SPEC/ADRs.

## 11. Do / Don't
| Do | Don't |
|---|---|
| one card = one worktree = one agent = one PR | let two agents edit the same file in parallel |
| small PRs, rebase early | giant PRs, long-lived branches |
| write the spec/acceptance first | "just build it, we'll see" |
| ask when the spec is silent/conflicting | guess and invent scope |
| keep comment/status current | leave stale cards and silent worktrees |
| keep secrets in `~/.orca-keys/<Name>.env` | paste secrets into prompts/commits |
