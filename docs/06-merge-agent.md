# 06 — Automated merge agent

Purpose: let several agents edit the same files; the merge agent lands their PRs,
resolves safe conflicts automatically, and asks the **author agents** when a
decision is needed. It replaces a separate merge queue (which isn't needed here,
because all agents run on this host).

## Components (`~/bin`)
- `orca-merge-agent` — one pass over `merge-ready` PRs (oldest first).
- `orca-merge-resolve.sh` — rebases a PR, asks an LLM agent to resolve, or escalates.
  Exit codes: `0` resolved/no-conflict, `10` escalated, `2` setup error.
- `orca-author-respond` — an author agent answers an escalation.
- systemd: `orca-merge-agent.service` + `orca-merge-agent.timer` (every **60s**).
- Skill: `skills/merge-agent/SKILL.md` (installed to `~/.agents/skills` and
  `~/.config/opencode/skills`).

## Flow
1. PR labeled `merge-ready`.
2. Merge agent updates the branch and arms auto-merge (`gh pr merge --squash --auto`).
3. On conflict: an LLM agent resolves per policy. If unsafe → it writes a `question`
   to `~/.orca-merge/questions/<pr>.json`, labels `merge-conflict` +
   `needs-author-input`, and comments on the PR.
4. The author agent answers via `orca-author-respond <author-label> <pr>`
   → `~/.orca-merge/answers/<pr>.json`.
5. The next pass applies the author's guidance, resolves, and merges.

## Conflict policy
| Class | Action |
|---|---|
| Disjoint edits | auto |
| Append-only logs (`*.jsonl`) | union merge |
| Generated files | regenerate |
| Semantic overlap (same constant/logic) | ESCALATE to author |
| Frozen / CODEOWNERS paths | ESCALATE |

## Proven scenarios (<repo>)
- `features.py`: two agents appended to the same list → **auto-resolved** (kept both), merged (PR #8).
- `config.py`: `RATE=2` vs `RATE=5` → **escalated** to `agent:rate5`, author answered,
  merge agent applied → merged (PR #11); result kept both intents.

## Logs
`~/.orca-merge/log/merge-agent.log`, `~/.orca-merge/log/resolve-<pr>.log`

## Consolidation note
An earlier GitHub Actions workflow (a "merge train") was removed: it duplicated the
merge agent, could not resolve conflicts, and its `schedule` never fired. The merge
agent does the same serialization/arming plus resolution and escalation. `ci.yml` is
now the only GitHub Actions workflow.
