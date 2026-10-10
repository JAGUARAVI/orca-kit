# Orca Hackathon Kit

A reusable, self-hosted **multi-agent coding workspace** with an **automated merge agent** and a
**spec-driven workflow** that keeps parallel agents from drifting.

One host runs Orca and a fleet of coding agents (Claude Code, Codex, OpenCode v2, Cursor). Each task
gets its own git worktree; work lands through PRs; a background **merge agent** serializes merges,
resolves safe conflicts (crediting combined authors), and escalates hard questions to the agents that
wrote the code. A shared GitHub Project board tracks features and decisions.

## Agent ruleset: Ponytail
Every agent ships with the **Ponytail** ruleset (write the least code that works; default level
`full`) — see `docs/20-ponytail.md`. Switch with `/ponytail lite|full|ultra|off`.

## Quickstart (one command for a new repo)
```bash
./setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
```

## Set up an existing local repo (no clone)
```bash
./setup-existing-repo.sh <local_dir> [base_branch]
```
Copies AGENTS.md + templates + docs + CI, writes the per-repo config, registers the repo in Orca,
and — if a GitHub remote exists — creates labels, protection and the merge-agent timer.

## Full guide
**[GUIDE.md](GUIDE.md)** — provisioning, per-person profiles, daily workflow, the merge agent,
multi-repo operation, troubleshooting.

## Documentation (`docs/`)
| # | Doc |
|---|---|
| 01–12 | architecture, access, agents, model config, per-person keys, merge agent, security, runbook, troubleshooting, board, porting, per-person GitHub auth |
| 13 | **Orca features & maximum-productivity patterns** |
| 14 | **Specs, architecture & guardrails** (stop agents wandering) |
| 15 | **Dividing work & delegating to agents** |
| 16 | **Agent playbook** (rules for agents) |
| 17 | **Conventions, glossary & FAQ** |

## Templates (`templates/`) — copy into your repo
`SPEC.md` · `ADR.md` · `AGENTS.md` · `TASK-BRIEF.md`

## Team-facing (`welcome/`)
`WELCOME.md` · `PLAYBOOK.md` (day-to-day) · `SUMMARY.md` · `INVITE-TEMPLATE.md`

## Plan → tasks → issues → board
A repeatable pipeline (see `docs/19-task-breakdown-and-issues.md`):
1. Break the plan into `docs/tasks/<PHASE>/<ID>-<slug>.md` briefs + a `docs/tasks/README.md` index
   (IDs, dependencies, path ownership, Orca runs). Templates: `templates/TASKS-README.md`,
   `templates/TASK-BRIEF.md`.
2. Create one GitHub issue per task with workflow labels and dependency links:
   ```bash
   github/labels.sh <owner/repo>
   github/create-task-issues.py --repo <owner/repo> --root . \
       --deps docs/tasks/deps.json --phases P0 P1 --gh <Name>-gh
   ```
   Labels: `ready` / `blocked` / `in-progress` / `review` / `task` / `P0` / `P1`.
3. Auto-unblock: `.github/workflows/task-reconcile.yml` runs `github/reconcile-task-issues.py`
   on every merged PR — it closes the completed task and flips dependents from `blocked` to `ready`.
4. Mirror the tasks as board cards and run them as Orca waves.

## Contents
- `setup-new-repo.sh` — bootstrap a repository (clone + GitHub + host).
- `setup-existing-repo.sh` — apply the kit to an existing local repo (GitHub optional).
- `github/` — `ci.yml`, `configure-repo.sh`, `setup-board.sh`, `labels.sh`, `create-task-issues.py`.
- `merge-agent/` — `orca-merge-agent`, `orca-merge-resolve.sh`, `orca-author-respond`.
- `person/` — `orca-keys-add`, `orca-gh-add`, `orca-route`, `orca-route-*`.
- `systemd/` — service + timer units.
- `skills/merge-agent/` — the agent skill.

## License
MIT — see [LICENSE](LICENSE).
